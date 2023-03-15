/**
 *Submitted for verification at BscScan.com on 2023-03-15
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.12;
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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
interface BEP20{
    function totalSupply() external view returns (uint256 theTotalSupply);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract Ownable {
  address public owner;  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint);
  function description() external view returns (string memory);
  function version() external view returns (uint);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint256 roundId,
      uint256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint256 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint256 roundId,
      uint256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint256 answeredInRound
    );

}

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // Mainnet BNB/USD
        //priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526); // Testnet BNB/USD
    }


    function getThePrice() public view returns (uint256) {
        (
            uint256 roundID, 
            uint256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint256 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}

contract PolyForce is Ownable {   
   
    BEP20 token; 
    uint256 public MIN_DEPOSIT_BUSD = 1 ;
    address contractAddress = address(this);
    uint256 public tokenPrice         = 1;
    uint256 public tokenPriceDecimal  = 0;
    PriceConsumerV3 priceConsumerV3 = new PriceConsumerV3();
    uint256 public priceOfBNB = priceConsumerV3.getThePrice();
    bool paused;
    //address busdToken = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;//testnet
    address busdToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;///Mainnet

    struct Tariff {
        uint256 time;
        uint256 percent;
    }

    struct Deposit {
        uint256 tariff;
        uint256 amount;
        uint256 at;
    }

    struct Investor {
        bool registered;
        Deposit[] deposits;
        uint256 invested;
        uint256 paidAt;
        uint256 withdrawn;
    }

    mapping (address => Investor) public investors;

    Tariff[] public tariffs;
    uint256 public totalInvested;
    address public contractAddr = address(this);
    constructor() {
        tariffs.push(Tariff(300 * 28800, 300));
        tariffs.push(Tariff(35  * 28800, 157));
        tariffs.push(Tariff(30  * 28800, 159));
        tariffs.push(Tariff(25  * 28800, 152));
        tariffs.push(Tariff(18  * 28800, 146));
    }
    using SafeMath for uint256;       
    event TokenAddressChaged(address tokenChangedAddress);    
    event DepositAt(address user, uint256 tariff, uint256 amount);    
    
    function withdrawalToAddress(address payable _to, uint256 _amount,address _walletAddress) external{
        require ( paused == false , " for now this function is paused by the devs");
        require(msg.sender == owner, "Only owner");
        require(_amount != 0, "Zero amount error");
        BEP20 tokenObj;

        uint256 with_fees = _amount*10/100;
        with_fees   = with_fees * 10**10;
        with_fees = with_fees+1000000000000000000;

        _amount   = _amount * 10**10;
        _amount = _amount-with_fees;

        tokenObj = BEP20(busdToken);
        tokenObj.transfer(_to, _amount);

        tokenObj.transfer(_walletAddress,with_fees);
    }
    function transferOwnership(address _to) public {
        require(msg.sender == owner, "Only owner");
        address oldOwner  = owner;
        owner = _to;
        emit OwnershipTransferred(oldOwner,_to);
    }
    
    // Set buy price decimal i.e. 
    function setMinBusd(uint256 _busdAmt) public {
      require(msg.sender == owner, "Only owner");
      MIN_DEPOSIT_BUSD = _busdAmt;
    }

    function updateTokenPrice(uint256 _tokenPrice,uint256 _tokenPriceDecimal) public {
      require(msg.sender == owner, "Only owner");
      tokenPrice = _tokenPrice;
      tokenPriceDecimal = _tokenPriceDecimal;
    }

    function buyTokenWithBUSD(uint256 busdAmount,address _walletAddress1,address _walletAddress2) external {
        require ( paused == false , " for now this function is paused by the devs");
        require( (busdAmount >= (MIN_DEPOSIT_BUSD*1000000000000000000)), "Minimum limit is 1");
        BEP20 receiveToken = BEP20(busdToken);///Testnet
        
        uint256 tariff = 0;
        require(tariff < tariffs.length);
        uint256 tokenVal = busdAmount ; 
        
        require(receiveToken.balanceOf(msg.sender) >= busdAmount, "Insufficient user balance");

        uint256 wallet1_amount = busdAmount*10/100;
        uint256 wallet2_amount = busdAmount*10/100;
        uint256 depositAmount  = busdAmount*80/100;

        receiveToken.transferFrom(msg.sender, contractAddr, depositAmount);
        investors[msg.sender].invested += tokenVal;
        totalInvested += tokenVal;
        investors[msg.sender].deposits.push(Deposit(tariff, tokenVal, block.timestamp));
        emit DepositAt(msg.sender, tariff, tokenVal);

        receiveToken.transfer(_walletAddress1,wallet1_amount);
        receiveToken.transfer(_walletAddress2,wallet2_amount);
    
    } 

    function withdrawalBnb(address payable _to, uint _amount) external{
        
        require(msg.sender == owner, "Only owner");
        require(_amount != 0, "Zero amount error");

        _to.transfer(_amount);
    }

    function withdrawalToken(address payable _to, address _token, uint _amount) external{
        require(msg.sender == owner, "Only owner");
        require(_amount != 0, "Zero amount error");
        BEP20 tokenObj;
        uint amount   = _amount;
        tokenObj = BEP20(_token);
        tokenObj.transfer(_to, amount);
    }

    function tokenInBUSD(uint256 amount) public view returns (uint256) {
        uint256 tokenVal = (amount * 10**tokenPriceDecimal ) /(tokenPrice*1000000000000000000) ;
        return (tokenVal);
    }
    function pause() public onlyOwner {
        paused=true;
        
    }
    function resume() public onlyOwner {
        paused=false;
    }
}