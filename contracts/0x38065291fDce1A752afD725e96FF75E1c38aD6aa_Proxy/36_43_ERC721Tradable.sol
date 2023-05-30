// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ContextMixin.sol";
import "./NativeMetaTransaction.sol";



contract OwnableDelegateProxy {}

contract ProxyRegistry 
{
    mapping(address => OwnableDelegateProxy) public proxies;
}


contract ERC721Tradable is ERC721, ContextMixin, NativeMetaTransaction
{
    address _proxyRegistry;

    constructor(string memory name, string memory symbol, address proxyRegistry) 
        ERC721(name, symbol) 
    {
        _proxyRegistry = proxyRegistry;
        _initializeEIP712(name);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        if (_proxyRegistry != address(0))
        {
            // Whitelist OpenSea proxy contract for easy trading.
            ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistry);
            if (address(proxyRegistry.proxies(owner)) == operator) 
            {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        virtual
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}