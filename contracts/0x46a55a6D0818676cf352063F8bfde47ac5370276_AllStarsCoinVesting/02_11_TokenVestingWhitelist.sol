// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "./TokenVesting.sol";

contract TokenVestingWhitelist is TokenVesting {
    event Approval(uint256 indexed roundId, address indexed account, uint256 value);

    mapping(uint256 => mapping(address => uint256)) private _allowances;

    constructor(address token_) TokenVesting(token_) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function allowance(uint256 roundId, address account) public view returns (uint256) {
        return _allowances[roundId][account];
    }

    function _increaseAllowance(
        uint256 roundId,
        address account,
        uint256 addedValue
    ) internal {
        _approve(roundId, account, allowance(roundId, account) + addedValue);
    }

    function _decreaseAllowance(
        uint256 roundId,
        address account,
        uint256 subtractedValue
    ) internal {
        uint256 currentAllowance = allowance(roundId, account);
        require(currentAllowance >= subtractedValue, "TokenVestingWhitelist: decreased allowance below zero");

        unchecked {
            _approve(roundId, account, currentAllowance - subtractedValue);
        }
    }

    function _spendAllowance(
        uint256 roundId,
        address account,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(roundId, account);

        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "TokenVestingWhitelist: insufficient allowance");

            unchecked {
                _approve(roundId, account, currentAllowance - amount);
            }
        }
    }

    function _approve(
        uint256 roundId,
        address account,
        uint256 amount
    ) internal {
        require(account != address(0), "TokenVestingWhitelist: approve to the zero address");

        _checkIfRoundExists(roundId);
        _allowances[roundId][account] = amount;

        emit Approval(roundId, account, amount);
    }
}