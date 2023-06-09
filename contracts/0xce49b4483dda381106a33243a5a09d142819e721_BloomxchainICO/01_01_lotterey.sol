pragma solidity ^0.8.7;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * mul 
     * @dev Safe math multiply function
     */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  /**
   * add
   * @dev Safe math addition function
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

/**
 * @title Ownable
 * @dev Ownable has an owner address to simplify "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * Ownable
   * @dev Ownable constructor sets the `owner` of the contract to sender
   */
   constructor(){
    owner = msg.sender;
   }


  /**
   * ownerOnly
   * @dev Throws an error if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * transferOwnership
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

/**
 * @title Token
 * @dev API interface for interacting with the WILD Token contract 
 */
interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external;
  function balanceOf(address _owner) external view returns (uint256 balance);
}

/**
 * @title BloomXChainICO
 * @dev BloomXChainICO contract is Ownable
 **/
contract BloomxchainICO is Ownable {
  using SafeMath for uint256;
  Token token;
  Token USDT;

  uint256 public RATE = 10000; // Number of tokens per Ether
  uint256 public START = block.timestamp;
  uint256 public constant DAYS = 300; // 45 Day
  uint256 public raisedAmount = 0;
  
  /**
   * BoughtTokens
   * @dev Log tokens bought onto the blockchain
   */
  event BoughtTokens(address indexed to, uint256 value);

  /**
   * whenSaleIsActive
   * @dev ensures that the contract is still active
   **/
  modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());
    _;
  }
  
  /**
   * BloomXChainICO
   * @dev BloomXChainICO constructor
   **/
  constructor(address _tokenAddr, address _USDT) {
      require(_tokenAddr != address(0x0));
      require(_USDT != address(0x0));
      token = Token(_tokenAddr);
      USDT = Token(_USDT);
  }
  


  /**
   * isActive
   * @dev Determins if the contract is still active
   **/
  function isActive() public view returns (bool) {
    return (
        block.timestamp >= START && // Must be after the START date
        block.timestamp <= START.add(DAYS * 1 days)  // Must be before the end date

    );
  }

  /**
   * buyTokens
   * @dev function that sells available tokens
   **/
  function buyTokens(uint256 amount) public whenSaleIsActive {

    uint256 USDTtokens = (amount.mul(RATE)).div(10**18);
    USDT.transferFrom(msg.sender, owner,USDTtokens);
    raisedAmount = raisedAmount.add(USDTtokens); // Increment raised amount
    token.transfer(msg.sender, amount); // Send tokens to buyer
    
    emit BoughtTokens(msg.sender, amount); // log event onto the blockchain
  }


  function transferToken(address _tokenAddr) public onlyOwner{
    uint256 totalBalance = Token(_tokenAddr).balanceOf(address(address(this)));
    Token(_tokenAddr).transfer(owner, totalBalance); // Send tokens to buyer

  }


  function changeRate(uint256 _rate)public onlyOwner{
     require(_rate >0,"cant set 0");
     RATE = _rate;
  }

  /**
   * tokensAvailable
   * @dev returns the number of tokens allocated to address(this) contract
   **/
  function tokensAvailable() public view returns (uint256) {
    return token.balanceOf(address(this));
  }

  /**
   * destroy
   * @notice Terminate contract and refund to owner
   **/
  function destroy() onlyOwner public {
    // Transfer tokens back to owner
    uint256 balance = token.balanceOf(address(this));
    assert(balance > 0);
    token.transfer(owner, balance);
    // There should be no ether in the contract but just in case
    selfdestruct(payable(owner));
  }
}