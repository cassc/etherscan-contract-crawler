// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract SaffronBTC22 is ERC1155, Ownable {
  using Address for address;

  string public name = "Saffron Finance @ Bitcoin 2022 Miami";
  uint256 constant BTC22_ID = 1;
  string constant BTC22_URI = "https://app.spice.finance/assets/metadata/btc22/1";

  constructor () ERC1155(BTC22_URI) {
  }

  function mintSingle(address to) external onlyOwner {
    if (!to.isContract()) {
      _mint(to, BTC22_ID, 1, "");
    }
  }

  function mintMany(address[] calldata to) external onlyOwner {
    for (uint256 i = 0; i < to.length; ++i) {
      address t = to[i];
      if (!t.isContract()) {
        _mint(t, BTC22_ID, 1, "");
      }
    }
  }

  function setUri(string memory uri_) external onlyOwner {
    _setURI(uri_);
  }
}