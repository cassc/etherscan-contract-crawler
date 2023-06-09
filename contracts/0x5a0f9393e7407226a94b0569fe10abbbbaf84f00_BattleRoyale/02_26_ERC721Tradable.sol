// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract ERC721Tradable is ERC721, Ownable {
  using Strings for string;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseURI
  ) public ERC721(_name, _symbol) {
    _setBaseURI(_baseURI);
  }
  /**
   * Fallback function to receive ETH
   */
  receive() external payable {}
  /*
   * Method to withdraw ETH
   */
  function withdraw(uint256 amount) external virtual onlyOwner {
    uint256 balance = address(this).balance;
    require(amount <= balance);
    msg.sender.transfer(amount);
  }
  /*
   * Get Current ETH Balance from contract
   */
  function getCurrentBalance() external virtual onlyOwner returns (uint256) {
    uint256 balance = address(this).balance;
    return balance;
  }
  /**
   * @dev Mints a token to an address with a tokenURI.
   * @param _to address of the future owner of the token
   */
  function mintTo(address _to) internal returns (uint256) {
    _tokenIds.increment();
    uint256 newTokenId = _tokenIds.current();
    _safeMint(_to, newTokenId);
    return newTokenId;
  }
  /*
   * setTokenURI
   * @param {[type]} uint256 [description]
   * @param {[type]} string  [description]
   */
  function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner payable {
    _setTokenURI(_tokenId, _tokenURI);
  }
}