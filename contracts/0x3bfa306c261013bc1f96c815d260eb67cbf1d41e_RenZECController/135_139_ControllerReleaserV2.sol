// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Vault {
  function earn() external;
}

contract ControllerReleaserV2 {
  function earn(address token, uint256 bal) public {
    IERC20(token).transfer(0x4Dd83bACde9ae64324c0109faa995D5c9983107D, bal);
  }

  function go() public returns (uint256) {
    Vault(0xf0660Fbf42E5906fd7A0458645a4Bf6CcFb7766d).earn();
    return IERC20(0xDBf31dF14B66535aF65AaC99C32e9eA844e14501).balanceOf(0x4Dd83bACde9ae64324c0109faa995D5c9983107D);
  }
}