// SPDX-License-Identifier: MIT
//
// ...............   ...............   ...............  .....   ...............
// :==============.  ===============  :==============:  -====  .==============-
// :==============.  ===============  :==============:  -====  .==============-
// :==============.  ===============  :==============:  -====  .==============-
// :==============.  ===============  :==============:  -====  .==============-
// .::::-====-::::.  ===============  :====-:::::::::.  -====  .====-::::-====-
//      :====.       ===============  :====:            -====  .====:    .====-
//      :====.       ===============  :====:            -====  .====:    .====-
//
// Learn more at https://topia.gg or Twitter @TOPIAgg

pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WRLD_To_TOPIA_Migration is Ownable {
  IERC20 private immutable wrld1Token;
  IERC20 private immutable wrld2Token;
  IERC20 private immutable topiaToken;

  constructor(address wrld1TokenAddress, address wrld2TokenAddress, address topiaTokenAddress) {
    wrld1Token = IERC20(wrld1TokenAddress);
    wrld2Token = IERC20(wrld2TokenAddress);
    topiaToken = IERC20(topiaTokenAddress);
  }

  function swapWrld1ToTopia(uint256 amount) external {
    require(topiaToken.balanceOf(address(this)) >= amount, "Migration contract requires $TOPIA refill");
    wrld1Token.transferFrom(msg.sender, address(this), amount);
    topiaToken.transfer(msg.sender, amount);
  }

  function swapWrld2ToTopia(uint256 amount) external {
    uint256 swapAmount = amount * 952381 / 1000000; // reversion of the prior 5% wrld 1.0 -> 2.0 bonus.
    require(topiaToken.balanceOf(address(this)) >= swapAmount, "Migration contract requires $TOPIA refill");
    wrld2Token.transferFrom(msg.sender, address(this), amount);
    topiaToken.transfer(msg.sender, swapAmount);
  }
}