// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "ERC1155.sol";
import "SafeMath.sol";
import "Strings.sol";

import "NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/** 
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists() , name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is
    ERC1155,
    NativeMetaTransaction,
    Ownable
{
    using Strings for string;
    using SafeMath for uint256;

    address proxyRegistryAddress;
    mapping(uint256 => string) internal customUri;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _proxyRegistryAddress
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
        proxyRegistryAddress = _proxyRegistryAddress;
        // _initializeEIP712(name);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     * @param _newURI New URI for all tokens
     */
    function setURI(string memory _newURI) public onlyOwner {
        _setURI(_newURI);
    }

    /**
     * @dev Will update the base URI for the token
     * @param _tokenId The token to update. _msgSender() must be its creator.
     * @param _newURI New URI for the token.
     */
    function setCustomURI(uint256 _tokenId, string memory _newURI)
        public
        onlyOwner
    {
        customUri[_tokenId] = _newURI;
        emit URI(_newURI, _tokenId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }
}