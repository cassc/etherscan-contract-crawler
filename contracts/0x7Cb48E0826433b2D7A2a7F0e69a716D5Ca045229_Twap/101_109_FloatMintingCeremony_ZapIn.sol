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
// - Uses msg.sender / removes the transfer from the zap contract.
// - Uses IMintingCeremony over IVault
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../funds/interfaces/IMintingCeremony.sol";
import "../external-lib/zapper/ZapInBaseV2.sol";

contract FloatMintingCeremonyZapInV1 is ZapInBaseV2 {
  using SafeMath for uint256;

  // calldata only accepted for approved zap contracts
  mapping(address => bool) public approvedTargets;

  event zapIn(address sender, address pool, uint256 tokensRec);

  constructor(uint256 _goodwill, uint256 _affiliateSplit)
    ZapBaseV1(_goodwill, _affiliateSplit)
  {}

  /**
    @notice This function commits to the Float Minting Ceremony with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param ceremony Float Protocol: Minting Ceremony address
    @param minFloatTokens The minimum acceptable quantity Float tokens to receive. Reverts otherwise
    @param intermediateToken Token to swap fromToken to before entering ceremony
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensReceived - Quantity of FLOAT that will be received
     */
  function ZapIn(
    address fromToken,
    uint256 amountIn,
    address ceremony,
    uint256 minFloatTokens,
    address intermediateToken,
    address swapTarget,
    bytes calldata swapData,
    address affiliate,
    bool shouldSellEntireBalance
  ) external payable stopInEmergency returns (uint256 tokensReceived) {
    require(
      approvedTargets[swapTarget] || swapTarget == address(0),
      "Target not Authorized"
    );

    // get incoming tokens
    uint256 toInvest =
      _pullTokens(
        fromToken,
        amountIn,
        affiliate,
        true,
        shouldSellEntireBalance
      );

    // get intermediate token
    uint256 intermediateAmt =
      _fillQuote(fromToken, intermediateToken, toInvest, swapTarget, swapData);

    // Deposit to Minting Ceremony
    tokensReceived = _ceremonyCommit(intermediateAmt, ceremony, minFloatTokens);
  }

  function _ceremonyCommit(
    uint256 amount,
    address toCeremony,
    uint256 minTokensRec
  ) internal returns (uint256 tokensReceived) {
    address underlyingVaultToken = IMintingCeremony(toCeremony).underlying();

    _approveToken(underlyingVaultToken, toCeremony);

    uint256 initialBal = IERC20(toCeremony).balanceOf(msg.sender);
    IMintingCeremony(toCeremony).commit(msg.sender, amount, minTokensRec);
    tokensReceived = IERC20(toCeremony).balanceOf(msg.sender).sub(initialBal);
    require(tokensReceived >= minTokensRec, "Err: High Slippage");

    // Note that tokens are gifted directly, so we don't transfer from vault.
    // IERC20(toCeremony).safeTransfer(msg.sender, tokensReceived);
    emit zapIn(msg.sender, toCeremony, tokensReceived);
  }

  function _fillQuote(
    address _fromTokenAddress,
    address toToken,
    uint256 _amount,
    address _swapTarget,
    bytes memory swapCallData
  ) internal returns (uint256 amtBought) {
    uint256 valueToSend;

    if (_fromTokenAddress == toToken) {
      return _amount;
    }

    if (_fromTokenAddress == address(0)) {
      valueToSend = _amount;
    } else {
      _approveToken(_fromTokenAddress, _swapTarget);
    }

    uint256 iniBal = _getBalance(toToken);
    (bool success, ) = _swapTarget.call{value: valueToSend}(swapCallData);
    require(success, "Error Swapping Tokens 1");
    uint256 finalBal = _getBalance(toToken);

    amtBought = finalBal.sub(iniBal);
  }

  function setApprovedTargets(
    address[] calldata targets,
    bool[] calldata isApproved
  ) external onlyOwner {
    require(targets.length == isApproved.length, "Invalid Input length");

    for (uint256 i = 0; i < targets.length; i++) {
      approvedTargets[targets[i]] = isApproved[i];
    }
  }
}