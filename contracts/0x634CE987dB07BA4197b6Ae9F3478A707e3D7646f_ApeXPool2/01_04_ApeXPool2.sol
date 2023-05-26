// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IApeXPool2.sol";
import "../utils/Ownable.sol";
import "../libraries/TransferHelper.sol";

contract ApeXPool2 is IApeXPool2, Ownable {
    address public immutable override apeX;
    address public immutable override esApeX;

    mapping(address => mapping(uint256 => uint256)) public override stakingAPEX;
    mapping(address => mapping(uint256 => uint256)) public override stakingEsAPEX;

    bool public override paused;

    constructor(address _apeX, address _esApeX, address _owner) {
        apeX = _apeX;
        esApeX = _esApeX;
        owner = _owner;
    }

    function setPaused(bool newState) external override onlyOwner {
        require(paused != newState, "same state");
        paused = newState;
        emit PausedStateChanged(newState);
    }

    function stakeAPEX(uint256 accountId, uint256 amount) external override {
        require(!paused, "paused");
        TransferHelper.safeTransferFrom(apeX, msg.sender, address(this), amount);
        stakingAPEX[msg.sender][accountId] += amount;
        emit Staked(apeX, msg.sender, accountId, amount);
    }

    function stakeEsAPEX(uint256 accountId, uint256 amount) external override {
        require(!paused, "paused");
        TransferHelper.safeTransferFrom(esApeX, msg.sender, address(this), amount);
        stakingEsAPEX[msg.sender][accountId] += amount;
        emit Staked(esApeX, msg.sender, accountId, amount);
    }

    function unstakeAPEX(address to, uint256 accountId, uint256 amount) external override {
        require(amount <= stakingAPEX[msg.sender][accountId], "not enough balance");
        stakingAPEX[msg.sender][accountId] -= amount;
        TransferHelper.safeTransfer(apeX, to, amount);
        emit Unstaked(apeX, msg.sender, to, accountId, amount);
    }

    function unstakeEsAPEX(address to, uint256 accountId, uint256 amount) external override {
        require(amount <= stakingEsAPEX[msg.sender][accountId], "not enough balance");
        stakingEsAPEX[msg.sender][accountId] -= amount;
        TransferHelper.safeTransfer(esApeX, to, amount);
        emit Unstaked(esApeX, msg.sender, to, accountId, amount);
    }
}