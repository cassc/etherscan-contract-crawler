/**
 * Equity wallet
 * Written by canp.eth
 */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EquityWallet is Ownable, ReentrancyGuard {
    // mapping percentage equity (out of 100) of each address in team
    mapping(address => uint) private _equityPercentages;

    // mapping of ethers already withdrawn for each address in team
    mapping(address => uint) private _withdrawnEthers;

    // total number of Ether ever sent to the contract (NOT current balance)
    uint private _accumulatedEthers;

    /** after being set, all equity percentages are locked in and cannot be changed again,
     * even by the owner.
     */
    bool private _isEquitiesLocked = false;

    /** updates equity of the team members. can only be called by the owner.
     * percentage in denoted in 0-100. so 50 means 50% equity in the project.
     */
    function updateEquity(address teamMemberAddress, uint percentage) public onlyOwner {
        require(!_isEquitiesLocked, "Equities are locked");
        require(percentage >= 0);
        require(percentage <= 100);
        if(percentage > 0){
            _equityPercentages[teamMemberAddress] = percentage;
        }else{
            delete _equityPercentages[teamMemberAddress];
        }
    }

    /** when called by the owner, equities can't be changed anymore.
     * there is no going back so call this one with caution.
     */
    function lockEquities() public onlyOwner {
        _isEquitiesLocked = true;
    }

    receive() external payable {
        _accumulatedEthers += msg.value;
    }

    /**
     *  withdraw all remaining equity from the contract for the calling user
     * can only be called by wallets with equity in the contract
     */
    function withdraw() public nonReentrant {
        // get how much % of the total funds caller can claim 
        uint callerEquityPercentage = _equityPercentages[msg.sender];
        
        require(callerEquityPercentage > 0, "Caller has 0 equity");


        // calculate how much ether is ever collected to date in the contract
        uint totalAccumulatedEther = _accumulatedEthers;

        // find the actual amount that the user could have ever withdrawn until now
        uint callerTotalEquity = totalAccumulatedEther * callerEquityPercentage / 100;

        // subtract any amount that has already been withdrawn
        uint callerAvailableEquity = callerTotalEquity - _withdrawnEthers[msg.sender];

        // check if there is any available funds to withdraw
        require(callerAvailableEquity > 0, "No funds to withdraw");

        // send the amount to the caller
        (bool success, ) = (msg.sender).call{value: callerAvailableEquity}("");

        require(success, "Unable to withdraw");

        // update withdrawn amount for that user
        _withdrawnEthers[msg.sender] += callerAvailableEquity;
    }

}