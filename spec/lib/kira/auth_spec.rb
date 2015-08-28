describe Kira::Auth do

  let ( :credentials ) { { key: 'ddc6ced6898b40f8b90aecb55c363824', secret: 'c73675c025034db8a4deaad8513a8721' } }

  let ( :client ) { Kira::Auth.new(credentials) }

  it 'gets an access token' do
    expect( client.access_token.length ).to eq 32
  end

end
