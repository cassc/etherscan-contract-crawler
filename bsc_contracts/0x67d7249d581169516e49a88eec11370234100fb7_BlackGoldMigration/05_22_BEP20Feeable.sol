// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./BEP20.sol";

abstract contract BEP20Feeable is BEP20 {
    mapping(address => bool) internal _isExcludedFromIncomingFee;
    mapping(address => bool) internal _isExcludedFromOutgoingFee;

    event Fee(address indexed sender, uint256 amount);

    constructor(string memory name_, string memory symbol_)
        BEP20(name_, symbol_)
    {
        _isExcludedFromIncomingFee[owner()] = true;
        _isExcludedFromOutgoingFee[owner()] = true;
        _isExcludedFromIncomingFee[address(this)] = true;
        _isExcludedFromOutgoingFee[address(this)] = true;
        // we don't want to fee on burn or mint, so exclude them here
        _isExcludedFromIncomingFee[address(0)] = true;
        _isExcludedFromOutgoingFee[address(0)] = true;
    }

    /**
     * @dev Sets true value for `account` in `_isExcludedFromIncomingFee`
     */
    function excludeFromIncomingFee(address account) external onlyOwner {
        _isExcludedFromIncomingFee[account] = true;
    }

    /**
     * @dev Sets false value for `account` in `_isExcludedFromIncomingFee`
     */
    function includeInIncomingFee(address account) external onlyOwner {
        _isExcludedFromIncomingFee[account] = false;
    }

    /**
     * @dev Checks if `account` is excluded from incoming fees
     */
    function isExcludedFromIncomingFee(address account)
        external
        view
        returns (bool)
    {
        return _isExcludedFromIncomingFee[account];
    }

    /**
     * @dev Sets true value for `account` in `_isExcludedFromOutgoingFee`
     */
    function excludeFromOutgoingFee(address account) external onlyOwner {
        _isExcludedFromOutgoingFee[account] = true;
    }

    /**
     * @dev Sets false value for `account` in `_isExcludedFromOutgoingFee`
     */
    function includeInOutgoingFee(address account) external onlyOwner {
        _isExcludedFromOutgoingFee[account] = false;
    }

    /**
     * @dev Checks if `account` is excluded from outgoing fees
     */
    function isExcludedFromOutgoingFee(address account)
        external
        view
        returns (bool)
    {
        return _isExcludedFromOutgoingFee[account];
    }

    /**
     * @dev Checks if a fee should be taken from the transaction.
     */
    function _shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        return
            !_isExcludedFromIncomingFee[to] &&
            !_isExcludedFromOutgoingFee[from];
    }
}