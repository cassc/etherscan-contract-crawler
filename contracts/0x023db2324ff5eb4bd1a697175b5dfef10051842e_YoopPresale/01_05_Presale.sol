// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract YoopPresale is Ownable {
    using SafeMath for uint256;
    IERC20 internal token;

    uint256 public rate;
    uint256 public openingTime;
    uint256 public closingTime;
    uint256 public hardCap;
    uint256 public raisedAmount;
    uint256 public tokenAmount;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public balancesToken;

    mapping(address => bool) public whitelist; // Mapping of whitelisted addresses

    event TokenPurchase(address indexed purchaser, uint256 amount);
    event TokenClaim(address indexed claimer);

    constructor(uint256 _rate, address _token, uint256 _openingTime, uint256 _closingTime, uint256 _hardCap) public {
        require(_rate > 0, "Rate is 0");
        require(_token != address(0), "Token address is 0");
        require(_closingTime > _openingTime, "ClosingTime needs to be superior");
        rate = _rate;
        token = IERC20(_token);
        openingTime = _openingTime;
        closingTime = _closingTime;
        hardCap = _hardCap * 10**18;
    }

    modifier icoOpen {
        require(block.timestamp >= openingTime && block.timestamp <= closingTime, "ICO not open");
        _;
    }

    modifier icoFinished {
        require(block.timestamp > closingTime, "ICO not finished");
        _;
    }

   
    function addToWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }
    function removeFromWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
    }

    mapping(address => uint256) public contributionAmount;

    function buyTokens() public payable icoOpen {
        require(whitelist[msg.sender], "Address not whitelisted");
        require(tokenAmount < hardCap, "Hard Cap reached");

        uint256 value = msg.value;
        uint256 tokens = value.mul(rate);
        raisedAmount = raisedAmount.add(value);
        tokenAmount = tokenAmount.add(tokens);
        balances[msg.sender] = balances[msg.sender].add(value);
        balancesToken[msg.sender] = balancesToken[msg.sender].add(tokens);

        // Additional constraints for minimum and maximum contributions
        uint256 minContribution = 0.05 ether;
        uint256 maxContribution = 2 ether;
        require(value >= minContribution, "Minimum contribution not met");
        require(contributionAmount[msg.sender].add(value) <= maxContribution, "Maximum contribution exceeded");

        // Update the contribution amount for the sender
        contributionAmount[msg.sender] = contributionAmount[msg.sender].add(value);

        emit TokenPurchase(msg.sender, tokens);

        uint256 amount = balancesToken[msg.sender];
        require(amount > 0);
        balancesToken[msg.sender] = 0;
        token.transfer(msg.sender, amount);
    }
    function withdrawTokens() public  {
        uint256 amount = balancesToken[msg.sender];
        require(amount > 0);
        balancesToken[msg.sender] = 0;
        token.transfer(msg.sender, amount);
    }
    function withdraw(uint256 amount) public onlyOwner returns (bool success) {
        require(amount <= address(this).balance, "ICO: function withdraw invalid input");
        payable(_msgSender()).transfer(amount);
        return true;
    }

    function getBalance() public view returns(uint256) {
        return balances[msg.sender];
    }

    function getBalanceToken() public view returns(uint256) {
        return balancesToken[msg.sender];
    }

    function changeClosingTime(uint256 _closingTime) public onlyOwner {
        closingTime = _closingTime;
    }
}