require 'csv'
require 'json'
require 'aws-sdk-v1'

headers = nil
result = {}
detail_cost = {}

s3 = AWS::S3.new(
  :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
  :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
  :region => 'us-west-1',
)

bucket = s3.buckets['capken-bills'] 
obj = bucket.objects['336932533718-aws-billing-csv-2015-01.csv']
obj.read.split("\n").each do |line|
  line = line.strip

  CSV.parse(line) do |row|
    if headers.nil?
      headers = row
    else
      record = {}
      headers.each_with_index do |attr, index|
        record[attr] = row[index]
      end

      case record['RecordType']
      when /EstimatedDisclaimer/
        if record['ItemDescription'] =~ /(\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2})/
          result['lastModifiedTime'] = $1
        end
      when /InvoiceTotal/
        result['totalCost'] = record['CostBeforeTax'].to_f.round(2)
      when /PayerLineItem/
        product_code = record['ProductCode']
        cost = detail_cost[product_code] || 0
        detail_cost[product_code] = cost + record['CostBeforeTax'].to_f
      end

    end
  end
end

result['detailCost'] = detail_cost.map { |code, cost| {:code => code, :cost => cost.round(2) } }

file_path = File.join(File.dirname(__FILE__), 'data', result['lastModifiedTime'].gsub(/[\/: ]/, '-') + '.json') 
File.open(file_path, 'w+') do |file|
  file.puts result.to_json
end unless File.exists?(file_path)
