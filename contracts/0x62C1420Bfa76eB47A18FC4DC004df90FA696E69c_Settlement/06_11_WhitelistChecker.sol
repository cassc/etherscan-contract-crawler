// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../interfaces/IWhitelistRegistry.sol";

/// @title Contract with modifier for check does address in whitelist
contract WhitelistChecker {
    error AccessDenied();

    uint256 private constant _NOT_CHECKED = 1;
    uint256 private constant _CHECKED = 2;

    IWhitelistRegistry private immutable _whitelist;
    address private _limitOrderProtocol;
    uint256 private _checked = _NOT_CHECKED;

    constructor(IWhitelistRegistry whitelist, address limitOrderProtocol) {
        _whitelist = whitelist;
        _limitOrderProtocol = limitOrderProtocol;
    }

    modifier onlyWhitelistedEOA() {
        _enforceWhitelist(tx.origin); // solhint-disable-line avoid-tx-origin
        _;
    }

    modifier onlyWhitelisted(address account) {
        _enforceWhitelist(account);
        if (_checked == _NOT_CHECKED) {
            _checked = _CHECKED;
            _;
            _checked = _NOT_CHECKED;
        } else {
            _;
        }
    }

    modifier onlyLimitOrderProtocol() {
        if (msg.sender != _limitOrderProtocol) revert AccessDenied(); // solhint-disable-next-line avoid-tx-origin
        if (_checked == _NOT_CHECKED && !_whitelist.isWhitelisted(tx.origin)) revert AccessDenied();
        _;
    }

    function _enforceWhitelist(address account) private view {
        if (!_whitelist.isWhitelisted(account)) revert AccessDenied();
    }
}