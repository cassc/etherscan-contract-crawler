/**
 *Submitted for verification at Etherscan.io on 2019-09-05
*/

/**
 *Submitted for verification at Etherscan.io on 2019-07-31
*/

pragma solidity ^0.4.21;

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public payable returns (bool);
}

library Math {
  function max64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a >= _b ? _a : _b;
  }

  function min64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a < _b ? _a : _b;
  }

  function max256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a >= _b ? _a : _b;
  }

  function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract StandardBurnableToken is BurnableToken, StandardToken {

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}


contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _start the time (as Unix time) at which point vesting starts
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param _token ERC20 token which is being vested
   */
  function release(ERC20Basic _token) public {
    uint256 unreleased = releasableAmount(_token);

    require(unreleased > 0);

    released[_token] = released[_token].add(unreleased);

    _token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param _token ERC20 token which is being vested
   */
  function revoke(ERC20Basic _token) public onlyOwner {
    require(revocable);
    require(!revoked[_token]);

    uint256 balance = _token.balanceOf(address(this));

    uint256 unreleased = releasableAmount(_token);
    uint256 refund = balance.sub(unreleased);

    revoked[_token] = true;

    _token.safeTransfer(owner, refund);

    emit Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param _token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic _token) public view returns (uint256) {
    return vestedAmount(_token).sub(released[_token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param _token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic _token) public view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(released[_token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[_token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}


contract TokenPool {
    ERC20Basic public token;

    modifier poolReady {
        require(token != address(0));
        _;
    }

    function setToken(ERC20Basic newToken) public {
        require(token == address(0));

        token = newToken;
    }

    function balance() view public returns (uint256) {
        return token.balanceOf(this);
    }

    function transferTo(address dst, uint256 amount) internal returns (bool) {
        return token.transfer(dst, amount);
    }

    function getFrom() view public returns (address) {
        return this;
    }
}

contract AdvisorPool is TokenPool, Ownable {

    function addVestor(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 totalTokens
    ) public onlyOwner poolReady returns (TokenVesting) {
        TokenVesting vesting = new TokenVesting(_beneficiary, _start, _cliff, _duration, false);

        transferTo(vesting, totalTokens);

        return vesting;
    }

    function transfer(address _beneficiary, uint256 amount) public onlyOwner poolReady returns (bool) {
        return transferTo(_beneficiary, amount);
    }
}

contract TeamPool is TokenPool, Ownable {

    mapping(address => TokenVesting[]) cache;

    function addVestor(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 totalTokens,
        bool revokable
    ) public onlyOwner poolReady returns (TokenVesting) {
        cache[_beneficiary].push(new TokenVesting(_beneficiary, _start, _cliff, _duration, revokable));

        uint newIndex = cache[_beneficiary].length - 1;

        transferTo(cache[_beneficiary][newIndex], totalTokens);

        return cache[_beneficiary][newIndex];
    }

    function vestingCount(address _beneficiary) public view poolReady returns (uint) {
        return cache[_beneficiary].length;
    }

    function revoke(address _beneficiary, uint index) public onlyOwner poolReady {
        require(index < vestingCount(_beneficiary));
        require(cache[_beneficiary][index] != address(0));

        cache[_beneficiary][index].revoke(token);
    }
}

contract StandbyGamePool is TokenPool, Ownable {
    TokenPool public currentVersion;
    bool public ready = false;

    function update(TokenPool newAddress) onlyOwner public {
        require(!ready);
        ready = true;
        currentVersion = newAddress;
        transferTo(newAddress, balance());
    }

    function() public payable {
        require(ready);
        if(!currentVersion.delegatecall(msg.data)) revert();
    }
}

contract TokenUpdate is StandardBurnableToken, DetailedERC20 {
    event Mint(address indexed to, uint256 amount);
    
    mapping(address => bool) internal _legacyTokens;
    
    address internal defaultLegacyToken;
    
    function _mint(address _to, uint256 _amount) internal returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
                
    /**
   * @dev Transfers part of an account's balance in the old token to this
   * contract, and mints the same amount of new tokens for that account.
   * @param token The legacy token to migrate from, should be registered under this token
   * @param account whose tokens will be migrated
   * @param amount amount of tokens to be migrated
   */
   function migrate(address token, address account, uint256 amount) public {
       require(_legacyTokens[token]);
       
       StandardBurnableToken legacyToken = StandardBurnableToken(token);
       
       legacyToken.burnFrom(account, amount);
       _mint(account, amount); 
   }

  /**
   * @dev Transfers all of an account's allowed balance in the old token to
   * this contract, and mints the same amount of new tokens for that account.
   * @param token The legacy token to migrate from, should be registered under this token
   * @param account whose tokens will be migrated
   */
  function migrateAll(address token, address account) public {
      require(_legacyTokens[token]);
       
      StandardBurnableToken legacyToken = StandardBurnableToken(token);
       
      uint256 balance = legacyToken.balanceOf(account);
      uint256 allowance = legacyToken.allowance(account, this);
      uint256 amount = Math.min256(balance, allowance);
      migrate(token, account, amount);
  }
  
  function migrateAll(address account) public {
      migrateAll(defaultLegacyToken, account);
  }
}


contract BenzeneToken is TokenUpdate, ApproveAndCallFallBack {
    using SafeMath for uint256;

    string public constant name = "Benzene";
    string public constant symbol = "BZN";
    uint8 public constant decimals = 18;

    address public GamePoolAddress;
    address public TeamPoolAddress;
    address public AdvisorPoolAddress;

    constructor(address gamePool,
                address teamPool, //vest
                address advisorPool,
                address oldTeamPool,
                address oldAdvisorPool,
                address[] oldBzn) public DetailedERC20(name, symbol, decimals) {
        
        require(oldBzn.length > 0);
        
        DetailedERC20 _legacyToken; //Save the last token (should be latest version)
        for (uint i = 0; i < oldBzn.length; i++) {
            //Ensure this is an actual token
            _legacyToken = DetailedERC20(oldBzn[i]);
            
            //Now register it for update
            _legacyTokens[oldBzn[i]] = true;
        }
        
        defaultLegacyToken = _legacyToken;
        
        GamePoolAddress = gamePool;
        
        uint256 teampool_balance =  _legacyToken.balanceOf(oldTeamPool);
        require(teampool_balance > 0); //Ensure the last token actually has a balance
        balances[teamPool] = teampool_balance;
        totalSupply_ = totalSupply_.add(teampool_balance);
        TeamPoolAddress = teamPool;

        
        uint256 advisor_balance =  _legacyToken.balanceOf(oldAdvisorPool);
        require(advisor_balance > 0); //Ensure the last token actually has a balance
        balances[advisorPool] = advisor_balance;
        totalSupply_ = totalSupply_.add(advisor_balance);
        AdvisorPoolAddress = advisorPool;
                    
        TeamPool(teamPool).setToken(this);
        AdvisorPool(advisorPool).setToken(this);
    }
  
  function approveAndCall(address spender, uint tokens, bytes memory data) public payable returns (bool success) {
      super.approve(spender, tokens);
      
      ApproveAndCallFallBack toCall = ApproveAndCallFallBack(spender);
      
      require(toCall.receiveApproval.value(msg.value)(msg.sender, tokens, address(this), data));
      
      return true;
  }
  
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public payable returns (bool) {
      super.migrate(token, from, tokens);
      
      return true;
  }
}