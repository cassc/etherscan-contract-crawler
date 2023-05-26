// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Vesting contract using for distributing STRP tokens
 * @dev On ethereum for investors:
 * Grant rewards to Investors is continious.
 * @author Strips Finance
 **/
contract Vesting is 
    Ownable,
    ReentrancyGuard
{    
    // The holder of STRP, it approve Vesting contract to send tokens
    address public strp;
    address public dao;

    event VestingClaimed(
        address indexed investor, 
        uint amount
    );

    event VestingGranted(
        address indexed investor, 
        uint vestingPeriod,
        uint unlockPeriod,
        uint strpTotal,
        uint strpInitial
    );

    event VestingRemoved(
        address indexed investor
    );


    //Structure that controlls vesting info for investors
    struct VestingData {
        bool isActive;

        uint startTime;
        uint endTime;
        uint periodLength;  // unlock period length calc it upfront for optimization
        uint strpPerPeriod;  // calc it upfront for optimization

        uint strpTotal; // the maximum amount of STRP that investor can claim, includes intitial
        uint strpReleased;  // the STRP amount that investor has released
        uint strpInitial;   //custom initial amount that is available to be claimed immidiately (it's included to strpTotal)

        uint lastClaim;
    }

    struct InitVesting {
        address _investor;
        uint _period;
        uint _periodLength;
        uint _strpPerPeriod;
        uint _strpTotal;
        uint _strpInitial;
    }

    //investors
    mapping (address => VestingData) public investors;
    address[] public allInvestors;

    constructor(address _strp, address _dao) 
    {
        require(_dao != address(0), "ZERO_DAO");
        require(_strp != address(0), "ZERO_DAO");

        strp = _strp;
        dao = _dao;
    }

    function getAllInvestors() external view returns (address[] memory){
        return allInvestors;
    }

    function changeDao(address _dao) external onlyOwner {
        dao = _dao;
    }

    function changeStrp(address _strp) external onlyOwner {
        strp = _strp;
    }

    function removeVesting(address _investor) public onlyOwner {
        require(investors[_investor].isActive, "ALREADY_REMOVED");

        investors[_investor].isActive = false;
        

        /*Let's just 0 all to not have any bugs */
        investors[_investor].strpTotal = 0;
        investors[_investor].strpReleased = 0;
        investors[_investor].strpInitial = 0;

        investors[_investor].startTime = 0;
        investors[_investor].endTime = 0;
        investors[_investor].periodLength = 0;
        investors[_investor].strpPerPeriod = 0;
        investors[_investor].lastClaim = 0;

        emit VestingRemoved(_investor);
    }

    function grantBatchVesting(InitVesting[] memory batch) public onlyOwner {
        for (uint i=0; i<batch.length; i++) {
            if (investors[batch[i]._investor].isActive == true){
                continue;
            }

            grantVesting(batch[i]);
        }
    }

    function grantVesting(
        InitVesting memory _data
    ) public onlyOwner {
        require (investors[_data._investor].isActive == false, "ALREADY_GRANTED");
        require (block.timestamp < block.timestamp + _data._period, "PERIOD_IN_THE_PAST");

        investors[_data._investor] = VestingData({
            isActive:true,
            startTime:block.timestamp,
            endTime:block.timestamp + _data._period,

            periodLength: _data._periodLength,
            strpPerPeriod: _data._strpPerPeriod,

            strpTotal: _data._strpTotal,
            strpReleased: 0,
            strpInitial: _data._strpInitial,

            lastClaim: block.timestamp
        });

        allInvestors.push(_data._investor);

        emit VestingGranted(
            _data._investor, 
            _data._period,
            _data._periodLength,
            _data._strpTotal,
            _data._strpInitial);
    }

    /**
     * @dev View method for INVESTOR to check available amount of STRP unlocked
     * @return STRP amount available for claiming
     **/

    function checkVestingAvailable() public view returns (uint){
        require (investors[msg.sender].isActive == true, "NOT_VESTED");

        uint periodLength = investors[msg.sender].periodLength;
        uint start = investors[msg.sender].startTime;
        uint end = investors[msg.sender].endTime;

        /* user can withdraw everything if end date passed */
        if (block.timestamp > end){
            return (investors[msg.sender].strpTotal - investors[msg.sender].strpReleased);
        }

        uint unlockedPeriods = (block.timestamp - start) / periodLength - (investors[msg.sender].lastClaim - start) / periodLength;
        uint available = unlockedPeriods * investors[msg.sender].strpPerPeriod;
        
        if (investors[msg.sender].strpReleased == 0){
            return available + investors[msg.sender].strpInitial;
        }

        return available;
    }

    /**
     * @dev INVESTOR must execute this method to release the current total unlocked STRP amount.
     * DAO should approve Vesting for required amount
     **/
    function releaseVesting() external nonReentrant {
        require (investors[msg.sender].isActive == true, "NOT_VESTED");

        uint available = checkVestingAvailable();
        if (available == 0){
            return;
        }

        SafeERC20.safeTransferFrom(IERC20(strp), dao, msg.sender, available);

        investors[msg.sender].strpReleased += available;
        investors[msg.sender].lastClaim = block.timestamp;


        /*will be reverted on negative - free integrity check */
        uint rest = investors[msg.sender].strpTotal - investors[msg.sender].strpReleased;
        if (rest == 0){
            investors[msg.sender].isActive = false;
        }

        emit VestingClaimed(
            msg.sender,
            available
        );
    }


    function showVesting(address _investor) external view onlyOwner returns (uint){
        require (investors[_investor].isActive == true, "NOT_VESTED");

        uint periodLength = investors[_investor].periodLength;
        uint start = investors[_investor].startTime;
        uint end = investors[_investor].endTime;

        /* user can withdraw everything if end date passed */
        if (block.timestamp > end){
            return (investors[_investor].strpTotal - investors[_investor].strpReleased);
        }

        uint unlockedPeriods = (block.timestamp - start) / periodLength - (investors[_investor].lastClaim - start) / periodLength;
        uint available = unlockedPeriods * investors[_investor].strpPerPeriod;
        
        if (investors[_investor].strpReleased == 0){
            return available + investors[_investor].strpInitial;
        }

        return available;
    }


}