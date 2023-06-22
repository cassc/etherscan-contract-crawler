// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RichBears is ERC721A, Ownable {

  using Strings for uint256;
  string public        baseURI;
  uint256 public       price             = 0.02 ether;
  uint256 public       totalFree         = 1000;
  uint256 public       maxSupply         = 10000;
  uint256 public       maxPerWallet      = 5;
  bool public          mintEnabled       = false;
  bool public revealed = false;

  mapping(address => uint256) private _walletMints;

  address public constant w1 = 0x897E4e5303F6634515daEbdda948bd841705CCA2;
  address public constant w2 = 0xbBaE93a5109357674cf749B6f294AD47C12BACbE;
  address public constant w3 = 0x15B6214f182841226B9991Cd88873dEFE616Da11;
  address public constant w4 = 0x810Fff32ce88E660C0a5eAD643E829EC0a59228b;

  constructor() ERC721A("Rich Bears", "RICH"){}

  function mint(uint256 amt) external payable
  {
    uint cost = price;
    if(totalSupply() + amt < totalFree + 1) {
      cost = 0;
      require(_walletMints[_msgSender()] + amt <= maxPerWallet, "Free limit for this wallet reached");
      require(msg.sender == tx.origin,"No bots, only bears!");
    }
    require(msg.value >= amt * cost,"Please send the right amount.");
    require(totalSupply() + amt < maxSupply + 1, "Not enough bears left.");
    require(mintEnabled, "Minting is not live yet.");

    _walletMints[_msgSender()] += amt;
    _safeMint(msg.sender, amt);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

        if (!revealed) {
            return "https://www.richbearsnft.com/prereveal.json";
        }

	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
  }

  function toggleMinting() external onlyOwner {
      mintEnabled = !mintEnabled;
  }

  function reveal(bool _state) public onlyOwner {
      revealed = _state;
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function setPrice(uint256 price_) external onlyOwner {
      price = price_;
  }

  function setTotalFree(uint256 totalFree_) external onlyOwner {
      totalFree = totalFree_;
  }

  function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
      maxPerWallet = maxPerWallet_;
  }

  function setmaxSupply(uint256 maxSupply_) external onlyOwner {
      maxSupply = maxSupply_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function withdrawAll() public onlyOwner {
      uint256 balance = address(this).balance;
      require(balance > 0, "Insufficent balance");
      _withdraw(w1, ((balance * 25) / 200));
      _withdraw(w2, ((balance * 17) / 200));
      _withdraw(w3, ((balance * 25) / 200));
      _withdraw(w4, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Failed to withdraw Ether");
  }

}