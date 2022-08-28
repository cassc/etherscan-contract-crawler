// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ShibaNFT is Ownable, ERC721 {
  uint public currentLeft;
  uint public totalLeft;
  uint public reserved;
  uint public price;

  uint public tokenIds;
  bool public pause;

  string private _URI;
  address private _beneficiary;

  constructor(string memory name_, string memory symbol_, string memory uri_, uint left_, uint totalLeft_, uint reserved_, uint price_, address beneficiary_) ERC721(name_, symbol_) {
    currentLeft = left_;
    totalLeft = totalLeft_;
    reserved = reserved_;
    price = price_;
    pause = true;
    _beneficiary = beneficiary_;

    _URI = uri_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _URI;
  }

  function setBaseURI(string calldata uri) external onlyOwner {
    _URI = uri;
  }

  event SetPrice(uint);

  function setPrice(uint price_) external onlyOwner {
    emit SetPrice(price_);
    price = price_;
  }

  function setPause(bool pause_) external onlyOwner {
    pause = pause_;
  }

  function resetSupply(uint supply) external onlyOwner {
    require(currentLeft == 0, "failed");
    require(supply <= totalLeft, "failed");
    currentLeft = supply;
    totalLeft -= supply;
  }

  // DO NOT CALL FROM SMART CONTRACT!!
  function tokensOf(address account) external view returns (uint[] memory) {
    uint tokenCount = balanceOf(account);
    if (tokenCount == 0) return new uint[](0);

    uint[] memory result = new uint[](tokenCount);
    uint ri = 0;
    for (uint i = 1; i <= tokenIds; ++i) {
      if (ownerOf(i) == account) {
        result[ri] = i;
        ri++;
      }
    }
    return result;
  }

  function contractURI() external pure returns (string memory) {
    return "";
  }

  function mint(address account) external payable {
    require(msg.value >= price, "bad price");
    require(!pause, "pause");
    _mint(account);
  }

  function bulkMint(address account, uint count) external payable {
    require(msg.value >= price * count, "bad price");
    require(!pause, "pause");
    for (uint i = 0; i < count; ++i)
      _mint(account);
  }

  function ownerMint(address account) external onlyOwner {
    _ownerMint(account);
  }

  function ownerBulkMint(address[] calldata account) external onlyOwner {
    for (uint i = 0; i < account.length; ++i)
      _ownerMint(account[i]);
  }

  event TransferValue(uint);

  function transferValue() external {
    emit TransferValue(address(this).balance);
    _sendValue(payable(_beneficiary), address(this).balance);
  }

  function _ownerMint(address account) internal {
    require(reserved > 0, "no reserved");
    reserved--;
    _mint(account);
  }

  function _mint(address account) internal {
    require(currentLeft > 0, "no supply");
    currentLeft--;
    tokenIds++;
    _safeMint(account, tokenIds);
  }

  function _sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "unable to send value");
  }
}