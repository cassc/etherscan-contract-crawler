// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EtherMan is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer{
  string  public  baseTokenURI = "ipfs://bafybeial6fciml27jifvzm2zmdmoy3jaljtgdqydhwbribp4wkx5eciajy";
  uint256 public  maxSupply = 3333;
  uint256 public  MAX_MINTS_PER_TX = 10;
  uint256 public  PUBLIC_SALE_PRICE = 0.003 ether;
  uint256 public  MAX_FREE_PER_WALLET = 1;

  constructor(
  ) ERC721A("EtherMan", "EM") {
      _safeMint(msg.sender, 100);
  }

  function mint(uint256 quantity)
      external
      payable
  {
    require(totalSupply() + quantity <= maxSupply, "OOS!");
    if (balanceOf(msg.sender) + quantity > MAX_FREE_PER_WALLET) {
        require((PUBLIC_SALE_PRICE * (quantity - ((balanceOf(msg.sender) > 0)? 0: 1))) <= msg.value, "Incorrect ETH value sent");
        require(quantity <= MAX_MINTS_PER_TX,"Max mints per transaction exceeded");
    } else {
        require(quantity <= MAX_FREE_PER_WALLET,"Max mints per transaction exceeded");
    }
    _safeMint(msg.sender, quantity);
  }

  function setBaseURI(string memory baseURI)
    public
    onlyOwner
  {
    baseTokenURI = baseURI;
  }

  function withdraw()
    public
    onlyOwner
    nonReentrant
  {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
  }

  function tokenURI(uint _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return string.concat(baseTokenURI, "/", Strings.toString(_tokenId), ".json");
  }

  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
  {
    return baseTokenURI;
  }

  function setSalePrice(uint256 _price)
      external
      onlyOwner
  {
      PUBLIC_SALE_PRICE = _price;
  }

  function setMaxLimitPerTransaction(uint256 _limit)
      external
      onlyOwner
  {
      MAX_MINTS_PER_TX = _limit;
  }

  function setFreeLimitPerWallet(uint256 _limit)
      external
      onlyOwner
  {
      MAX_FREE_PER_WALLET = _limit;
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }
  
  function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from){
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override payable onlyAllowedOperator(from){
      super.safeTransferFrom(from, to, tokenId, data);
  }
}