// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "./FeeToken.sol";

contract bSMC is FeeToken {
    event Stake(address indexed _account, uint256 indexed _amount, uint256 indexed _timestamp);

    constructor (address _USDT, address _SMC) FeeToken(_USDT, _SMC, "Burnt SMC", "bSMC", 0) {}

    function stake(uint256 _toStake) external nonReentrant {
        if (_toStake > underlyingToken.balanceOf(msg.sender)) {
            revert InsufficientSMCBalance(_toStake, underlyingToken.balanceOf(msg.sender));
        }
        if (_toStake > underlyingToken.allowance(msg.sender, address(this))) {
            revert InsufficientSMCAllowance(_toStake, underlyingToken.allowance(msg.sender, address(this)));
        }
        underlyingToken.burnFrom(msg.sender, _toStake);
        _mint(msg.sender, _toStake);
        emit Stake(msg.sender, _toStake, block.timestamp);
    }
}