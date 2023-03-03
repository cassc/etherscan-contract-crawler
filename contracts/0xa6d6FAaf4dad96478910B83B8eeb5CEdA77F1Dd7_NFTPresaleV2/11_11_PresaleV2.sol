// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Presale.sol";

contract NFTPresaleV2 is Ownable {
    using SafeERC20 for IERC20;

    address public usdtAddress;
    address public paradoxAddress;

    IERC20 internal para;
    IERC20 internal usdt;

    NFTPresale public presaleV1;

    uint256 constant mintSupply = 12500000 * paradoxDecimals;

    uint256 constant paradoxDecimals = 10 ** 18;
    uint256 constant usdtDecimals = 10 ** 6;

    uint256 constant exchangeRateV1 = 8;
    uint256 constant exchangeRatePrecisionV1 = 100;

    uint256 constant exchangeRateV2 = 27;
    uint256 constant exchangeRatePrecisionV2 = 1000;

    uint256 private forteenNovemberTimestamp = 1668420935;


    uint256 constant month = 4 weeks;

    mapping(address => Lock) public locks;

    mapping(address => bool)public islockedOnV2;

    struct Lock {
        uint256 total;
        uint256 max;
        uint256 paid;
        uint256 debt;
        uint256 startTime;
    }

    constructor(address _usdt, address _paradox, address _presaleV1) {
        usdtAddress = _usdt;
        usdt = IERC20(_usdt);

        paradoxAddress = _paradox;
        para = IERC20(_paradox);

        presaleV1 = NFTPresale(_presaleV1);
    }

    function pendingVestedClaim(address _user) external view returns (uint256) {
          Lock memory userLock;

         if(islockedOnV2[_user]){
              userLock = locks[_user];
         }else{
            (  uint256 total, uint256 max, uint256 paid, uint256 debt,uint256 startTime) = presaleV1.locks(_user);
              userLock.total = total;
              userLock.paid = paid;
              userLock.startTime = forteenNovemberTimestamp;
              userLock.debt = debt;
              userLock.max = max;

            // 100% of bought tokens for 0.08$
           uint256 initialTotal = userLock.total + (userLock.total * 10 / 100);
            // Initial amount of usdt user send to buy Parapad 
           uint256 buyAmount = initialTotal * (usdtDecimals * exchangeRateV1)/(exchangeRatePrecisionV1 * paradoxDecimals);
            // 100% of bought tokens for 0.027$
           uint256 newTotal = (buyAmount * exchangeRatePrecisionV2 * paradoxDecimals) / (usdtDecimals * exchangeRateV2);

           userLock.total = newTotal - ((newTotal*10)/100);
         }

         uint256 monthsPassed = (block.timestamp - userLock.startTime) / 4 weeks;

        /** @notice userlock.total = 90%, 5% released each month. */
        uint256 monthlyRelease = (userLock.total + (userLock.total * 10)/100) * 5 / 100;

        uint256 release;
        for (uint256 i = 0; i < monthsPassed; i++) {

            if (release >= userLock.total) {
                    release = userLock.total;
                    break;
            }
            release += monthlyRelease;
        }

        uint256 reward = release - userLock.debt;

        return reward;
    }

    function claimVested() external {
        
         Lock memory userLock;

         if(islockedOnV2[msg.sender]){
              userLock = locks[msg.sender];
         }else{
            (  uint256 total, uint256 max, uint256 paid, uint256 debt,uint256 startTime) = presaleV1.locks(msg.sender);
              userLock.total = total;
              userLock.paid = paid;
              userLock.startTime = forteenNovemberTimestamp;
              userLock.debt = debt;
              userLock.max = max;

            // 100% of bought tokens for 0.08$
           uint256 initialTotal = userLock.total + (userLock.total * 10 / 100);
            // Initial amount of usdt user send to buy Parapad 
           uint256 buyAmount = initialTotal * (usdtDecimals * exchangeRateV1)/(exchangeRatePrecisionV1 * paradoxDecimals);
            // 100% of bought tokens for 0.027$
           uint256 newTotal = (buyAmount * exchangeRatePrecisionV2 * paradoxDecimals) / (usdtDecimals * exchangeRateV2);

            userLock.total = newTotal - ((newTotal*10)/100);
         }

         uint256 monthsPassed = (block.timestamp - userLock.startTime) / 4 weeks;

        /** @notice userlock.total = 90%, 5% released each month. */
        uint256 monthlyRelease = (userLock.total + (userLock.total * 10)/100) * 5 / 100;

        uint256 release;
        for (uint256 i = 0; i < monthsPassed; i++) {
            if (release >= userLock.total) {
                    release = userLock.total;
                    break;
            }
            release += monthlyRelease;
        }

        uint256 reward = release - userLock.debt;
        userLock.debt += reward;

        // Save userLock info to the storage
        locks[msg.sender] = userLock;      
        
        // Update mapping to identify where to fetch info about user lock
        if(!islockedOnV2[msg.sender]){
          islockedOnV2[msg.sender] = true;
        }
        para.safeTransfer(msg.sender, reward);
    }

    function withdrawTether() external onlyOwner {
        usdt.safeTransfer(msg.sender, usdt.balanceOf(address(this)));
    }

    function withdrawETH() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    function withdrawParadox() external onlyOwner {
        para.safeTransfer(msg.sender, para.balanceOf(address(this)));
    }

    function setTimestamp(uint256 _newTimestamp) external onlyOwner {
       forteenNovemberTimestamp = _newTimestamp;
    }

     function getUserLeftToClaim(address _user) external view returns(uint256){
         Lock memory userLock;

         if(islockedOnV2[_user]){
              userLock = locks[_user];
         }else{
            (  uint256 total, uint256 max, uint256 paid, uint256 debt,uint256 startTime) = presaleV1.locks(msg.sender);
              userLock.total = total;
              userLock.paid = paid;
              userLock.startTime = startTime;
              userLock.debt = debt;
              userLock.max = max;
         }

         return userLock.total - userLock.debt;
    }

    function getUserNextClaimTimestamp(address _user) external view returns(uint256){
         Lock memory userLock;

         if(islockedOnV2[_user]){
              userLock = locks[_user];
         }else{
            (  uint256 total, uint256 max, uint256 paid, uint256 debt,uint256 startTime) = presaleV1.locks(msg.sender);
              userLock.total = total;
              userLock.paid = paid;
              userLock.startTime = startTime;
              userLock.debt = debt;
              userLock.max = max;
         }
        
        uint256 monthsPassed = (block.timestamp - userLock.startTime) / 4 weeks;
        
        uint256 nextClaimTimestamp = monthsPassed + month;

         return nextClaimTimestamp - block.timestamp;
    }

     function getUserClaimed(address _user) external view returns(uint256){
         Lock memory userLock;

         if(islockedOnV2[_user]){
              userLock = locks[_user];
         }else{
           (  uint256 total, uint256 max, uint256 paid, uint256 debt,uint256 startTime) = presaleV1.locks(msg.sender);
              userLock.total = total;
              userLock.paid = paid;
              userLock.startTime = startTime;
              userLock.debt = debt;
              userLock.max = max;
         }

         return userLock.debt;
    }
}