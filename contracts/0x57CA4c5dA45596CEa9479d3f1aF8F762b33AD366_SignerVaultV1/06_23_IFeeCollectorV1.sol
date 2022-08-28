// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./IVersion.sol";
import "../structs/Collaborations.sol";
import "../structs/Shareholders.sol";

interface IFeeCollectorV1 is IVersion {
  function contractDeployer() external view returns (address);

  function shares() external view returns (Shareholders memory);
  function setShares(address shareholder, uint share) external;

  function reductions() external view returns (Collaborations memory);
  function setReductions(address collaboration, uint minBalance, Fees calldata reduction) external;

  function partnerOf(address partner) external view returns (uint);
  function setPartnerOf(address partner, uint fee) external;

  function exemptOf(address vaultOrSigner) external view returns (bool);
  function setExemptOf(address vaultOrSigner, bool exempt) external;

  function lockETHFee() external view returns (uint);
  function lockETHFee(address vault, address signer) external view returns (uint);
  function setLockETHFee(uint lockETHFee_) external;

  function lockTokenFee() external view returns (uint);
  function lockTokenFee(address vault, address signer) external view returns (uint);
  function setLockTokenFee(uint lockTokenFee_) external;

  function lockERC721Fee() external view returns (uint);
  function lockERC721Fee(address vault, address signer) external view returns (uint);
  function setLockERC721Fee(uint lockERC721Fee_) external;

  function swapLiquidityFee() external view returns (uint);
  function swapLiquidityFee(address vault, address signer) external view returns (uint);
  function setSwapLiquidityFee(uint swapLiquidityFee_) external;

  function fees() external view returns (Fees memory);
  function fees(address vault, address signer) external view returns (Fees memory);
  function setFees(Fees calldata fees_) external;

  function payFee(uint fee) external payable;
  function payFeeOnPartner(uint fee, address partner) external payable;
}