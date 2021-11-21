require 'csv'
require 'fileutils'

CSV_DIR = 'D:/Downloads/Trading212'
CSVS = "#{CSV_DIR}/*.csv"
OUTPUT_FILE = "#{CSV_DIR}/output.csv"
VALID_ACTIONS = {
  'buy' => 'Buy',
  'sell' => 'Sell'
}
EXCHANGE_MAPPINGS = {
  'Z' => 'NasdaqGS:Z',
  'BEP' => 'NYSE:BEP',
  'RDSA' => 'LSE:RDSA'
}
IGNORE_LIST = ['PHGP']

FileUtils.rm_f OUTPUT_FILE

def lookup(ticker)
  EXCHANGE_MAPPINGS[ticker] || ticker
end

def adjust_for_pennies(price, currency)
  price / (currency == 'GBX' ? 100.0 : 1.0)
end

to_csv = CSV.generate do |csv|
  data = Dir.glob(CSVS) do |file|
    CSV.foreach(file, headers: true) do |row|
      next if IGNORE_LIST.include?(row['Ticker'])
      ticker = lookup(row['Ticker'])

      action = row['Action']&.gsub(/.*(buy|sell)/, '\1')
      action = VALID_ACTIONS[action]
      shares = row['No. of shares'].to_f
      price = adjust_for_pennies(row['Price / share'].to_f, row['Currency (Price / share)'])
      csv << [ticker, row['Time'], shares, price, action] if action
    end
  end
end

File.write(OUTPUT_FILE, to_csv)
