/**
 *Submitted for verification at Etherscan.io on 2020-02-18
*/

// File: localhost/2key/ERC20/ERC20.sol

pragma solidity ^0.4.24;


contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _ocwner, address _spender) public view returns (uint256);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: localhost/2key/libraries/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    require(c / _a == _b);
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
    require(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    require(c >= _a);
    return c;
  }
}

// File: localhost/2key/ERC20/StandardTokenModified.sol

pragma solidity ^0.4.24;




/**
 * @author Nikola Madjarevic added frozen transfer options
 */
contract StandardTokenModified is ERC20 {

    using SafeMath for uint256;

    uint256 internal totalSupply_;
    string public name;
    string public symbol;
    uint8 public decimals;
    bool public transfersFrozen = false;


    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) internal balances;

    modifier onlyIfNotFrozen {
        require(transfersFrozen == false);
        _;
    }

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
    onlyIfNotFrozen
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
    function transfer(address _to, uint256 _value) public onlyIfNotFrozen returns (bool) {
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

// File: localhost/2key/interfaces/ITwoKeySingletoneRegistryFetchAddress.sol

pragma solidity ^0.4.24;
/**
 * @author Nikola Madjarevic
 * Created at 2/7/19
 */
contract ITwoKeySingletoneRegistryFetchAddress {
    function getContractProxyAddress(string _contractName) public view returns (address);
    function getNonUpgradableContractAddress(string contractName) public view returns (address);
    function getLatestCampaignApprovedVersion(string campaignType) public view returns (string);
}

// File: localhost/2key/non-upgradable-singletons/TwoKeyEconomy.sol

pragma solidity 0.4.24;




contract TwoKeyEconomy is StandardTokenModified {
    string public name = 'TwoKeyEconomy';
    string public symbol= '2KEY';
    uint8 public decimals= 18;

    address public twoKeyAdmin;
    address public twoKeySingletonRegistry;

    modifier onlyTwoKeyAdmin {
        require(msg.sender == twoKeyAdmin);
        _;
    }

    constructor (
        address _twoKeySingletonRegistry
    )
    public
    {
        twoKeySingletonRegistry = _twoKeySingletonRegistry;

        twoKeyAdmin = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).
            getContractProxyAddress("TwoKeyAdmin");

        address twoKeyUpgradableExchange = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).
            getContractProxyAddress("TwoKeyUpgradableExchange");
        address twoKeyParticipationMiningPool = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).
            getContractProxyAddress("TwoKeyParticipationMiningPool");
        address twoKeyNetworkGrowthFund = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).
            getContractProxyAddress("TwoKeyNetworkGrowthFund");
        address twoKeyMPSNMiningPool = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).
            getContractProxyAddress("TwoKeyMPSNMiningPool");
        address twoKeyTeamGrowthFund = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).
            getContractProxyAddress("TwoKeyTeamGrowthFund");


        totalSupply_= 600000000000000000000000000; // 600M tokens total minted supply

        balances[twoKeyUpgradableExchange] = totalSupply_.mul(3).div(100);
        emit Transfer(address(this), twoKeyUpgradableExchange, totalSupply_.mul(3).div(100));

        balances[twoKeyParticipationMiningPool] = totalSupply_.mul(20).div(100);
        emit Transfer(address(this), twoKeyParticipationMiningPool, totalSupply_.mul(20).div(100));

        balances[twoKeyNetworkGrowthFund] = totalSupply_.mul(16).div(100);
        emit Transfer(address(this), twoKeyNetworkGrowthFund, totalSupply_.mul(16).div(100));

        balances[twoKeyMPSNMiningPool] = totalSupply_.mul(10).div(100);
        emit Transfer(address(this), twoKeyMPSNMiningPool, totalSupply_.mul(10).div(100));

        balances[twoKeyTeamGrowthFund] = totalSupply_.mul(4).div(100);
        emit Transfer(address(this), twoKeyTeamGrowthFund, totalSupply_.mul(4).div(100));

        balances[twoKeyAdmin] = totalSupply_.mul(47).div(100);
        emit Transfer(address(this), twoKeyAdmin, totalSupply_.mul(47).div(100));
    }


    /// @notice TwoKeyAdmin is available to freeze all transfers on ERC for some period of time
    /// @dev in TwoKeyAdmin only Congress can call this
    function freezeTransfers()
    public
    onlyTwoKeyAdmin
    {
        transfersFrozen = true;
    }

    /// @notice TwoKeyAmin is available to unfreeze all transfers on ERC for some period of time
    /// @dev in TwoKeyAdmin only Congress can call this
    function unfreezeTransfers()
    public
    onlyTwoKeyAdmin
    {
        transfersFrozen = false;
    }

}