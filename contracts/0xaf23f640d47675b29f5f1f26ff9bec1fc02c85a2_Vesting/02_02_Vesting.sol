// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract Vesting {

    address public immutable token;
    uint256 public immutable startTime;
    uint256 public immutable endTime;
    uint256 public immutable totalAmount;
    address public recipient;

    modifier onlyRecipient() {
        require(msg.sender == recipient, "Only recipient.");
        _;
    }

    constructor(address _token, uint256 _startTime, uint256 _endTime, address _recipient, uint256 _amount) {
        require(_startTime < _endTime, "Invalid timeframe.");
        token = _token;
        startTime = _startTime;
        endTime = _endTime;
        recipient = _recipient;
        totalAmount = _amount;
    }

    function getVestingStatus() public view returns (uint256 claimed, uint256 claimable, uint256 pending) {
        uint256 vested;
        (vested, pending) = _getVested();
        claimable = ERC20(token).balanceOf(address(this)) - pending;
        claimed = vested - claimable;
    }

    function claim() external onlyRecipient returns (uint256 amount) {
        (, amount, ) = getVestingStatus();
        ERC20(token).transfer(recipient, amount);
    }

    function changeRecipient(address _newRecipient) external onlyRecipient {
        recipient = _newRecipient;
    }

    function _getVested() internal view returns (uint256 vested, uint256 pending) {
        if (block.timestamp <= startTime) return (0, totalAmount);
        if (block.timestamp >= endTime) return (totalAmount, 0);
        uint256 passedTime = block.timestamp - startTime;
        uint256 totalTime = endTime - startTime;
        vested = totalAmount * passedTime / totalTime;
        return (vested, totalAmount - vested);
    }

}