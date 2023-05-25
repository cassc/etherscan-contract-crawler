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
//   - library imports throughout
//   - remove revert fallback as now default

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

pragma solidity ^0.7.6;

contract ZapBaseV1 is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  bool public stopped = false;

  // if true, goodwill is not deducted
  mapping(address => bool) public feeWhitelist;

  uint256 public goodwill;
  // % share of goodwill (0-100 %)
  uint256 affiliateSplit;
  // restrict affiliates
  mapping(address => bool) public affiliates;
  // affiliate => token => amount
  mapping(address => mapping(address => uint256)) public affiliateBalance;
  // token => amount
  mapping(address => uint256) public totalAffiliateBalance;

  address internal constant ETHAddress =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  constructor(uint256 _goodwill, uint256 _affiliateSplit) {
    goodwill = _goodwill;
    affiliateSplit = _affiliateSplit;
  }

  // circuit breaker modifiers
  modifier stopInEmergency {
    if (stopped) {
      revert("Temporarily Paused");
    } else {
      _;
    }
  }

  function _getBalance(address token) internal view returns (uint256 balance) {
    if (token == address(0)) {
      balance = address(this).balance;
    } else {
      balance = IERC20(token).balanceOf(address(this));
    }
  }

  function _approveToken(address token, address spender) internal {
    IERC20 _token = IERC20(token);
    if (_token.allowance(address(this), spender) > 0) return;
    else {
      _token.safeApprove(spender, uint256(-1));
    }
  }

  function _approveToken(
    address token,
    address spender,
    uint256 amount
  ) internal {
    IERC20 _token = IERC20(token);
    _token.safeApprove(spender, 0);
    _token.safeApprove(spender, amount);
  }

  // - to Pause the contract
  function toggleContractActive() public onlyOwner {
    stopped = !stopped;
  }

  function set_feeWhitelist(address zapAddress, bool status)
    external
    onlyOwner
  {
    feeWhitelist[zapAddress] = status;
  }

  function set_new_goodwill(uint256 _new_goodwill) public onlyOwner {
    require(
      _new_goodwill >= 0 && _new_goodwill <= 100,
      "GoodWill Value not allowed"
    );
    goodwill = _new_goodwill;
  }

  function set_new_affiliateSplit(uint256 _new_affiliateSplit)
    external
    onlyOwner
  {
    require(_new_affiliateSplit <= 100, "Affiliate Split Value not allowed");
    affiliateSplit = _new_affiliateSplit;
  }

  function set_affiliate(address _affiliate, bool _status) external onlyOwner {
    affiliates[_affiliate] = _status;
  }

  ///@notice Withdraw goodwill share, retaining affilliate share
  function withdrawTokens(address[] calldata tokens) external onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 qty;

      if (tokens[i] == ETHAddress) {
        qty = address(this).balance.sub(totalAffiliateBalance[tokens[i]]);
        Address.sendValue(payable(owner()), qty);
      } else {
        qty = IERC20(tokens[i]).balanceOf(address(this)).sub(
          totalAffiliateBalance[tokens[i]]
        );
        IERC20(tokens[i]).safeTransfer(owner(), qty);
      }
    }
  }

  ///@notice Withdraw affilliate share, retaining goodwill share
  function affilliateWithdraw(address[] calldata tokens) external {
    uint256 tokenBal;
    for (uint256 i = 0; i < tokens.length; i++) {
      tokenBal = affiliateBalance[msg.sender][tokens[i]];
      affiliateBalance[msg.sender][tokens[i]] = 0;
      totalAffiliateBalance[tokens[i]] = totalAffiliateBalance[tokens[i]].sub(
        tokenBal
      );

      if (tokens[i] == ETHAddress) {
        Address.sendValue(msg.sender, tokenBal);
      } else {
        IERC20(tokens[i]).safeTransfer(msg.sender, tokenBal);
      }
    }
  }
}