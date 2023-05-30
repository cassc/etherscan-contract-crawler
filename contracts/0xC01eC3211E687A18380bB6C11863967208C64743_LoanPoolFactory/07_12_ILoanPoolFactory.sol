// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ILoanPool.sol";
import "./ICreditLineBase.sol";

interface ILoanPoolFactory {
  /// @notice Credit line template is not registered with the factory
  error CreditLineTemplateNotRegistered();

  /// @notice New loan pool has been created
  /// @param loanPool Address of the loan pool
  /// @param borrower Address of the borrower
  /// @param fundingAsset Address of the asset used for the loan
  /// @param creditLineTemplate Address of the template which loan terms
  /// @param creditLine Address of the credit line
  /// @param maxLimit Maximum amount of funds that can be raised
  /// @param fees Fees charged for the loan
  event LoanPoolCreated(
    address indexed loanPool,
    address indexed borrower,
    address indexed fundingAsset,
    address creditLineTemplate,
    address creditLine,
    uint256 maxLimit,
    uint256 fees
  );

  /// @notice Fee recipient has been updated
  /// @param feeRecipient Address of fee recipient
  event UpdateFeeRecipient(address indexed feeRecipient);

  /// @notice Fee tier of a particular asset has been updated
  /// @param asset Address of the asset
  /// @param tier Updated fee tier of the asset
  event UpdateAssetFeeTier(address indexed asset, uint256 indexed tier);

  /// @notice Updated fees for a fee tier
  /// @param tier Fee tier
  /// @param fees Fees for the fee tier
  event UpdateFeeTier(uint256 indexed tier, uint256 fees);

  /// @notice Credit line template has been registered or unregistered
  /// @param creditLineTemplate Address of the credit line template
  /// @param isRegistered If the template can be used in creating new loan pools
  event UpdateCreditLineTemplate(
    address indexed creditLineTemplate,
    bool indexed isRegistered
  );

  function createPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[11] calldata _uints
  ) external returns (ILoanPool loanPool, ICreditLineBase creditLine);

  function createCustomPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[12] calldata _uints
  ) external returns (ILoanPool loanPool, ICreditLineBase creditLine);

  function feeRecipient() external view returns (address);

  function loanPoolTemplate() external view returns (address);

  function isCreditLineTemplate(address template) external view returns (bool);

  function feesForTier(uint256 tier) external view returns (uint256);

  function feesTierForAsset(address asset) external view returns (uint256);

  function loanPoolDeployed(address) external view returns (bool);

  function feesOnAsset(address asset) external view returns (uint256 fee);

  function addCreditLine(address _creditLine) external;

  function removeCreditLine(address _creditLine) external;

  function setFeeTier(uint256 tier, uint256 fee) external;

  function setAssetFeeTier(address asset, uint256 tier) external;

  function setFeeRecipient(address _feeRecipient) external;
}