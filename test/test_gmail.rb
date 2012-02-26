require 'test_helper'

class GmailTest < Test::Unit::TestCase
  def test_initialize
    imap = mock('imap')
    Net::IMAP.expects(:new).with('imap.gmail.com', 993, true, nil, false).returns(imap)
    gmail = Gmail.new('test@gmail.com', 'password')
  end
  
  def test_initialize_with_xoauth
    imap = mock('imap')
    Net::IMAP.expects(:new).with('imap.gmail.com', 993, true, nil, false).returns(imap)
    gmail = Gmail.new('test@gmail.com', nil, {
      :consumer_key => 'anonymous',
      :consumer_secret => 'anonymous',
      :token => 'some token',
      :token_secret => 'some secret'
    })
  end
  
  def test_xoauth_does_login
    setup_xoauth_mocks
    
    res = mock('res')
    res.expects(:name).at_least(1).returns('OK')
    
    @imap.expects(:authenticate).
      with('XOAUTH', 'test@gmail.com', {
      :consumer_key => 'anonymous',
      :consumer_secret => 'anonymous',
      :token => 'some token',
      :token_secret => 'some secret'
      }).
      returns(res)
    
    @gmail.imap
  end

  def test_imap_does_login
    setup_mocks(:at_exit => true)
    
    res = mock('res')
    res.expects(:name).at_least(1).returns('OK')

    @imap.expects(:login).
    with('test@gmail.com', 'password').
    returns(res)

    @gmail.imap
  end

  def test_imap_does_login_only_once
    setup_mocks(:at_exit => true)
    res = mock('res')
    res.expects(:name).at_least(1).returns('OK')

    @imap.expects(:login).with('test@gmail.com', 'password').returns(res)
    @gmail.imap
    @gmail.imap
    @gmail.imap
  end

  def test_imap_does_login_without_appending_gmail_domain
    setup_mocks(:at_exit => true)
    res = mock('res')
    res.expects(:name).at_least(1).returns('OK')

    @imap.expects(:login).with('test@gmail.com', 'password').returns(res)
    @gmail.imap
  end

  def test_imap_logs_out
    setup_mocks(:at_exit => true)
    res = mock('res')
    res.expects(:name).at_least(1).returns('OK')

    @imap.expects(:login).with('test@gmail.com', 'password').returns(res)
    @gmail.imap
    @imap.expects(:logout).returns(res)
    @gmail.logout
  end

  def test_imap_logout_does_nothing_if_not_logged_in
    setup_mocks

    @gmail.expects(:logged_in?).returns(false)
    @imap.expects(:logout).never
    @gmail.logout
  end

  def test_imap_calls_create_label
    setup_mocks(:at_exit => true)
    res = mock('res')
    res.expects(:name).at_least(1).returns('OK')

    @imap.expects(:login).with('test@gmail.com', 'password').returns(res)
    @imap.expects(:create).with('foo')
    @gmail.create_label('foo')
  end

  private
  
    def setup_xoauth_mocks(options = {})
      options = {:at_exit => true}.merge(options)
      
      @imap = mock('imap')
      Net::IMAP.expects(:new).with('imap.gmail.com', 993, true, nil, false).returns(@imap)
      @gmail = Gmail.new('test@gmail.com', nil, {
        :consumer_key => 'anonymous',
        :consumer_secret => 'anonymous',
        :token => 'some token',
        :token_secret => 'some secret'
      })
      # need this for the at_exit block that auto-exits after this test method completes
      @imap.expects(:logout).at_least(0) if options[:at_exit]
    end
  
  
  def setup_mocks(options = {})
    options = {:at_exit => false}.merge(options)
    @imap = mock('imap')
    Net::IMAP.expects(:new).with('imap.gmail.com', 993, true, nil, false).returns(@imap)
    @gmail = Gmail.new('test@gmail.com', 'password')

    # need this for the at_exit block that auto-exits after this test method completes
    @imap.expects(:logout).at_least(0) if options[:at_exit]
  end
end
