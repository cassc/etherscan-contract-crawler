// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
// SPDX-License-Identifier: GPLv2

// Changes:
// - Conversion to 0.7.6
//   - abstract type
//   - library imports throughout

pragma solidity ^0.7.6;

import "./ZapBaseV1.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract ZapInBaseV2 is ZapBaseV1 {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  function _pullTokens(
    address token,
    uint256 amount,
    address affiliate,
    bool enableGoodwill,
    bool shouldSellEntireBalance
  ) internal returns (uint256 value) {
    uint256 totalGoodwillPortion;

    if (token == address(0)) {
      require(msg.value > 0, "No eth sent");

      // subtract goodwill
      totalGoodwillPortion = _subtractGoodwill(
        ETHAddress,
        msg.value,
        affiliate,
        enableGoodwill
      );

      return msg.value.sub(totalGoodwillPortion);
    }
    require(amount > 0, "Invalid token amount");
    require(msg.value == 0, "Eth sent with token");

    //transfer token
    if (shouldSellEntireBalance) {
      require(
        Address.isContract(msg.sender),
        "ERR: shouldSellEntireBalance is true for EOA"
      );
      amount = IERC20(token).allowance(msg.sender, address(this));
    }
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

    // subtract goodwill
    totalGoodwillPortion = _subtractGoodwill(
      token,
      amount,
      affiliate,
      enableGoodwill
    );

    return amount.sub(totalGoodwillPortion);
  }

  function _subtractGoodwill(
    address token,
    uint256 amount,
    address affiliate,
    bool enableGoodwill
  ) internal returns (uint256 totalGoodwillPortion) {
    bool whitelisted = feeWhitelist[msg.sender];
    if (enableGoodwill && !whitelisted && goodwill > 0) {
      totalGoodwillPortion = SafeMath.div(
        SafeMath.mul(amount, goodwill),
        10000
      );

      if (affiliates[affiliate]) {
        if (token == address(0)) {
          token = ETHAddress;
        }

        uint256 affiliatePortion =
          totalGoodwillPortion.mul(affiliateSplit).div(100);
        affiliateBalance[affiliate][token] = affiliateBalance[affiliate][token]
          .add(affiliatePortion);
        totalAffiliateBalance[token] = totalAffiliateBalance[token].add(
          affiliatePortion
        );
      }
    }
  }
}