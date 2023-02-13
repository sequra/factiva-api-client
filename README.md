# Factiva-api-client

This gem integrates your ruby app with [Dow Jones Risk & Compliance API](https://developer.dowjones.com/site/docs/risk_and_compliance_apis/risk_and_compliance_2_0/index.gsp)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'factiva-api-client', git: "git@github.com:sequra/factiva-api-client.git"
```

And then execute:
```bash
$ bundle install
```

## Usage

A configuration is required. Add this to your app config with your credentials and the global timeout you want to set for each request:
```ruby
Factiva.configure do |config|
  config.auth_url  = "https://accounts.dowjones.com/oauth2/v1/token"
  config.base_url  = "https://api.dowjones.com"
  config.timeout   = 5
  config.client_id = "your_client_id"
  config.password  = "your_password"
  config.username  = "your_username"
  config.device    = "testdevice"
end

Factiva.configure(Factiva::MONITORING_API_ACCOUNT) do |config|
  config.auth_url  = "https://accounts.dowjones.com/oauth2/v1/token"
  config.base_url  = "https://api.dowjones.com"
  config.timeout   = 5
  config.client_id = "your_monitoring_client_id"
  config.password  = "your_monitoring_password"
  config.username  = "your_monitoring_username"
  config.device    = "testdevice"
end
```

Authentication is performed automatically on your first request, as well as token handling and expiration.

Then, there are two requests available that can be made through `Factiva::Request`.

### Search request.
Search the Dow Jones RiskCenter database for risk entities.
The response will return an array of json formatted `RiskEntities`.

Method parameters:
| parameter   | type    | required |
| ----------- | ------- | -------- |
| first_name  | string  | true     |
| last_name   | string  | true     |
| birth_date  | Date    | false    |
| birth_year  | string  | false    |
| birth_month | string  | false    |
| birth_day   | string  | false    |
| offset      | integer | false    |
| limit       | integer | false    |

The parameter `birth_date` takes priority over year, month and day.

Examples:

```ruby
Factiva::Request.search(first_name: "Jhon", last_name: "Smith", birth_date: Date.new(1995, 8, 22))
=> {"meta"=>{"count"=>32, "first"=>0, "last"=>0, "total_count"=>32, "screen...
```

```ruby
Factiva::Request.search(first_name: "Jhon", last_name: "Smith", birth_year: "1992")
=> {"meta"=>{"count"=>47, "first"=>0, "last"=>0, "total_count"=>47, "screen...
```

### Profile request.
View risk profiles in the Dow Jones RiskCenter database. The method requires as a param the `RiskEntity` id that is returned in search request.

Example:
```ruby
Factiva::Request.profile("11266381")
=> {"data"=>{"attributes"=>{"basic"=>{"type"=>"Person", "name_details"=>{"primary_...
```

### Stub requests
Both methods `search` and `profile` can be mocked using `Factiva::Response` class method `stub!`. Once it is used, it will ignore the configuration and return always given fixed responses passed to it. Example:
```ruby
Factiva::Request.stub!(
  search: { "data" => ["Jhon", "Smith"] },
  profile: { "data" => "Jhon Smith" }
)
=> true

Factiva::Request.search(first_name: "Jhon", last_name: "Smith")
=> {"data"=>["Jhon", "Smith"]}

Factiva::Request.profile("1234")
=> {"data"=>"Jhon Smith"}
```

If a method response is not given to `stub!`, it will be mocked with empty response. Example:
```ruby
Factiva::Request.stub!(
  profile: { "data" => "Jhon Smith" }
)
=> true

Factiva::Request.search(first_name: "Jhon", last_name: "Smith")
=> {}
```

Use `unstub!` to go back to use real requests with given configuration. Example:
```ruby
Factiva::Request.unstub!
=> true

Factiva::Request.profile("11266381")
=> {"data"=>{"attributes"=>{"basic"=>{"type"=>"Person", "name_details"=>{"primary_...
```


## Contributing

All contributions are welcome, feel free to create a Pull request.

You can start the development environment with `docker-compose run dev sh` and run specs with `docker-compose run dev bundle exec rspec`

In case you want to use the gem in our of our application from your local code, you can do the following:

* Add a new volume in the Rails application's docker-compose with `~/${PATH_TO_THE_GEM}:/app/vendor/gems/factiva-api-client`
* Update the Gemfile to use the gem from `path:` with line `gem "factiva-api-client", path: '/app/vendor/gems/factiva-api-client'`
