#Author Nicolas Bessi, Joel Grandguillaume 2009 
#copyright Camptocamp SA
require 'rubygems'
require 'ooor'
include Ooor
require 'pp'

# Add useful methode on invoice handling
AccountInvoice.class_eval do 
    # Create an invoice with given informations
    # Add a line if amount <> false, the account could be provided or not
    # Input :
    #  - name : Name of the invoice
    #  - partner : A valid ResPartner instance
    #  - currency_code (Default : EUR) : An ISO code for currency
    #  - date (Default : false) : A date in this text format : 1 jan 2009
    #  - amount (Default : false) : An amount for the invoice => this will create a line 
    #  - account (Default : false) : An valide AccountAccount
    #  - type (Default : out_invoice) : the invoice type
    # Return
    #  - The created AccountInvoice as a instance of the class¨
    # Usage Example:
    # part = ResPartner.find(:first)
    # puts part.id
    # inv = AccountInvoice.create_cust_invoice_with_currency('my name',part,{currency_code =>'CHF'})
    def self.create_invoice_with_currency(name, partner, options={}, *args)
        o = {:type=>'out_invoice', :currency_code=>'EUR', :date=>false, :amount=>false, :account=>false}.merge(options)
        toreturn = AccountInvoice.new()
        # Set name
        toreturn.name = name
        if o[:date] :
            toreturn.date_invoice = Date.parse(str=o[:date]).to_s
        else
            toreturn.date_invoice = Date.today.to_s
        end
        
        # Set type
        toreturn.type = o[:type]
        curr =  ResCurrency.find(:first, :domain=>[['code','=',o[:currency_code]]])
        # Set currency
        if curr : 
            toreturn.currency_id = curr.id
        else
            raise "!!! --- HELPER ERROR :#{o[:currency_code]} currency not found"
        end
        unless partner.class  == ResPartner :
            raise "!!! --- HELPER ERROR :create_cust_invoice_with_currency received a #{partner.class.to_s} instead of ResPartner" 
        end 
        # Set partner
        if (partner.address.length >0) :
            toreturn.partner_id = partner.id
        else
            raise "!!! --- HELPER ERROR :create_cust_invoice_with_currency received a partner : #{partner.name} without adresses"
        end
        toreturn.on_change('onchange_partner_id', 1, 0[:type], partner.id, toreturn.date_invoice, false, false)
        
        # Set amount and line if asked for
        toreturn.create
        toreturn.type = o[:type]
        toreturn.save
        if o[:amount] :
            if ['in_invoice', 'in_refund'].include? o[:type] :
                toreturn.check_total = o[:amount]
            end
            if o[:account] :
                unless account.class  == AccountAccount :
                    raise "!!! --- HELPER ERROR :create_cust_invoice_with_currency received a #{o[:account].class.to_s} instead of AccountAccount" 
                end
                account_id = o[:account].id
            else
                account_id = AccountAccount.find(:first, :domain=>[['type','=','other']]).id
                # Create a line = amount for the created invoice
                line=AccountInvoiceLine.new(
                :account_id => account_id,
                :quantity => 1,
                :price_unit => o[:amount],
                :name => name+' line',
                :invoice_id => toreturn.id
                )
                line.create
               
            end
        end
        toreturn.save 
        return toreturn
    end
end