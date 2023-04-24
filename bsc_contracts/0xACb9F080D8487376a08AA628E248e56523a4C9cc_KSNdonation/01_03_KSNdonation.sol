// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./AggregatorV3Interface.sol";


contract KSNdonation {
    
    struct Donation {
        address donor;
        uint amount;
    }
    
    address payable public owner;
    mapping(uint => Donation) public donations;
    uint public donationIndex;
    IERC20 public ksnToken;
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
    
    event Donate(address indexed donor, uint amount);

    constructor(address _ksnToken, address _priceFeed) {
        owner = payable(msg.sender);
        ksnToken = IERC20(_ksnToken);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function donate(uint _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        uint allowance = ksnToken.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Insufficient token allowance");
        donationIndex++;
        ksnToken.transferFrom(msg.sender, address(this), _amount);
        donations[donationIndex] = Donation(msg.sender, _amount);
        emit Donate(msg.sender, _amount);
    }
    
    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw funds");
        uint balance = ksnToken.balanceOf(address(this));
        require(balance > 0, "No balance to withdraw");
        ksnToken.transfer(owner, balance);
    }
    
    function getDonation(uint _index) public view returns (address, uint) {
        Donation storage d = donations[_index];
        return (d.donor, d.amount);
    }
    
    function getDonationsCount() public view returns (uint) {
        return donationIndex;
    }
    
    function getKSNPrice() public view returns (uint) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        return uint(price);
    }
}