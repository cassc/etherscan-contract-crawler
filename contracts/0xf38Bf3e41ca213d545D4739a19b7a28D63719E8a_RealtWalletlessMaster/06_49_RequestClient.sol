// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IERC20ConversionProxy.sol";
import "./interfaces/IRequestClient.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract RequestClient is IRequestClient, Initializable {
    address[] internal _tokenWhitelist;
    address[] internal _destinationWhitelist;
    address[] internal _feeAddressWhitelist;
    address internal _feeProxy;

    /**
     * @dev Initializes the contract
     */
    function __RequestClient_init(
        address[] memory tokenWhitelist_,
        address[] memory destinationWhitelist_,
        address[] memory feeAddressWhitelist_,
        address feeProxy_
    ) internal onlyInitializing {
        __RequestClient_init_unchained(
            tokenWhitelist_,
            destinationWhitelist_,
            feeAddressWhitelist_,
            feeProxy_
        );
    }

    function __RequestClient_init_unchained(
        address[] memory tokenWhitelist_,
        address[] memory destinationWhitelist_,
        address[] memory feeAddressWhitelist_,
        address feeProxy_
    ) internal onlyInitializing {
        _tokenWhitelist = tokenWhitelist_;
        _destinationWhitelist = destinationWhitelist_;
        _feeAddressWhitelist = feeAddressWhitelist_;
        _feeProxy = feeProxy_;
    }

    function setDestinationWhitelist(address[] memory destinationWhitelist_)
        external
        override
    {
        _authorizeRequestClient();
        emit DestinationWhitelistSet(
            _destinationWhitelist,
            destinationWhitelist_
        );
        _destinationWhitelist = destinationWhitelist_;
    }

    function destinationWhitelist()
        external
        view
        override
        returns (address[] memory)
    {
        return _destinationWhitelist;
    }

    function setTokenWhitelist(address[] memory tokenWhitelist_)
        external
        override
    {
        _authorizeRequestClient();
        emit TokenWhitelistSet(_tokenWhitelist, tokenWhitelist_);
        _tokenWhitelist = tokenWhitelist_;
    }

    function tokenWhitelist()
        external
        view
        override
        returns (address[] memory)
    {
        return _tokenWhitelist;
    }

    function setFeeProxy(address feeProxy_) external override {
        _authorizeRequestClient();
        emit SetFeeProxy(_feeProxy, feeProxy_);
        _feeProxy = feeProxy_;
    }

    function feeProxy() external view override returns (address) {
        return _feeProxy;
    }

    function setFeeAddressWhitelist(address[] memory feeAddressWhitelist_)
        external
        override
    {
        _authorizeRequestClient();
        emit FeeAddressWhitelistSet(_feeAddressWhitelist, feeAddressWhitelist_);
        _feeAddressWhitelist = feeAddressWhitelist_;
    }

    function feeAddressWhitelist()
        external
        view
        override
        returns (address[] memory)
    {
        return _feeAddressWhitelist;
    }

    // Implement this for auth function
    function _authorizeRequestClient() internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[6] private __gap;
}