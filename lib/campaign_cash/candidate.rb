module CampaignCash
  class Candidate < Base

    # Represents a candidate object based on the FEC's candidate and candidate summary files.
    # A candidate is a person seeking a particular office within a particular two-year election
    # cycle. Each candidate is assigned a unique ID within a cycle.
    attr_reader :name, :id, :state, :district, :party, :fec_uri, :committee_id, 
    :mailing_city, :mailing_address, :mailing_state, :mailing_zip,
    :total_receipts, :total_contributions, :total_from_individuals, 
    :total_from_pacs, :candidate_loans, :total_disbursements,
    :total_refunds, :debts_owed, :begin_cash, :end_cash, :status,
    :date_coverage_to, :date_coverage_from, :relative_uri, :office

    def initialize(params={})
      params.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end
    end

    # Creates a new candidate object from a JSON API response.
    def self.create(params={})
      self.new name: params['name'],
      id: params['id'],
      state: parse_state(params['state']),
      office: parse_office(params['id']),
      district: parse_district(params['district']),
      party: params['party'],
      fec_uri: params['fec_uri'],
      committee_id: parse_committee(params['committee']),
      mailing_city: params['mailing_city'],
      mailing_address: params['mailing_address'],
      mailing_state: params['mailing_state'],
      mailing_zip: params['mailing_zip'],
      total_receipts: params['total_receipts'].to_f,
      total_contributions: params['total_contributions'].to_f,
      total_from_individuals: params['total_from_individuals'].to_f,
      total_from_pacs: params['total_from_pacs'].to_f,
      candidate_loans: params['candidate_loans'].to_f,
      total_disbursements: params['total_disbursements'].to_f,
      total_refunds: params['total_refunds'].to_f,
      debts_owed: params['debts_owed'].to_f,
      begin_cash: params['begin_cash'].to_f,
      end_cash: params['end_cash'].to_f,
      status: params['status'],
      date_coverage_from: params['date_coverage_from'],
      date_coverage_to: params['date_coverage_to'] 
    end

    def self.create_from_search_results(params={})
      self.new name: params['candidate']['name'],
      id: params['candidate']['id'],
      state: params['candidate']['id'][2..3],
      office: parse_office(params['candidate']['id'][0..0]),
      district: parse_district(params['district']),
      party: params['candidate']['party'],
      committee_id: parse_committee(params['committee'])
    end

    def self.parse_state(state)
      state.split('/').last[0..1] if state
    end

    def self.parse_office(id)
      return nil unless id
      if id[0..0] == "H"
        'house'
      elsif id[0..0] == 'S'
        'senate'
      else
        'president'
      end
    end

    def self.parse_district(uri)
      if uri and uri.split('/').last.split('.').first.to_i > 0
        uri.split('/').last.split('.').first.to_i
      else
        0
      end
    end

    def self.categories
      {
        individual_total: "Contributions from individuals",
        contribution_total: "Total contributions",
        candidate_loan: "Loans from candidate",
        receipts_total: "Total receipts",
        refund_total: "Total refunds",
        pac_total: "Contributions from PACs",
        disbursements_total: "Total disbursements",
        end_cash: "Cash on hand",
        debts_owed: "Debts owed by",
      }
    end

    # Retrieve a candidate object via its FEC candidate id within a cycle.
    # Defaults to the current cycle.
    def self.find(fecid, cycle=CURRENT_CYCLE)
      reply = invoke("#{cycle}/candidates/#{fecid}")
        result = reply['results']
      self.create(result.first) if result.first
    end

    # Returns leading candidates for given categories from campaign filings within a cycle.
    # See [the API docs](http://developer.nytimes.com/docs/read/campaign_finance_api#h3-candidate-leaders) for
    # a list of acceptable categories to pass in. Defaults to the current cycle.
    def self.leaders(category, cycle=CURRENT_CYCLE)
      reply = invoke("#{cycle}/candidates/leaders/#{category}",{})
        results = reply['results']
      results.map{|c| self.create(c)}
    end

    # Returns an array of candidates matching a search term within a cycle. Defaults to the
    # current cycle.
    def self.search(name, cycle=CURRENT_CYCLE, offset=nil)
      reply = invoke("#{cycle}/candidates/search", {query: name, offset: offset})
      results = reply['results']      
      results.map{|c| self.create_from_search_results(c)}
    end

    # Returns an array of newly created FEC candidates within a current cycle. Defaults to the
    # current cycle.
    def self.new_candidates(cycle=CURRENT_CYCLE, offset=nil)
      reply = invoke("#{cycle}/candidates/new",{offset: offset})
      results = reply['results']
      results.map{|c| self.create(c)}      
    end

    # Returns an array of candidates for a given state within a cycle, with optional chamber and
    # district parameters. For example, House candidates from New York. Defaults to the current cycle.
    def self.state(state, chamber=nil, district=nil, cycle=CURRENT_CYCLE, offset=nil)
      path = "#{cycle}/seats/#{state}"
        if chamber
          path += "/#{chamber}"
          path += "/#{district}" if district
        end
      reply = invoke(path, {offset: offset})
      results = reply['results']
      results.map{|c| self.create_from_search_results(c)}      
    end

    instance_eval { alias :state_chamber :state }
  end
end
