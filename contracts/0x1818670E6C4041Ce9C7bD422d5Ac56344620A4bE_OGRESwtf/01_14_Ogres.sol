// SPDX-License-Identifier: MIT


//  ___    ____  ____     ___  _____    __    __  ______  _____ 
// /   \  /    ||    \   /  _]/ ___/   |  |__|  ||      ||     |
//|     ||   __||  D  ) /  [_(   \_    |  |  |  ||      ||   __|
//|  O  ||  |  ||    / |    _]\__  |   |  |  |  ||_|  |_||  |_  
//|     ||  |_ ||    \ |   [_ /  \ | __|  `  '  |  |  |  |   _] 
//|     ||     ||  .  \|     |\    ||  |\      /   |  |  |  |   
// \___/ |___,_||__|\_||_____| \___||__| \_/\_/    |__|  |__|   
                                                           

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract OGRESwtf is ERC721, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  string _baseUri;
  string _contractUri;

  bool public isSalesActive;
  uint public maxSupply;
  uint public maxTx;
  uint public maxPerWallet;

  constructor() ERC721("ogres.wtf", "OGRWTF") {
    _contractUri = "ipfs://QmbMnDV7fa1hpozsPGX8cfMAFDJbk4dtySpaSUdRVS8Jv9";
    maxSupply = 5000;
    maxTx = 3;
    maxPerWallet = 3;
    isSalesActive = true;
  }

  function mint(uint quantity) external {
    require(isSalesActive, "sale is not active");
    require(totalSupply() + quantity <= maxSupply, "sold out");
    require(quantity <= maxTx, "quantity exceeds max mints per tx");
    require(balanceOf(msg.sender) < maxPerWallet, "quantity exceeds max mints per wallet");

    for (uint i = 0; i < quantity; i++) {
      safeMint(msg.sender);
    }
  }

  function safeMint(address to) internal {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
  }

  function totalSupply() public view returns (uint) {
    return _tokenIdCounter.current();
  }

  function setIsSaleActive(bool isSalesActive_) external onlyOwner {
    isSalesActive = isSalesActive_;
  }

  function contractURI() public view returns (string memory) {
    return _contractUri;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    _baseUri = newBaseURI;
  }

  function setContractURI(string memory newContractURI) external onlyOwner {
    _contractUri = newContractURI;
  }

  function setMaxSupply(uint newSupply) external onlyOwner {
    maxSupply = newSupply;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseUri;
  }

  function withdraw(uint amount) external onlyOwner {
    require(payable(msg.sender).send(amount));
  }

  function withdrawAll() external onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}