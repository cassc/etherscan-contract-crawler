// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";
import "@openzeppelin/[email protected]/security/Pausable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract SHIBAFIGHTERSICO is Pausable, Ownable {
    address public constant SFC = 0x0a5B855a743AA383A47804E1fE3c3Cd7d1F043D9;
    address public constant LIQUIDITY_POOL = 0x181576116D35c14eF6792c9Fb22D133d6440D5E7;
    
    uint public constant MAX_ORDER_SIZE = 5000000000000000000000000;
    mapping(address => uint) public orders;

    mapping(address => uint) public referrals;
    uint public rewardPercent = 15;
    uint public rewardPercentTo = 15;

    uint public valueForGetReward = 200000000000000000;
   
    uint public bnbPrice;
    uint public icoBalance;

    event Released(address indexed to, uint amount);

    function start() public onlyOwner {
       icoBalance = IERC20(SFC).balanceOf(address(this));
    }

    function purchese(address referral) public payable whenNotPaused {
        if(msg.value < valueForGetReward) 
        {
            _purchese(msg.value);
        }
        
        _purcheseWithReferral(msg.value, referral);
    }

    function _purchese(uint value) private returns (bool) {
        uint amount = (10000 * (bnbPrice * value * 1000000000000000000)) / 1000000000000000000; 
       
        require(amount <= icoBalance, "ICO BALANCE IS LESS THAN YOUR ORDER");
        require(amount < MAX_ORDER_SIZE, "MAX_ORDER_SIZE ERROR");
        require((orders[msg.sender] + amount) < MAX_ORDER_SIZE, "YOU ARE LIMITED");

        (bool liquiditySuccess, ) = LIQUIDITY_POOL.call{value: msg.value}("");

        if(liquiditySuccess) {
            IERC20(SFC).transfer(msg.sender, amount);
            orders[msg.sender] += amount;
            icoBalance -= amount;
            emit Released(msg.sender,amount);

            return true;
        }

        return false;
    }

    function _purcheseWithReferral(uint value, address referral) private returns (bool) {
        uint amount = (10000 * (bnbPrice * value * 1000000000000000000)) / 1000000000000000000; 
        uint referralReward = ((amount * rewardPercent) / 100);
        uint referralRewardTo = ((amount * rewardPercentTo) / 100);
        uint totalAmount = amount + referralReward + referralRewardTo;

        require(totalAmount <= icoBalance, "ICO BALANCE IS LESS THAN YOUR ORDER");
        require(totalAmount < MAX_ORDER_SIZE, "MAX_ORDER_SIZE ERROR");
        require((orders[msg.sender] + totalAmount) < MAX_ORDER_SIZE, "YOU ARE LIMITED");

        (bool liquiditySuccess, ) = LIQUIDITY_POOL.call{value: msg.value}("");

        if(liquiditySuccess) {
            IERC20(SFC).transfer(msg.sender, (amount + referralRewardTo));
            IERC20(SFC).transfer(referral, referralReward);
            orders[msg.sender] += amount;
            referrals[referral] += referralReward;
            icoBalance -= totalAmount;
            emit Released(msg.sender,amount);

            return true;
        }

        return false;
    }

    function setBnbPrice(uint price) public onlyOwner {
        bnbPrice = price;
    }

    function setRewardPercent(uint percent) public onlyOwner {
        rewardPercent = percent;
    }

    function setRewardPercentTo(uint percent) public onlyOwner {
        rewardPercentTo = percent;
    }

    function setValueForGetReward(uint value) public onlyOwner {
        valueForGetReward = value;
    }

    function emergencyWithdraw() public onlyOwner {
       uint balance = IERC20(SFC).balanceOf(address(this));
       IERC20(SFC).transfer(msg.sender, balance);
	   icoBalance -= balance;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}