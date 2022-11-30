// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./Epoch.sol";

contract MiningToken is Epoch {
    bool public miningStarted;

    mapping(address => uint256) private _balances;
    mapping(address => bool) internal _mintExclude;

    uint256 private _initialSupply;
    uint256 private _totalSupplyEpoch;
    uint256 private _totalSupplyBlock;

    function initialSupply() public view returns (uint256) {
        return _initialSupply;
    }

    function totalSupply() public view virtual returns (uint256) {
        if (!miningStarted) return _initialSupply;

        uint256 _currentEpoch = currentEpoch();

        uint256 amount = _totalSupplyEpoch;
        for (uint256 i = lastEpoch; i < _currentEpoch; i++) {
            amount += amount * getMultiplyByEpoch(i) / MULTIPLY;
        }

        uint256 epochTotal = amount * getMultiplyByEpoch(_currentEpoch) / MULTIPLY;
        return amount + epochTotal * (block.number - currentEpochBlock()) / EPOCH_PERIOD;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        if (!miningStarted) return _balances[account];

        if (_mintExclude[account]) return _balances[account];

        return _balances[account] * totalSupply() / _initialSupply;
    }

    function _mint(address account, uint256 amount) internal virtual {
        _initialSupply += amount;
        _totalSupplyEpoch += amount;
        _totalSupplyBlock += amount;
        _balances[account] += amount;
    }

    function _tokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        uint256 initialAmount = amount * _initialSupply / _totalSupplyBlock;

        if (_mintExclude[from]) {
            require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
            _balances[from] -= amount;
        } else {
            require(_balances[from] >= initialAmount, "ERC20: transfer amount exceeds balance");
            _balances[from] -= initialAmount;
        }

        if (_mintExclude[to]) {
            _balances[to] += amount;
        } else {
            _balances[to] += initialAmount;
        }
    }

    function updateMining() internal {
        uint256 _currentEpoch = currentEpoch();

        uint256 amount = _totalSupplyEpoch;
        for (uint256 i = lastEpoch; i < _currentEpoch; i++) {
            amount += amount * getMultiplyByEpoch(i) / MULTIPLY;
        }

        _totalSupplyEpoch = amount;

        uint256 epochTotal = amount * getMultiplyByEpoch(_currentEpoch) / MULTIPLY;
        amount += epochTotal * (block.number - currentEpochBlock()) / EPOCH_PERIOD;

        _totalSupplyBlock = amount;

        updateEpoch();
    }
}