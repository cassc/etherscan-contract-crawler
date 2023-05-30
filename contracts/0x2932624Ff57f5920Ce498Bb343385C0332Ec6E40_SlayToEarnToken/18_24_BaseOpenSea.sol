//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title OpenSea contract helper that defines a few things
/// @author Simon Fremaux (@dievardump)
/// @dev This is a contract used to add OpenSea's
///      gas-less trading and contractURI support
contract BaseOpenSea {
    string private _contractURI;
    address private _proxyRegistry;

    /// @notice Returns the current OS proxyRegistry address registered
    function proxyRegistry() public view returns (address) {
        return _proxyRegistry;
    }

    /// @notice Helper allowing OpenSea gas-less trading by verifying who's operator
    ///         for owner
    /// @dev Allows to check if `operator` is owner's OpenSea proxy on eth mainnet / rinkeby
    ///      or to check if operator is OpenSea's proxy contract on Polygon and Mumbai
    /// @param owner the owner we check for
    /// @param operator the operator (proxy) we check for
    function isOwnersOpenSeaProxy(address owner, address operator)
    public
    view
    returns (bool)
    {
        address proxyRegistry_ = _proxyRegistry;

        // if we have a proxy registry
        if (proxyRegistry_ != address(0)) {
            // on ethereum mainnet or rinkeby use "ProxyRegistry" to
            // get owner's proxy
            if (block.chainid == 1 || block.chainid == 4) {
                return
                address(ProxyRegistry(proxyRegistry_).proxies(owner)) ==
                operator;
            } else if (block.chainid == 137 || block.chainid == 80001) {
                // on Polygon and Mumbai just try with OpenSea's proxy contract
                // https://docs.opensea.io/docs/polygon-basic-integration
                return proxyRegistry_ == operator;
            }
        }

        return false;
    }

    /// @dev Internal function to set the _proxyRegistry
    /// @param proxyRegistryAddress the new proxy registry address
    function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
        _proxyRegistry = proxyRegistryAddress;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}