// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Special_Clothing {
  using Strings for uint256;

  string constant SPECIAL_CLOTHING_SHIRT___GHOST =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////AAAAzs7O////E2eUFAAAAAR0Uk5T////AEAqqfQAAADsSURBVHja7NfhDoMgDATga/f+77woaEBLvcpEY8YfiHqfrdmM4NM58G5A1nEKEME6HANEPBExYBOfiQhg5FvCQwEz3xCuBKaz1SIIpNPlYhwgsFswBfDPsBtQFpD5YlZ4IlDltQYMIQKYJZiAohPY5/NCCUDgAfsSQBXglACqAKcEkP+DOKAmgCNAintxQgtQ/BoACzQ6iALtvA8QHWwFEB3oaUDvAzZJDQBmsp7OA3lmAHhQB5DmW4CqhyHA7hdU9jACUOetfDGQBReQg9f6NPIWYfnkr49Rn3nLdcV+pbVxefmu7Q+MAr4CDACcJh9f/5NQsQAAAABJRU5ErkJggg==";

  function getAsset(uint256 headNum) external pure returns (string memory) {
    if (headNum == 0) {
      return SPECIAL_CLOTHING_SHIRT___GHOST;
    }
    return SPECIAL_CLOTHING_SHIRT___GHOST;
  }
}