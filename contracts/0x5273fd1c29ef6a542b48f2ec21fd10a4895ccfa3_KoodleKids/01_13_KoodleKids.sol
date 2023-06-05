// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *        __ __                ____         __ __ _     __    
 *       / //_/___  ____  ____/ / /__      / //_/(_)___/ /____
 *      / ,< / __ \/ __ \/ __  / / _ \    / ,<  / / __  / ___/
 *     / /| / /_/ / /_/ / /_/ / /  __(   / /| |/ / /_/ (__  ) 
 *    /_/ |_\____/\____/\__,_/_/\___//  /_/ |_/_/\__,_/____/  
 *
 *                     Koodle Kids | 2022  
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract KoodleKids is ERC721Enumerable, Ownable {
  using Address for address payable;

  uint256 public constant KID_PREMINT = 25;
  uint256 public constant KID_MAX = 8888;
  uint256 public constant KID_PRICE = 0.02 ether;

  string private _baseTokenURI;

  bool public saleLive;

  bool public locked;

  constructor(
    string memory newBaseTokenURI
  )
    ERC721("Koodle Kids", "KID")
  {
    _baseTokenURI = newBaseTokenURI;
    _preMint(KID_PREMINT);
  }

  /**
   * @dev Mints number of tokens specified to wallet.
   * @param quantity uint256 Number of tokens to be minted
   */
  function buy(uint256 quantity) external payable {
    require(saleLive, "KID: Sale is not currently live");
    require(totalSupply() + quantity <= KID_MAX, "KID: Quantity exceeds remaining tokens");
    require(quantity != 0, "KID: Cannot buy zero tokens");
    require(msg.value >= quantity * KID_PRICE, "KID: Insufficient funds");

    for (uint256 i=0; i<quantity; i++) {
      _safeMint(msg.sender, totalSupply()+1);
    }
  }

  /**
   * @dev Set base token URI.
   * @param newBaseURI string New URI to set
   */
  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    require(!locked, "KID: Contract metadata is locked");
    _baseTokenURI = newBaseURI;
  }

  /**
   * @dev Returns token URI of token with given tokenId.
   * @param tokenId uint256 Id of token
   * @return string Specific token URI
   */
  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "KID: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
  }

  /**
   * @dev Toggles status of token sale. Only callable by owner.
   */
  function toggleSale() external onlyOwner {
    saleLive = !saleLive;
  }

  /**
   * @dev Locks contract metadata. Only callable by owner.
   */
  function lockMetadata() external onlyOwner {
    locked = true;
  }

  /**
   * @dev Withdraw funds from contract. Only callable by owner.
   */
  function withdraw() public onlyOwner {
    payable(msg.sender).sendValue(address(this).balance);
  }

  /**
   * @dev Pre mint n tokens to owner address.
   * @param n uint256 Number of tokens to be minted
   */
  function _preMint(uint256 n) private {
    for (uint256 i=0; i<n; i++) {
      _safeMint(owner(), totalSupply()+1);
    }
  }
}