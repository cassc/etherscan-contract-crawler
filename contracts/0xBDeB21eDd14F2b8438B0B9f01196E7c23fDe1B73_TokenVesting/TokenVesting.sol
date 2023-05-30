/**
 *Submitted for verification at Etherscan.io on 2020-08-26
*/

pragma solidity 0.5.0;
pragma experimental ABIEncoderV2;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
    }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

    /**
    * @title Standard ERC20 token
    *
    * @dev Implementation of the basic standard token.
    * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
    * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
    */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }


    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= _balances[msg.sender]);
        require(to != address(0));

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        returns (bool)
    {
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed_[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param spender The address which will spend the funds.
    * @param addedValue The amount of tokens to increase the allowance by.
    */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed_[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param spender The address which will spend the funds.
    * @param subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Internal function that mints an amount of the token and assigns it to
    * an account. This encapsulates the modification of balances such that the
    * proper events are emitted.
    * @param account The account that will receive the created tokens.
    * @param amount The amount that will be created.
    */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
    * @dev Internal function that burns an amount of the token of a given
    * account.
    * @param account The account whose tokens will be burnt.
    * @param amount The amount that will be burnt.
    */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0));
        require(amount <= _balances[account]);

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
    * @dev Internal function that burns an amount of the token of a given
    * account, deducting from the sender's allowance for said account. Uses the
    * internal burn function.
    * @param account The account whose tokens will be burnt.
    * @param amount The amount that will be burnt.
    */
    function _burnFrom(address account, uint256 amount) internal {
        require(amount <= _allowed[account][msg.sender]);

        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
        amount);
        _burn(account, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getOwnerStatic(address ownableContract) internal view returns (address) {
        bytes memory callcodeOwner = abi.encodeWithSignature("getOwner()");
        (bool success, bytes memory returnData) = address(ownableContract).staticcall(callcodeOwner);
        require(success, "input address has to be a valid ownable contract");
        return parseAddr(returnData);
    }

    function getTokenVestingStatic(address tokenFactoryContract) internal view returns (address) {
        bytes memory callcodeTokenVesting = abi.encodeWithSignature("getTokenVesting()");
        (bool success, bytes memory returnData) = address(tokenFactoryContract).staticcall(callcodeTokenVesting);
        require(success, "input address has to be a valid TokenFactory contract");
        return parseAddr(returnData);
    }


    function parseAddr(bytes memory data) public pure returns (address parsed){
        assembly {parsed := mload(add(data, 32))}
    }




}

/**
 * @title TokenVesting contract for linearly vesting tokens to the respective vesting beneficiary
 * @dev This contract receives accepted proposals from the Manager contract, and holds in lieu
 * @dev all the tokens to be vested by the vesting beneficiary. It releases these tokens when called
 * @dev upon in a continuous-like linear fashion.
 * @notice This contract was written with reference to the TokenVesting contract from openZeppelin
 * @notice @ https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/drafts/TokenVesting.sol
 * @author Jake Goh Si Yuan @ jakegsy, [email protected]
 */
contract TokenVesting is Ownable{

    using SafeMath for uint256;

    event Released(address indexed token, address vestingBeneficiary, uint256 amount);
    event LogTokenAdded(address indexed token, address vestingBeneficiary, uint256 vestingPeriodInWeeks);

    uint256 constant public WEEKS_IN_SECONDS = 1 * 7 * 24 * 60 * 60;

    struct VestingInfo {
        address vestingBeneficiary;
        uint256 releasedSupply;
        uint256 start;
        uint256 duration;
    }

    mapping(address => VestingInfo) public vestingInfo;

    /**
     * @dev Method to add a token into TokenVesting
     * @param _token address Address of token
     * @param _vestingBeneficiary address Address of vesting beneficiary
     * @param _vestingPeriodInWeeks uint256 Period of vesting, in units of Weeks, to be converted
     * @notice This emits an Event LogTokenAdded which is indexed by the token address
     */
    function addToken
    (
        address _token,
        address _vestingBeneficiary,
        uint256 _vestingPeriodInWeeks
    )
    external
    onlyOwner
    {
        vestingInfo[_token] = VestingInfo({
            vestingBeneficiary : _vestingBeneficiary,
            releasedSupply : 0,
            start : now,
            duration : uint256(_vestingPeriodInWeeks).mul(WEEKS_IN_SECONDS)
        });
        emit LogTokenAdded(_token, _vestingBeneficiary, _vestingPeriodInWeeks);
    }

    /**
     * @dev Method to release any already vested but not yet received tokens
     * @param _token address Address of Token
     * @notice This emits an Event LogTokenAdded which is indexed by the token address
     */

    function release
    (
        address _token
    )
    external
    {
        uint256 unreleased = releaseableAmount(_token);
        require(unreleased > 0);
        vestingInfo[_token].releasedSupply = vestingInfo[_token].releasedSupply.add(unreleased);
        bool success = ERC20(_token).transfer(vestingInfo[_token].vestingBeneficiary, unreleased);
        require(success, "transfer from vesting to beneficiary has to succeed");
        emit Released(_token, vestingInfo[_token].vestingBeneficiary, unreleased);
    }

    /**
     * @dev Method to check the quantity of token that is already vested but not yet received
     * @param _token address Address of Token
     * @return uint256 Quantity of token that is already vested but not yet received
     */
    function releaseableAmount
    (
        address _token
    )
    public
    view
    returns(uint256)
    {
        return vestedAmount(_token).sub(vestingInfo[_token].releasedSupply);
    }

    /**
     * @dev Method to check the quantity of token vested at current block
     * @param _token address Address of Token
     * @return uint256 Quantity of token that is vested at current block
     */

    function vestedAmount
    (
        address _token
    )
    public
    view
    returns(uint256)
    {
        VestingInfo memory info = vestingInfo[_token];
        uint256 currentBalance = ERC20(_token).balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(info.releasedSupply);
        if (now >= info.start.add(info.duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(info.start)).div(info.duration);
        }

    }


    function getVestingInfo
    (
        address _token
    )
    external
    view
    returns(VestingInfo memory)
    {
        return vestingInfo[_token];
    }


}