// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ITomi.sol";

contract TomiVesting {
    using SafeMath for uint256;

    ITomi public TOMI;

    // First Year Clif
    uint256 private firstVesting;
    uint256 private lastVesting;


    struct Info {
        address account;
        uint256 amountVested;
        uint256 totalClaimed;
        bool firstVestingClaimed;
        uint256 lastClaim;
        uint256 firstAmount;
        uint256 afterAmount;
    }

    Info public tomi2Cliff;
    Info public tomi1;
    Info public tomi2;


    event vestingClaimedTomi2Cliff (
        uint256 timestamp,
        uint256 amount
    );


    event vestingClaimedTomi1 (
        uint256 timestamp,
        uint256 amount
    );

     event vestingClaimedTomi2 (
        uint256 timestamp,
        uint256 amount
    );

    constructor(address tomi1_, address tomi2_, ITomi tomi_) {
        TOMI = tomi_;
        firstVesting = block.timestamp.add(365 days);
        lastVesting = block.timestamp.add(1826 days);
        tomi2Cliff = Info(tomi2_, 59760000000000000000000000,0,false,0,11945454545500000000000000,32727272727300000000000);
        tomi1 = Info(tomi1_, 41835000000000000000000000,0,false,block.timestamp,0,22910733844500000000000);
        tomi2 = Info(tomi2_, 48405000000000000000000000,0,false,block.timestamp,0,26508762322000000000000);
    }

    function claimTomi2Cliff() external {
        require(tomi2Cliff.account == msg.sender, "Not Authorised");
        require(block.timestamp >= firstVesting, "Vesting Not Open");
        require(tomi2Cliff.totalClaimed < tomi2Cliff.amountVested , "Already fully claimed");

        if (!tomi2Cliff.firstVestingClaimed) {
            TOMI.mintThroughVesting(tomi2Cliff.account, tomi2Cliff.firstAmount);
            tomi2Cliff.firstVestingClaimed = true;
            tomi2Cliff.lastClaim = firstVesting;
            tomi2Cliff.totalClaimed = tomi2Cliff.firstAmount;
            emit vestingClaimedTomi2Cliff(block.timestamp , tomi2Cliff.firstAmount);
            return;
        }

        uint256 startDate = tomi2Cliff.lastClaim; // eg 2018-01-01 00:00:00
        uint256 endDate = block.timestamp < lastVesting ? block.timestamp : lastVesting; // eg 2018-02-10 00:00:00

        uint256 diff = (endDate.sub(startDate)).div(60).div(60).div(24); // eg 40 days 

        if(diff <= 0){
            revert("Already Claimed");
        }

        uint256 amount = diff.mul(tomi2Cliff.afterAmount);

        TOMI.mintThroughVesting(tomi2Cliff.account, amount);
        tomi2Cliff.lastClaim = block.timestamp;
        tomi2Cliff.totalClaimed = tomi2Cliff.totalClaimed.add(amount);
        emit vestingClaimedTomi2Cliff(block.timestamp, amount);
    }
    
    function claimTomi1() external {
        require(tomi1.account == msg.sender, "Not Authorised");
        require(tomi1.totalClaimed < tomi1.amountVested , "Already fully claimed");

        uint256 startDate = tomi1.lastClaim; // eg 2018-01-01 00:00:00
        uint256 endDate = block.timestamp < lastVesting ? block.timestamp : lastVesting; // eg 2018-02-10 00:00:00

        uint256 diff = (endDate.sub(startDate)).div(60).div(60).div(24); // eg 40 days 

        if(diff <= 0){
            revert("Already Claimed");
        }

        uint256 amount = diff.mul(tomi1.afterAmount);

        TOMI.mintThroughVesting(tomi1.account, amount);
        tomi1.lastClaim = block.timestamp;
        tomi1.totalClaimed = tomi1.totalClaimed.add(amount);
        emit vestingClaimedTomi1(block.timestamp, amount);
    }

    function claimTomi2() external {
        require(tomi2.account == msg.sender, "Not Authorised");
        require(tomi2.totalClaimed < tomi2.amountVested , "Already fully claimed");

        uint256 startDate = tomi2.lastClaim; // eg 2018-01-01 00:00:00
        uint256 endDate = block.timestamp < lastVesting ? block.timestamp : lastVesting; // eg 2018-02-10 00:00:00

        uint256 diff = (endDate.sub(startDate)).div(60).div(60).div(24); // eg 40 days 

        if(diff <= 0){
            revert("Already Claimed");
        }

        uint256 amount = diff.mul(tomi2.afterAmount);

        TOMI.mintThroughVesting(tomi2.account, amount);
        tomi2.lastClaim = block.timestamp;
        tomi2.totalClaimed = tomi2.totalClaimed.add(amount);
        emit vestingClaimedTomi2(block.timestamp, amount);
    }
}