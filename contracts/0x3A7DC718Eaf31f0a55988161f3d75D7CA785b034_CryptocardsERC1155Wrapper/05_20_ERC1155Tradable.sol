// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
abstract contract ERC1155Tradable is ContextMixin, ERC1155, NativeMetaTransaction, Ownable {
  using Strings for string;
  using SafeMath for uint256;

  address public proxyRegistryAddress;
  mapping (uint256 => string) public customUri;
  
  // Contract name
  string public name;
  // Contract symbol
  string public symbol;

  function _initialize() virtual internal {}

  constructor(
    string memory _uri,
    address _proxyRegistryAddress
  ) ERC1155(_uri) {
    proxyRegistryAddress = _proxyRegistryAddress;
    _initializeEIP712(name);
    _initialize();
  }

  function uri(
    uint256 _id
  ) override public view returns (string memory) {
    // We have to convert string to bytes to check for existence
    bytes memory customUriBytes = bytes(customUri[_id]);
    if (customUriBytes.length > 0) {
        return customUri[_id];
    } else {
        return super.uri(_id);
    }
  }

  /**
   * @dev Sets a new URI for all token types, by relying on the token type ID
    * substitution mechanism
    * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   * @param _newURI New URI for all tokens
   */
  function setURI(
    string memory _newURI
  ) public onlyOwner {
    _setURI(_newURI);
  }

  /**
   * @dev Will update the base URI for the token
   * @param _tokenId The token to update. _msgSender() must be its creator.
   * @param _newURI New URI for the token.
   */
  function setCustomURI(
    uint256 _tokenId,
    string memory _newURI
  ) public onlyOwner {
    customUri[_tokenId] = _newURI;
    emit URI(_newURI, _tokenId);
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  ) override public view returns (bool isOperator) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  /**
    * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
    */
  function _msgSender()
      internal
      override
      view
      returns (address sender)
  {
      return ContextMixin.msgSender();
  }
}