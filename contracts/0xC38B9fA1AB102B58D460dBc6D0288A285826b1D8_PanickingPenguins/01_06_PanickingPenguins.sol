// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PanickingPenguins is ERC721A, Ownable {

  using Strings for uint256;
  string public           baseURI;
  uint256 public          price             = 0.0025 ether;
  uint256 public          maxPerWallet      = 50;
  uint256 public constant maxSupply         = 10000;
  bool public             mintEnabled       = false;

  mapping(address => uint256) private _walletMints;
  mapping(address => uint256) private _freeMints;

  constructor() ERC721A("Panicking Penguins", "PP"){
  }

  function mint(uint256 tokens) external payable {
    require(mintEnabled, "Not minting yet!");
    require(tokens > 0, "Mint at least 1!");
    require(totalSupply() + tokens <= maxSupply, "All gone!");
    require(_walletMints[_msgSender()] + tokens <= maxPerWallet, "Greedy!");
    uint256 paidTokens = tokens;
    if (tokens > 1 && _freeMints[_msgSender()] < 1) {
      paidTokens = tokens - 1;
      _freeMints[_msgSender()] += 1;
    }
    require(price * paidTokens <= msg.value, "Pay up!");

    _walletMints[_msgSender()] += tokens;
    _safeMint(msg.sender, tokens);
  }

  function ownerMint(uint256 tokens, address to) external onlyOwner {
    require(totalSupply() + tokens <= maxSupply, "All gone!");

    _safeMint(to, tokens);
  }

  function setMaxPerWallet(uint256 _newMaxPerWallet) external onlyOwner {
    maxPerWallet = _newMaxPerWallet;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
  }

  function toggleMinting() external onlyOwner {
      mintEnabled = !mintEnabled;
  }

  function setPrice(uint256 price_) external onlyOwner {
      price = price_;
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function freeMinted(address wallet) external view returns (uint256) {
    return _freeMints[wallet];
  }

  function withdrawAll() public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "Insufficent balance");
    _withdraw(_msgSender(), address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Failed to withdraw Ether");
  }

}