// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachineportal
// https://twitter.com/erc_arcade

import "./FeeToken.sol";

contract sSMC is FeeToken {
    event Stake(address indexed _account, uint256 indexed _amount, uint256 indexed _timestamp);
    event Unstake(address indexed _account, uint256 indexed _amount, uint256 indexed _timestamp);

    constructor (address _USDT, address _SMC) FeeToken(_USDT, _SMC, "Staked SMC", "sSMC", 0) {}

    function stake(uint256 _toStake) external nonReentrant {
        if (_toStake > underlyingToken.balanceOf(msg.sender)) {
            revert InsufficientSMCBalance(_toStake, underlyingToken.balanceOf(msg.sender));
        }
        if (_toStake > underlyingToken.allowance(msg.sender, address(this))) {
            revert InsufficientSMCAllowance(_toStake, underlyingToken.allowance(msg.sender, address(this)));
        }
        underlyingToken.transferFrom(msg.sender, address(this), _toStake);
        _mint(msg.sender, _toStake);
        emit Stake(msg.sender, _toStake, block.timestamp);
    }

    function unstake(uint256 _toUnstake) external nonReentrant {
        if (_toUnstake > _balances[msg.sender]) {
            revert InsufficientsSMCBalance(_toUnstake, _balances[msg.sender]);
        }
        if (_toUnstake > _allowances[msg.sender][address(this)]) {
            revert InsufficientsSMCAllowance(_toUnstake, _allowances[msg.sender][address(this)]);
        }
        // ! _transferFrom(msg.sender, address(this), _toUnstake);
        _burn(msg.sender, _toUnstake);
        underlyingToken.transfer(msg.sender, _toUnstake);
        emit Unstake(msg.sender, _toUnstake, block.timestamp);
    }
}