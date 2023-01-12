// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./WSYRF.sol";

interface IBEP20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

contract SYRFICO {
    using SafeMath for uint256;
    AggregatorV3Interface internal priceFeed;
    //Administration Details
    address public admin;

    //Token
    WSYRF public token;
    IBEP20 BUSD;
    IBEP20 USDT;
    IBEP20 USDC;
    address public BUSD_Addr = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public USDT_Addr = 0x55d398326f99059fF775485246999027B3197955;
    address public USDC_Addr = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address private priceAddress = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE; // BNB/USD Mainnet
    //address private priceAddress = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526; // BNB/USD Testnet

    //ICO Details
    uint public tokenPrice = 50;
    uint public hardCap = 20000000;
    uint public raisedAmount;
    // uint public bnbprice = 25564418385;

    //Investor
    mapping(address => uint) public investedAmountOf;

    //ICO State
    enum State {
        BEFORE,
        RUNNING,
        END,
        HALTED
    }
    State public ICOState;

    //Events
    event Invest(
        address indexed from,
        address indexed to,
        uint value,
        uint tokens
    );

    event BoughtTokens(address indexed to, uint256 value);
    
    event TokenBurn(address to, uint amount, uint time);

    //Initialize Variables
    constructor(address _token) {
        admin = msg.sender;
        token = WSYRF(_token);
        BUSD = IBEP20(BUSD_Addr);
        USDT = IBEP20(USDT_Addr);
        USDC = IBEP20(USDC_Addr);
        priceFeed = AggregatorV3Interface(
            priceAddress
        );
    }

    //Access Control
    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin Only function");
        _;
    }

    //Receive Ether Directly
    receive() external payable {
        invest();
    }

    fallback() external payable {
        invest();
    }

    /* Functions */

    //Get ICO State
    function getICOState() external view returns (string memory) {
        if (ICOState == State.BEFORE) {
            return "Not Started";
        } else if (ICOState == State.RUNNING) {
            return "Running";
        } else if (ICOState == State.END) {
            return "End";
        } else {
            return "Halted";
        }
    }

    /* Admin Functions */

    //Start, Halt and End ICO
    function startICO() external onlyAdmin {
        require(ICOState == State.BEFORE, "ICO isn't in before state");
        ICOState = State.RUNNING;
    }

    function haltICO() external onlyAdmin {
        require(ICOState == State.RUNNING, "ICO isn't running yet");
        ICOState = State.HALTED;
    }

    function resumeICO() external onlyAdmin {
        require(ICOState == State.HALTED, "ICO State isn't halted yet");
        ICOState = State.RUNNING;
    }

    function endICO() external onlyAdmin {
        require(ICOState == State.RUNNING, "ICO State isn't running yet");
        ICOState = State.END;
    }

    //Change tokenprice
    function changeTokenPrice(uint _tokenPrice) external onlyAdmin {
        tokenPrice = _tokenPrice;
    }

    //Change amount of token sale
    function changeHardCap(uint _hardCap) external onlyAdmin {
        hardCap = _hardCap;
    }

    //Burn Tokens
    function burn() external onlyAdmin returns (bool)  {
        require(ICOState == State.END, "ICO isn't over yet");

        uint remainingTokens = token.balanceOf(address(this));
        bool success = token.transfer(address(0), remainingTokens);
        require(success, "Failed to burn remaining tokens");

        emit TokenBurn(address(0), remainingTokens, block.timestamp);
        return true;
    }

    //WithdrawBNB
    function withdrawBNB() public onlyAdmin {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    //WithdrawToken
    function withdrawToken(address _tokenAddr) public onlyAdmin {
        require(IBEP20(_tokenAddr).balanceOf(address(this)) > 0, "Sufficient Token balance");
        
        IBEP20(_tokenAddr).transfer(msg.sender, IBEP20(_tokenAddr).balanceOf(address(this)));
    }

    function changeSYRFAddr(address _newAddr) public onlyAdmin {
        token = WSYRF(_newAddr);
    }

    /* User Function */
    
    //Invest
    function invest() public payable returns (bool) {
        require(ICOState == State.RUNNING, "ICO isn't running");
        require(raisedAmount.add((msg.value.mul(getLatestPrice())).div(tokenPrice.mul(1e6))) <= hardCap.mul(10**18), "Send within hardcap range");

        uint tokens = ((msg.value.mul(getLatestPrice())).div(tokenPrice.mul(1e6)));

        investedAmountOf[msg.sender] = investedAmountOf[msg.sender].add(tokens);

        raisedAmount = raisedAmount.add(tokens);

        bool saleSuccess = token.transfer(msg.sender, tokens);
        require(saleSuccess, "Failed to Invest");

        emit Invest(address(this), msg.sender, msg.value, tokens);
        return true;
    }

    //Buy SYRF with other tokens
    function buyWithTokens(uint token_amount, address _tokenAddr) public returns (bool) {
        require(ICOState == State.RUNNING, "ICO isn't running");
        require(token_amount > 0, "Amount can't be zero numbers");
        require(raisedAmount.add(token_amount.mul(10**2).div(tokenPrice)) <= hardCap.mul(10**18), "Send within hardcap range");

        uint tokens = token_amount.mul(1e2).div(tokenPrice);

        if(_tokenAddr == BUSD_Addr) {
            BUSD.transferFrom(msg.sender, address(this), token_amount); // Bring ICO contract address BUSD tokens from buyer
        } else if(_tokenAddr == USDT_Addr) {
            USDT.transferFrom(msg.sender, address(this), token_amount); // Bring ICO contract address USDT tokens from buyer
        } else if(_tokenAddr == USDC_Addr) {
            USDC.transferFrom(msg.sender, address(this), token_amount); // Bring ICO contract address USDC tokens from buyer
        } else {
            return false;
        }

        investedAmountOf[msg.sender] = investedAmountOf[msg.sender].add(tokens);
        raisedAmount = raisedAmount.add(tokens);
        token.transfer(msg.sender, tokens); // Send WSYRF tokens to buyer

        emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain

        return true;
    }

    //Check ICO Contract Token Balance
    function getICOTokenBalance() external view returns (uint) {
        return token.balanceOf(address(this));
    }

    //Check ICO Contract Investor Token Balance
    function investorBalanceOf(address _investor) external view returns (uint) {
        return token.balanceOf(_investor);
    }

    function getLatestPrice() public view returns (uint) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return (uint)(price);
    }
}