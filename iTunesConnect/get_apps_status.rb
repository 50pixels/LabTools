require 'mechanize'

class Account
	attr_accessor :username, :password
	attr_reader :apps

	def initialize
		@agent = Mechanize.new
		@agent.get "https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa"
		@apps = []
	end


	def agent
		@agent
	end

	def update
		login
		applications_page
		@apps.each do |app|
			app.update self
			@agent.back
			puts app.to_s
			puts "\n"
		end
	end


	class App
		attr_accessor :app_name

		attr_accessor :app_sku, :app_id
		attr_accessor :bundle_id, :date_created, :version, :status
		
		def agent
			@agent
		end

		def update(account)
			@account = account
			@agent = account.agent
			enter_into_app
			get_app_details
		end

		def to_s
			puts "--- #{@app_name}"
			puts "Version:\t #{@version}"
			puts "Bundle ID:\t #{@bundle_id}"
			puts "App ID:\t #{@app_id}"
			puts "Status:\t #{@status}"
			puts "-----------------------"
		end


		private


			def enter_into_app
				link = agent.page.link_with text: /#{self.app_name}/i
				link.click
			end

			def get_app_details
				@agent.page.search("p").each do |element|
					self.app_sku ||= get_info_from_label "sku", element				
					self.app_id ||= get_info_from_label "apple id", element
					self.bundle_id ||= get_info_from_label "bundle id", element
					self.version ||= get_info_from_label "version", element				
				end

				#getting the status of the app
				doc = @agent.page.parser
				status_div = doc.xpath ".//div[label[text()='Status']]"
				self.status = (status_div.xpath ".//span/span").text.strip

			end

			def get_info_from_label(label_string,element)
				label = element.search "label"
				span = element.search "span"
				if label.text =~ /#{label_string}/i
					return span.text
				end				
			end
	end

	private

	def login
		form = @agent.page.forms.first
		form['theAccountName'] = self.username
		form['theAccountPW'] = self.password
		form.submit
	end

	def applications_page
		@manage_your_applications ||= @agent.page.link_with(text: /manage your applications/i)
		@manage_your_applications.click

		#get applications
		name_divs = @agent.page.search "div.app-name"
		@apps = []
		name_divs.each do |name_div|
			app = App.new
			app.app_name = name_div.text
			@apps << app
		end

	end

end


a = Account.new

a.username = "your@email.com"
a.password = "password"
a.update

