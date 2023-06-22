// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

// ███    ██ ██    ██ ████████ ███████ 
// ████   ██ ██    ██    ██    ██      
// ██ ██  ██ ██    ██    ██    ███████ 
// ██  ██ ██ ██    ██    ██         ██ 
// ██   ████  ██████     ██    ███████

contract Nuts is Ownable, ERC721A {
  using Strings for uint256;

  string public baseUri;
  bool public saleOn;
  bool public revealed;

  uint256 public MAX_MINT_SUPPLY = 2000;
  uint256 public NFT_PRICE = 0.01 ether;

  constructor(
  ) ERC721A("Nuts", "Nuts") Ownable() {
    baseUri = "https://ipfs.io/ipfs/bafybeihkqdht5lnnlniuhzbggiwrblqxrrf6tlmrih7ywnbwr6lyyr54su/unrevealed.json";
  }

  function mint(uint256 amount) external payable {
    require(saleOn, "Sale off");
    require(amount > 0, "Invalid amount");
    require((NFT_PRICE * amount) <= msg.value, "Invalid ETH amount");
    require(totalSupply() + amount <= MAX_MINT_SUPPLY, "Maximum supply exceeded");
    _mint(msg.sender, amount);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if (revealed) {
      return string(abi.encodePacked(
        baseUri,
        tokenId.toString(),
        ".json"
      ));
    } else {
      return baseUri;
    }
  }

  function nextTokenId() public view returns (uint256) {
    return _nextTokenId();
  }

  function setBaseUri(string memory _baseUri) external onlyOwner {
    baseUri = _baseUri;
  }

  function setSaleOn(bool _saleOn) external onlyOwner {
    saleOn = _saleOn;
  }

  function setRevealed(bool _revealed) external onlyOwner {
    revealed = _revealed;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No balance to withdraw");
    payable(msg.sender).transfer(balance);
  }

  function setMaxMintSupply(uint256 _maxMintSupply) external onlyOwner {
    MAX_MINT_SUPPLY = _maxMintSupply;
  }

  function setNftPrice(uint256 _nftPrice) external onlyOwner {
    NFT_PRICE = _nftPrice;
  }

  function _startTokenId() internal view override returns (uint256) {
    return 1;
  }
}