// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "./FeeToken.sol";

contract esSMC is FeeToken {
    error StillVesting(uint256 _currentDate, uint256 _unlockDate);

    mapping (address => uint256) public lastVestStart;
    mapping (address => uint256) public vestedTokens;

    event StartVest(address indexed _account, uint256 indexed _amount, uint256 indexed _timestamp);
    event EndVest(address indexed _account, uint256 indexed _amount, uint256 indexed _timestamp);

    uint256 public constant year = 31557600;

    constructor (address _USDT, address _SMC, uint256 _supply) FeeToken(_USDT, _SMC, "Escrowed SMC", "esSMC", _supply) {}

    function beginVest(uint256 _toVest) external nonReentrant {
        if (_toVest > _balances[msg.sender]) {
            revert InsufficientSMCBalance(_toVest, _balances[msg.sender]);
        }
        if (_toVest > _allowances[msg.sender][address(this)]) {
            revert InsufficientSMCAllowance(_toVest, _allowances[msg.sender][address(this)]);
        }
        _transferFrom(msg.sender, address(this), _toVest);
        lastVestStart[msg.sender] = block.timestamp;
        vestedTokens[msg.sender] += _toVest;
        emit StartVest(msg.sender, _toVest, block.timestamp);
    }

    function endVest() external nonReentrant {
        if (lastVestStart[msg.sender] + year > block.timestamp) {
            revert StillVesting(block.timestamp, lastVestStart[msg.sender] + year);
        }
        uint256 _toUnvest = vestedTokens[msg.sender];
        _burn(address(this), _toUnvest);
        underlyingToken.transfer(msg.sender, _toUnvest);
        emit EndVest(msg.sender, _toUnvest, block.timestamp);
    }
}