
require "net/http"
require "spec_helper"
require 'poseidon' 


xml = <<XML
<StudentPersonals xmlns="http://www.sifassociation.org/au/datamodel/3.4">
<StudentPersonal RefId="e9fc2b1f-07a5-4c07-ad9a-6ffa3d9b576d">
    <LocalId>45715</LocalId>
    <StateProvinceId>96413752</StateProvinceId>
    <OtherIdList/>
    <PersonInfo>
        <Name Type="LGL">
            <FamilyName>Dodich</FamilyName>
            <GivenName>Kira</GivenName>
            <MiddleName>Glynis</MiddleName>
            <PreferredGivenName>Kira</PreferredGivenName>
        </Name>
        <Demographics>
            <IndigenousStatus>2</IndigenousStatus>
            <Sex>2</Sex>
            <BirthDate>2004-02-10</BirthDate>
            <CountryOfBirth>1101</CountryOfBirth>
        </Demographics>
        <AddressList>
            <Address Type="0123" Role="012A">
                <Street>
                    <Line1>Line1</Line1>
                </Street>
                <City>City1</City>
                <StateProvince>StatePrivince</StateProvince>
                <PostalCode>PostalCode</PostalCode>
            </Address>
        </AddressList>
        <EmailList>
            <Email Type="06">Dodich.Kira.G@vic.edu.au</Email>
        </EmailList>
    </PersonInfo>
    <MostRecent>
        <YearLevel><Code>6</Code></YearLevel>
        <Parent1Language>1201</Parent1Language>
        <Parent2Language>1201</Parent2Language>
        <Parent1EmploymentType>8</Parent1EmploymentType>
        <Parent2EmploymentType>3</Parent2EmploymentType>
        <Parent1SchoolEducationLevel>2</Parent1SchoolEducationLevel>
        <Parent2SchoolEducationLevel>0</Parent2SchoolEducationLevel>
        <Parent1NonSchoolEducation>5</Parent1NonSchoolEducation>
        <Parent2NonSchoolEducation>6</Parent2NonSchoolEducation>
    </MostRecent>
</StudentPersonal>
</StudentPersonals>
XML

xml_low = xml.gsub(%r{<StateProvinceId>[^<]+</StateProvinceId>}, "<StateProvinceId>ZZREDACTED</StateProvinceId>")

xml_medium = xml_low.gsub(%r{<BirthDate>[^<]+</BirthDate>}, "<BirthDate>1582-10-15</BirthDate>")
xml_medium.gsub!(%r{<Line1>[^<]+</Line1>}, "<Line1>ZZREDACTED</Line1>")
xml_medium.gsub!(%r{<City>[^<]+</City>}, "<City>ZZREDACTED</City>")
xml_medium.gsub!(%r{<StateProvince>[^<]+</StateProvince>}, "<StateProvince>ZZREDACTED</StateProvince>")
xml_medium.gsub!(%r{<PostalCode>[^<]+</PostalCode>}, "<PostalCode>ZZREDACTED</PostalCode>")

