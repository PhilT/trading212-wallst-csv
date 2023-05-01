require 'csv'
require 'fileutils'

# Shell (SHEL) ticker changed from RDSA to SHEL on 1st Feb 2022. Something weird happened
# in the data at this point but everything was sold after that and rebought from
# 27th May 2022 so all RDSA entries and SHEL entries prior to this date can be
# safely ignored.

# Easyjet (EZJ) problem with selling more shares that I bought (not sure how
# that happened). Liquidated position so adjusted to the shares I had bought.

CSV_DIR = 'E:/Downloads/Trading212'
CSVS = "#{CSV_DIR}/from*.csv"
OUTPUT_FILE = "#{CSV_DIR}/output.csv"
VALID_ACTIONS = {
  'buy' => 'Buy',
  'sell' => 'Sell'
}
EXCHANGE_MAPPINGS = {
  'Z' => 'NasdaqGS:Z',
  'BEP' => 'NYSE:BEP',
  'ADM' => 'LSE:ADM',
  'P911' => 'XTRA:P911',
  'FB' => 'NasdaqGS:META',
  'NG' => 'LSE:NG.'
}
IGNORE_LIST = ['PHGP', 'CRUDP', 'RDSA']

FileUtils.rm_f OUTPUT_FILE

def lookup(ticker)
  EXCHANGE_MAPPINGS[ticker] || ticker
end

def adjust_for_pennies(price, currency)
  price
  #price / (currency == 'GBX' ? 100.0 : 1.0)
end

to_csv = CSV.generate do |csv|
  data = Dir.glob(CSVS) do |file|
    puts "Processing: #{file}"
    CSV.foreach(file, headers: true) do |row|
      next if IGNORE_LIST.include?(row['Ticker'])
      next if row['Ticker'] == 'SHEL' and Date.parse(row['Time']) < Date.new(2022, 5, 27)
      ticker = lookup(row['Ticker'])

      action = row['Action']&.gsub(/.*(buy|sell)/, '\1')
      action = VALID_ACTIONS[action]
      shares = row['No. of shares'].to_f
      shares = 550.0 if ticker == 'EZJ' && shares == 714.0
      price = adjust_for_pennies(row['Price / share'].to_f, row['Currency (Price / share)'])
      csv << [ticker, row['Name'], row['Time'], shares, price, action] if action
    end
  end
end

header = "Ticker Symbol,Name,Date (yyyy-mm-dd),Shares,Price,Cost,Type\n"
File.write(OUTPUT_FILE, header + to_csv)
