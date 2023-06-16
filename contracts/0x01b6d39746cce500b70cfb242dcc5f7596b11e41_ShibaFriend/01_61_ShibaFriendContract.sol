// contracts/TestERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ShibaFriend is ERC20, AccessControl, ReentrancyGuard {
    uint8 private _decimals = 9;

    using EnumerableSet for EnumerableSet.AddressSet;

    bool private _isAllowWalletTransfer;

    EnumerableSet.AddressSet private _blacklisted;

    EnumerableSet.AddressSet private _allowedSend;

    EnumerableSet.AddressSet private _allowedReceive;

    constructor(uint256 initialSupply) ERC20("SHIBAFRIEND NFT", "SFT") ReentrancyGuard() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _mint(msg.sender, initialSupply  * 10**_decimals);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
    */
    function _transfer(address from, address to, uint256 amount)
        internal
        nonReentrant
        override
    {
        // sender and receiver must not be in blacklisted.
        require(!isBlacklisted(from) && !isBlacklisted(to), "ShibaFriend: sender or receiver is blacklisted");

        // when wallet transfer is disable, sender or receiver must be in allowed contract list.
        if(!_isAllowWalletTransfer) {
            require(isAllowSend(from) || isAllowReceive(to), "ShibaFriend: sender or receiver not allowed");
        }

        super._transfer(from, to, amount);
    }

    /*
        Additional functions
    */
    function isAllowWalletTransfer()
        external
        view
        returns(bool)
    {
        return _isAllowWalletTransfer;
    }

    function isBlacklisted(address _account)
        public
        view
        returns(bool)
    {
        return _blacklisted.contains(_account);
    }

    function isAllowSend(address _account)
        public
        view
        returns(bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, _account) ||
                _allowedSend.contains(_account);
    }

    function isAllowReceive(address _account)
        public
        view
        returns(bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, _account) ||
                _allowedReceive.contains(_account);
    }

    // Admin's functions

    function allowWalletTransfer()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _isAllowWalletTransfer = true;
    }

    function unAllowWalletTransfer()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _isAllowWalletTransfer = false;
    }

    function blacklistAddress(address _account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if(!_blacklisted.contains(_account)) {
            _blacklisted.add(_account);
        }
    }

    function unBlacklistAddress(address _account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if(_blacklisted.contains(_account)) {
            _blacklisted.remove(_account);
        }
    }

    function allowSendAddress(address _account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if(!_allowedSend.contains(_account)) {
            _allowedSend.add(_account);
        }
    }

    function unAllowSendAddress(address _account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if(_allowedSend.contains(_account)) {
            _allowedSend.remove(_account);
        }
    }

    function allowReceiveAddress(address _account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if(!_allowedReceive.contains(_account)) {
            _allowedReceive.add(_account);
        }
    }

    function unAllowReceiveAddress(address _account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if(_allowedReceive.contains(_account)) {
            _allowedReceive.remove(_account);
        }
    }

    // statistic functions
    function getBlackListedAddress()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(address[] memory)
    {
        address[] memory wallets = new address[](_blacklisted.length());
        for(uint i = 0; i < _blacklisted.length(); i++) {
            wallets[i] = _blacklisted.at(i);
        }
        return wallets;
    }

    function getAllowedSendAddress()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(address[] memory)
    {
        address[] memory wallets = new address[](_allowedSend.length());
        for(uint i = 0; i < _allowedSend.length(); i++) {
            wallets[i] = _allowedSend.at(i);
        }
        return wallets;
    }

    function getAllowedReceiveAddress()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(address[] memory)
    {
        address[] memory wallets = new address[](_allowedReceive.length());
        for(uint i = 0; i < _allowedReceive.length(); i++) {
            wallets[i] = _allowedReceive.at(i);
        }
        return wallets;
    }
}