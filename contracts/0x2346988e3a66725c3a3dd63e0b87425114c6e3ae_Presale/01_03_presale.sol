// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 contract Presale is Ownable{
    using SafeMath for uint256;

    bool public isPresaleOpen = false;

    struct preBuy {
        string recipient;
        uint256 btcAmount;
        uint256 tokenAmount;
        uint256 feeInSats;
        address referrer;
    }

    mapping (address => preBuy) public preBuys;

    mapping (address => uint256) public paidTotal;
    // address where funds are collected
    address public wallet;
    // BTC-ETH feed address
    address public btcEthFeed;
    // buy rate: satoshi amount
    uint public rate;
    // referral fee
    uint public referralFeeRateBP = 100; // 1%
    // amount of wei raised
    uint public raisedAmount;

    uint256 public minBuyLimit = 10 ** 15; // min buyAmount is 0.1ETH

    event TokenPurchase(
        address indexed purchaser,
        uint256 amount,
        uint256 tokenAmount
    );

    receive() external payable {}

    constructor(uint256 _rate, address _wallet, address _btcEthFeed) {
        require(_rate > 0);
        require(_wallet != address(0));

        rate = _rate;
        wallet = _wallet;
        btcEthFeed = _btcEthFeed;
    }

    function setWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    }

    function startPresale() external onlyOwner {
        require(!isPresaleOpen, "Presale is open");
        
        isPresaleOpen = true;
    }

    function closePrsale() external onlyOwner {
        require(isPresaleOpen, "Presale is not open yet.");
        
        isPresaleOpen = false;
    }

    function setMinBuyLimit(uint256 _amount) external onlyOwner {
        minBuyLimit = _amount;    
    }

    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;    
    }

    function setReferralFeeRate(uint256 _rate) external onlyOwner {
        require(_rate <= 1000, "Max referral fee is 10%");
        rate = _rate;    
    }

    function getBTCPriceInETH() public view returns (uint256) {
        AggregatorV3Interface feed = AggregatorV3Interface(
            btcEthFeed
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = feed.latestRoundData();
        // decimal is 18
        return uint256(price);
    }

    // allows buyers to put their busd to get some token once the presale will closes
    function buy(string memory _recipient, uint256 _feeInSats, address _referrer) public payable {
        require(isPresaleOpen, "Presale is not open yet");
        require(msg.value >= minBuyLimit, "You need to sell at least some min amount");
        uint256 referralFee = 0;
        if (_referrer != address(0) && msg.sender != _referrer && preBuys[msg.sender].referrer == address(0)) {
            preBuys[msg.sender].referrer = _referrer;
        }
        if (preBuys[msg.sender].referrer != address(0)) {
            referralFee = msg.value.mul(referralFeeRateBP).div(10000);
            payable(preBuys[msg.sender].referrer).transfer(referralFee);
        }
        uint256 btcPrice = getBTCPriceInETH();

        // fee in ETH
        uint256 feeInETH = _feeInSats.mul(btcPrice).div(10 ** 8);
        // calculate token amount to be bought
        uint256 sellAmount = msg.value.sub(feeInETH).sub(referralFee);
        preBuys[msg.sender].tokenAmount = sellAmount.mul(10 ** 8).div(btcPrice).div(rate);
        preBuys[msg.sender].btcAmount = sellAmount.mul(10 ** 8).div(btcPrice);
        // update state
        raisedAmount = raisedAmount.add(msg.value);

        preBuys[msg.sender].recipient = _recipient;
        preBuys[msg.sender].feeInSats = _feeInSats;

        paidTotal[msg.sender] = paidTotal[msg.sender].add(sellAmount);
        emit TokenPurchase(
            msg.sender,
            sellAmount,
            preBuys[msg.sender].tokenAmount
        );
    }

    // allows operator wallet to get the fund deposited in the contract
    function retreiveFund() public {
        require(msg.sender == wallet);
        require(!isPresaleOpen, "Presale is not over yet");
        address payable recipient = payable(msg.sender);
        recipient.transfer(address(this).balance);
    }
}