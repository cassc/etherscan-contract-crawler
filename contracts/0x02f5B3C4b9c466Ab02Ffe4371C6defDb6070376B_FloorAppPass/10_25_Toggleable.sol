// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

error SaleNotActive();
error WhitelistNotActive();

abstract contract Toggleable is Ownable {

  bool public saleIsActive = false;
  bool public whitelistIsActive = false;

    function flipWhitelistState() external onlyOwner {
    whitelistIsActive = !whitelistIsActive;
  }

  function flipSaleState() external onlyOwner {
    saleIsActive = !saleIsActive;
  }

  modifier requireActiveSale {
    if(!saleIsActive) revert SaleNotActive();
    _;
  }

  modifier requireActiveWhitelist {
    if(!whitelistIsActive) revert WhitelistNotActive();
    _;
  }
}