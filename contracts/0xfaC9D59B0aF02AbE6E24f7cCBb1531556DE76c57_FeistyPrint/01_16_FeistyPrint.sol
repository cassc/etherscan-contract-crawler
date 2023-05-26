// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FeistyPrint is ERC721Enumerable, Ownable {
  using SafeERC20 for IERC20;
  using Counters for Counters.Counter;

  event Printed(address sender, uint256 tokenId, uint256 price);
  event Redeemed(address sender, uint256 tokenId, uint256 price);
  event PriceUpdated(uint256 oldPrice, uint256 newPrice);

  IERC20 private immutable _token;
  mapping(uint256 => uint256) _tokenPrices;

  uint256 private _price;
  Counters.Counter private _mints;

  string _tokenURI;
  string _contractURI;

  constructor(IERC20 token_, uint256 price_) ERC721("Feisty Doge Print", "FDP") {
    _token = token_;
    _price = price_;

    _tokenURI = "ipfs://QmNUUqGtwKg4TzVp4cAXE6aeBprxPFcoKNvTFFi58dnZva";
    _contractURI = "ipfs://QmQfkV8NEzoLYn3LDUbJuTXFUcRHrsPVTcy9ZTVmEMmnMj";
  }

  // -- Admin -- //
  function setPrice(uint256 price_) external onlyOwner {
    emit PriceUpdated(_price, price_);

    _price = price_;
  }

  function setTokenURI(string memory tokenURI_) external onlyOwner {
    _tokenURI = tokenURI_;
  }

  function setContractURI(string memory contractURI_) external onlyOwner {
    _contractURI = contractURI_;
  }
  // -- Admin -- //

  // -- Accessors -- //
  function token() external view returns (IERC20) {
    return _token;
  }

  function price() external view returns (uint256) {
    return _price;
  }

  function mints() external view returns (uint256) {
    return _mints.current();
  }

  function tokenURI(uint256) public view virtual override returns (string memory) {
    return _tokenURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }
  // -- Accessors -- //

  // -- Functions -- //
  function print() external {
    printMultiple(1);
  }

  function printMultiple(uint256 count) public {
    require(count <= 10, "FeistyPrint: max 10 prints");

    require(_token.transferFrom(_msgSender(), address(this), _price * count));

    for (uint i = 0; i < count; i++) {
      uint256 tokenId = _mints.current();

      emit Printed(_msgSender(), tokenId, _price);
      _tokenPrices[tokenId] = _price;

      _safeMint(_msgSender(), tokenId);
      _mints.increment();
    }
  }

  function redeem() external {
    redeemMultiple(1);
  }

  function redeem(uint256 tokenId) public {
    require(ownerOf(tokenId) == _msgSender(), "FeistyPrint: sender does not own token");

    uint256 tokenPrice = _tokenPrices[tokenId];
    emit Redeemed(_msgSender(), tokenId, tokenPrice);

    _burn(tokenId);
    require(_token.transfer(_msgSender(), tokenPrice));
  }

  function redeemMultiple(uint256 count) public {
    uint256 tokenCount = balanceOf(_msgSender());

    require(count <= 10, "FeistyPrint: max 10 prints");
    require(count <= tokenCount, "FeistyPrint: sender doesn't have enough prints");

    for (uint i = 1; i <= count; i++) {
      uint256 tokenToRedeem = tokenOfOwnerByIndex(_msgSender(), tokenCount - i);
      redeem(tokenToRedeem);
    }
  }
  // -- Functions -- //
}