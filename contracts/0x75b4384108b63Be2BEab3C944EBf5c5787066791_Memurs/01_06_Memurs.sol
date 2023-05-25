// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Memurs is ERC721A, Ownable {

  using Strings for uint256;
  string public           baseURI;
  uint256 public constant maxSupply         = 4444;
  uint256 public          maxPerWallet      = 1;
  bool public             mintEnabled       = false;

  mapping(address => uint256) private _walletMints;

  constructor() ERC721A("Memurs", "MEMURS"){
  }

  function mint(uint256 amt) external payable {
    require(mintEnabled, "Minting is not live yet.");
    require(_walletMints[_msgSender()] + amt < maxPerWallet + 1, "That's enough Memurs for you!");
    require(msg.sender == tx.origin,"No bots, only true Memurs!");
    require(totalSupply() + amt < maxSupply + 1, "Not enough Memurs left.");

    _walletMints[_msgSender()] += amt;
    _safeMint(msg.sender, amt);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

	  string memory currentBaseURI = _baseURI();
	  return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
  }

  function toggleMinting() external onlyOwner {
      mintEnabled = !mintEnabled;
  }

  function numberMinted(address owner) public view returns (uint256) {
      return _numberMinted(owner);
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
      baseURI = baseURI_;
  }

  function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
      maxPerWallet = maxPerWallet_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

}