# frozen_string_literal: true

# Base Class
class BaseClass
  def self.downcase_name(name)
    name.downcase
  end

  def self.validate_params!(*params)
    return false if params.any?(&:nil?)

    true
  end

  def self.capitalize_name(name)
    name.capitalize
  end

  def self.round_price(price)
    price.round(2)
  end
end

#================================================================

# Items
class Items < BaseClass
  @@items = {}

  def self.create(name, price)
    return unless validate_params!(name, price)

    name = downcase_name(name)
    @@items[name] = { name: name, price: price }
  end

  def self.all
    @all ||= @@items
  end
end

# CREATE STATIC ITEMS DATA=========================================
Items.create('Milk', 3.97)
Items.create('Bread', 2.17)
Items.create('Banana', 0.99)
Items.create('Apple', 0.89)
#=================================================================

# Itemoffers
class ItemOffers < BaseClass
  @@offers = {}

  def self.create(name, quantity, price)
    return unless validate_params!(name, quantity, price)

    name = downcase_name(name)
    @@offers[name] = { name: name, quantity: quantity, price: price }
  end

  def self.all
    @all ||= @@offers
  end
end

# CREATE STATIC SALES ITEMS DATA====================================
ItemOffers.create('milk',  2, 5.00)
ItemOffers.create('bread', 3, 6.00)
#==================================================================

# Purchase Details
class PurchaseDetails
  def initialize(purchased_items)
    @purchased_items = purchased_items
    @items = Items.all
    @item_offers = ItemOffers.all
  end

  def generate_invoice
    {
      item_details: item_details,
      amount_details: amount_details
    }
  end

  private

  def item_details
    @item_details ||= begin
      group_by_purchased_items_details.map do |item|
        price = if @item_offers[item[:name]]
                  total_amount_after_offers(item)
                else
                  item[:price]
                end
        { name: item[:name], quantity: item[:quantity], price: price }
      end
    end
  end

  def amount_details
    total_amount =
      item_details.inject(0) { |sum, hash| sum + hash[:price] }
    {
      total_amount: total_amount.round(2),
      saved_amount: (purchased_items_details.inject(0) do |sum, hash|
                       sum + hash[:price]
                     end - total_amount)
    }
  end

  def total_amount_after_offers(purchased_item)
    reminder =
      purchased_item[:quantity] - @item_offers[purchased_item[:name]][:quantity]
    (reminder * @items[purchased_item[:name]][:price] + \
      @item_offers[purchased_item[:name]][:price])
  end

  def group_by_purchased_items_details
    @group_by_purchased_items_details ||= begin
      purchased_items_details.group_by { |purchased_item| purchased_item[:name] }
                             .map do |item, value|
        total_quantity = value.map { |item| item[:quantity] }.compact.inject(:+)
        price = value.map { |item| item[:price] }.compact.inject(:+)
        { name: item, quantity: total_quantity, price: price }
      end
    end
  end

  def purchased_items_details
    @purchased_items_details ||= begin
      @purchased_items.map do |item|
        next unless @items[item]

        {
          name: item,
          quantity: 1,
          price: @items[item][:price]
        }
      end
    end
  end
end

#================================================================

# Bill
class Bill < BaseClass
  def self.print
    read_input
    print_header
    print_invoice_details
    print_footer
  end

  def self.read_input
    puts "Please enter all the items purchased separated by a comma\n"
    input = gets
    puts "\n"
    items = input.split(' ').join.split(',')
    @details = PurchaseDetails.new(items).generate_invoice
  end

  def self.print_header
    puts 'Item      Quantity      Price'
    puts '--------------------------------------'
  end

  def self.print_invoice_details
    @details[:item_details].each do |item|
      puts "#{capitalize_name(item[:name]).ljust(10)}"\
           "#{item[:quantity].to_s.ljust(14)}$#{item[:price]}"
    end
  end

  def self.print_footer
    puts "\n"
    puts "Total price : $#{round_price(@details[:amount_details][:total_amount])}\n"
    puts "You saved $#{round_price(@details[:amount_details][:saved_amount])} today."
    puts "\n"
  end
end

Bill.print