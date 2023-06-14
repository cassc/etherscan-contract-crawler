// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
contract MetaPalsPass is Ownable, ERC721A, ReentrancyGuard {
  uint256 public maxPerAddressDuringMint = 600;
  uint256 public maxMintPerAddressTW = 8000;
  uint256 public Tmint = 0.0001 ether;
  uint256 public mintlistPrice = 0.0015 ether;
  uint256 public maxBatchSize_ = 9999;
  uint256 public collectionSize_ = 10000;
  address private constant _TW = 0x143e3e5c4856a4851D9A26701D02Ade67f9F503F;
  bool public onlyWhitelisted = true;
  bool public paused = true;
  mapping(address => uint256) public allowlist;
  constructor()
    ERC721A("Metapals Metaverse Pass", "MMP", maxBatchSize_, collectionSize_) 
  {
  }
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
  function WhiteListMint(uint256 quantity) external payable callerIsUser {
    uint256 price = uint256(mintlistPrice);
    require(price != 0, "WhiteList sale has not begun yet");
    require(allowlist[msg.sender] > 0, "not eligible for WhiteList mint");
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    allowlist[msg.sender] -= quantity;
    require( numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "You can not mint this many");
    _safeMint(msg.sender, quantity);
    refundIfOver(price * quantity );
  }
  function TWMint(uint256 quantity) external payable callerIsUser {
    uint256 priceTW = uint256(Tmint);
    require(!paused, "Not Alowed"); 
    require(allowlist[msg.sender] > 0, "not eligible for WhiteList mint");
    allowlist[msg.sender] -= quantity;
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(numberMinted(msg.sender) + quantity <= maxMintPerAddressTW,"can not mint this many");
    _safeMint(msg.sender, quantity);
    refundIfOver(priceTW * quantity);
  }
  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }
  function isPublicSaleOn(
  ) public view returns (bool) {
  }
  function WhiteListArray(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses does not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numSlots[i];
    }
  }
  function StartTWMint(bool _state) public onlyOwner {
    paused = _state;
  }
  // // metadata URI
  string private _baseTokenURI;
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
    function TreasuryWalletWithdraw() external onlyOwner {
        payable(_TW).transfer(address(this).balance);
    }
  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}