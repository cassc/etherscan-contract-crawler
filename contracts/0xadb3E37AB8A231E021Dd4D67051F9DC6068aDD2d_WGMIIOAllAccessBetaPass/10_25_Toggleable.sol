// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

error SaleNotActive();
error WhitelistNotActive();
error AllowlistNotActive();

abstract contract Toggleable is Ownable {

  bool public saleIsActive = false;
  bool public allowListIsActive = false;
  bool public whitelistIsActive = false;

    function flipWhitelistState() external onlyOwner {
    whitelistIsActive = !whitelistIsActive;
  }

  function flipSaleState() external onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function flipAllowListState() external onlyOwner {
    allowListIsActive = !allowListIsActive;
  }

  modifier requireActiveSale {
    if(!saleIsActive) revert SaleNotActive();
    _;
  }

  modifier requireActiveWhitelist {
    if(!whitelistIsActive) revert WhitelistNotActive();
    _;
  }

  modifier requireActiveAllowlist {
    if(!allowListIsActive) revert AllowlistNotActive();
    _;
  }

}