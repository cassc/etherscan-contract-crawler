// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract BWPNFT is ERC721Tradable {
  string private _baseTokenURI;

  event PermanentURI(string _value, uint256 indexed _id);

  constructor(address _proxyRegistryAddress)
    ERC721Tradable("RFOX VALT", "VALT", _proxyRegistryAddress)
  {}

	/**
   * Set new base token uri
   *
   * @param _uri base token uri
  */
  function setBaseTokenURI(string memory _uri) external onlyOwner {
    _baseTokenURI = _uri;
  }

  /**
   * Return base token uri
   *
   * @return base token uri
  */
  function baseTokenURI() override public view returns (string memory) {
    return _baseTokenURI;
    // return "https://creatures-api.opensea.io/api/creature/";
  }

	/**
   * Return contract uri
   *
   * @return contract uri
  */
  function contractURI() external pure returns (string memory) {
    return "https://rfoxvalt.com";
  }

	/**
   * Freeze a token
   *
   * @param _value string of metadata of a token
	 * @param _id token id to freeze
  */
  function freeze(string memory _value, uint256 _id) external {
    require(ownerOf(_id) == msg.sender, 'BWPNFT: INSUFFICIENT PERMISSION');
    emit PermanentURI(_value, _id);
  }
}