// SPDX-License-Identifier: MIT
// Creator: https://cojodi.com

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract AbstractWhitelist is Ownable {
  bool public isWhitelistSale = false;
  bool public isPublicSale = false;

  function toggleWhitelistSale() external onlyOwner {
    isWhitelistSale = !isWhitelistSale;
    if (isPublicSale) isPublicSale = false;
  }

  function togglePublicSale() external onlyOwner {
    isPublicSale = !isPublicSale;
    if (isWhitelistSale) isWhitelistSale = false;
  }

  modifier isPublic() {
    require(isPublicSale, "not public sale");
    _;
  }
}