xml_high = xml_medium.gsub(%r{<LocalId>[^<]+</LocalId>}, "<LocalId>ZZREDACTED</LocalId>")
xml_high.gsub!(%r{<FamilyName>[^<]+</FamilyName>}, "<FamilyName>ZZREDACTED</FamilyName>")
xml_high.gsub!(%r{<GivenName>[^<]+</GivenName>}, "<GivenName>ZZREDACTED</GivenName>")
xml_high.gsub!(%r{<MiddleName>[^<]+</MiddleName>}, "<MiddleName>ZZREDACTED</MiddleName>")
xml_high.gsub!(%r{<PreferredGivenName>[^<]+</PreferredGivenName>}, "<PreferredGivenName>ZZREDACTED</PreferredGivenName>")
xml_high.gsub!(%r{<IndigenousStatus>[^<]+</IndigenousStatus>}, "<IndigenousStatus>ZZREDACTED</IndigenousStatus>")
xml_high.gsub!(%r{<Sex>[^<]+</Sex>}, "<Sex>ZZREDACTED</Sex>")
xml_high.gsub!(%r{<CountryOfBirth>[^<]+</CountryOfBirth>}, "<CountryOfBirth>ZZREDACTED</CountryOfBirth>")
xml_high.gsub!(%r{<Parent1Language>[^<]+</Parent1Language>}, "<Parent1Language>ZZREDACTED</Parent1Language>")
xml_high.gsub!(%r{<Parent2Language>[^<]+</Parent2Language>}, "<Parent2Language>ZZREDACTED</Parent2Language>")
xml_high.gsub!(%r{<Parent1EmploymentType>[^<]+</Parent1EmploymentType>}, "<Parent1EmploymentType>ZZREDACTED</Parent1EmploymentType>")
xml_high.gsub!(%r{<Parent2EmploymentType>[^<]+</Parent2EmploymentType>}, "<Parent2EmploymentType>ZZREDACTED</Parent2EmploymentType>")
xml_high.gsub!(%r{<Parent1SchoolEducationLevel>[^<]+</Parent1SchoolEducationLevel>}, "<Parent1SchoolEducationLevel>ZZREDACTED</Parent1SchoolEducationLevel>")
xml_high.gsub!(%r{<Parent2SchoolEducationLevel>[^<]+</Parent2SchoolEducationLevel>}, "<Parent2SchoolEducationLevel>ZZREDACTED</Parent2SchoolEducationLevel>")
xml_high.gsub!(%r{<Parent1NonSchoolEducation>[^<]+</Parent1NonSchoolEducation>}, "<Parent1NonSchoolEducation>ZZREDACTED</Parent1NonSchoolEducation>")
xml_high.gsub!(%r{<Parent2NonSchoolEducation>[^<]+</Parent2NonSchoolEducation>}, "<Parent2NonSchoolEducation>ZZREDACTED</Parent2NonSchoolEducation>")
xml_high.gsub!(%r{<Email([^>]*)>[^<]+</Email>}, "<Email\\1>ZZREDACTED</Email>")
xml_high.gsub!(%r{ RefId="[^"]+"}, ' RefId="00000000-0000-0000-0000-000000000000"')

xml_extreme = xml_high.gsub(%r{<YearLevel><Code>6</Code></YearLevel>}, "<YearLevel><Code>ZZREDACTED</Code></YearLevel>")

@service_name = 'ssf_services_cons_prod_privacyfilter_spec'
puts @service_name

describe "SIF Privacy Filter" do

def post_xml(xml) 
	Net::HTTP.start("localhost", "9292") do |http|
		request = Net::HTTP::Post.new("/rspec/test")
		request.body = xml
		request["Content-Type"] = "application/xml"
		http.request(request)
	end
end
		before(:context) do
			@xmlconsumernone = Poseidon::PartitionConsumer.new(@service_name, "localhost", 9092, "rspec.test.none", 0, :latest_offset)
			@xmlconsumerlow = Poseidon::PartitionConsumer.new(@service_name, "localhost", 9092, "rspec.test.low", 0, :latest_offset)
			@xmlconsumermedium = Poseidon::PartitionConsumer.new(@service_name, "localhost", 9092, "rspec.test.medium", 0, :latest_offset)
			@xmlconsumerhigh = Poseidon::PartitionConsumer.new(@service_name, "localhost", 9092, "rspec.test.high", 0, :latest_offset)
			@xmlconsumerextreme = Poseidon::PartitionConsumer.new(@service_name, "localhost", 9092, "rspec.test.extreme", 0, :latest_offset)
			puts "Next offset    = #{@xmlconsumernone.next_offset}"
			puts "Next offset    = #{@xmlconsumerlow.next_offset}"
			puts "Next offset    = #{@xmlconsumermedium.next_offset}"
			puts "Next offset    = #{@xmlconsumerhigh.next_offset}"
			puts "Next offset    = #{@xmlconsumerextreme.next_offset}"
			post_xml(xml)
			sleep 10
		end

		context "Valid XML into topic/stream" do
		
		it "pushes XML as is to topic/stream/none" do
			#puts "Next offset 1    = #{@xmlconsumernone.next_offset}"
			sleep 1
                       begin
                                a = @xmlconsumernone.fetch
                                expect(a).to_not be_nil
                                expect(a.empty?).to be false
				expected = xml.lines[1..-2].join.gsub(/\n[ ]+/,"")
				a[0].value.gsub!(/ xmlns="[^"]+"/, "").gsub!(/<\?[^>]*>\n/, "").gsub!(/\n[ ]+/,"")
                                expect(a[0].value.chomp).to eq expected.chomp
                        rescue Poseidon::Errors::OffsetOutOfRange
                            puts "[warning] - bad offset supplied, resetting..."
                            offset = :latest_offset
                            retry
                        end
		end

		it "pushes redacted XML to topic/stream/low" do
                       begin
                                a = @xmlconsumerlow.fetch
                                expect(a).to_not be_nil
                                expect(a.empty?).to be false
				expected = xml_low.lines[1..-2].join.gsub(/\n[ ]+/,"")
				a[0].value.gsub!(/ xmlns="[^"]+"/, "").gsub!(/<\?[^>]*>\n/, "").gsub!(/\n[ ]+/,"")
                                expect(a[0].value.chomp).to eq expected.chomp
                        rescue Poseidon::Errors::OffsetOutOfRange
                            puts "[warning] - bad offset supplied, resetting..."
                            offset = :latest_offset
                            retry
                        end
		end

		it "pushes redacted XML to topic/stream/medium" do
                       begin
                                a = @xmlconsumermedium.fetch
                                expect(a).to_not be_nil
                                expect(a.empty?).to be false
				expected = xml_medium.lines[1..-2].join.gsub(/\n[ ]+/,"")
				a[0].value.gsub!(/ xmlns="[^"]+"/, "").gsub!(/<\?[^>]*>\n/, "").gsub!(/\n[ ]+/,"")
                                expect(a[0].value.chomp).to eq expected.chomp
                        rescue Poseidon::Errors::OffsetOutOfRange
                            puts "[warning] - bad offset supplied, resetting..."
                            offset = :latest_offset
                            retry
                        end
		end

		it "pushes redacted XML to topic/stream/high" do
                       begin
                                a = @xmlconsumerhigh.fetch
                                expect(a).to_not be_nil
                                expect(a.empty?).to be false
				expected = xml_high.lines[1..-2].join.gsub(/\n[ ]+/,"")
				a[0].value.gsub!(/ xmlns="[^"]+"/, "").gsub!(/<\?[^>]*>\n/, "").gsub!(/\n[ ]+/,"")
                                expect(a[0].value.chomp).to eq expected.chomp
                        rescue Poseidon::Errors::OffsetOutOfRange
                            puts "[warning] - bad offset supplied, resetting..."
                            offset = :latest_offset
                            retry
                        end
		end

		it "pushes redacted XML to topic/stream/extreme" do
                       begin
                                a = @xmlconsumerextreme.fetch
                                expect(a).to_not be_nil
                                expect(a.empty?).to be false
				expected = xml_extreme.lines[1..-2].join.gsub(/\n[ ]+/,"")
				a[0].value.gsub!(/ xmlns="[^"]+"/, "").gsub!(/<\?[^>]*>\n/, "").gsub!(/\n[ ]+/,"")
                                expect(a[0].value.chomp).to eq expected.chomp
                        rescue Poseidon::Errors::OffsetOutOfRange
                            puts "[warning] - bad offset supplied, resetting..."
                            offset = :latest_offset
                            retry
                        end
		end
		after (:all) do
			sleep 10
		end



	end

end