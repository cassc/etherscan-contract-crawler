// SPDX-License-Identifier: None
// twitter: @FIFAcom

pragma solidity ^0.8.4;

import "./libs/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**********************************************
 * 2022 world cup
 * Get you first fifa digital trading card here
 **********************************************/

contract FIFA is ERC721A, IERC2981, Ownable {
  using Strings for uint256;
  uint256 constant MINT_PRICE = 0.01 ether;
  uint256 constant MAX_SUPPLY = 2022;
  uint256 constant MAX_PER_TRANSACTION = 10;

  bool public paused = true;

  string tokenBaseUri;

  constructor() ERC721A("FIFA Trading Cards", "FIFA") {
  }

  function mint(uint256 _quantity) external payable {
    require(!paused, "minting is paused");

    uint256 _totalSupply = totalSupply();

    require(_totalSupply + _quantity <= MAX_SUPPLY, "max supply exceeded");
    require(_quantity <= MAX_PER_TRANSACTION, "max per tx exceed");
    require(msg.value >= _quantity * MINT_PRICE, "0.01 ether for each banana");

    _safeMint(msg.sender, _quantity);
  }


  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function setBaseURI(string calldata _newBaseUri) external onlyOwner {
    tokenBaseUri = _newBaseUri;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
  }

  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function ownerMint() external onlyOwner {
    require(totalSupply() == 0, "already minted");

    _safeMint(msg.sender, 10);
  }

  function withdraw() external onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "withdraw ether"
    );
  }
  
  function royaltyInfo(uint256 , uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount){
        // calculate the amount of royalties
        uint256 _royaltyAmount = salePrice / 10; // 10%
        // return the amount of royalties and the recipient collection address
        return (owner(), _royaltyAmount);
  }
}