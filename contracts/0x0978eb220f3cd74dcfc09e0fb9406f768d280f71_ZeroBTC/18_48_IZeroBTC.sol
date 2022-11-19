// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { ModuleType } from "../utils/ModuleStateCoder.sol";
import { IERC4626 } from "./IERC4626.sol";
import "./IGovernable.sol";
import "./InitializationErrors.sol";

interface IZeroBTC is IERC4626, IGovernable, InitializationErrors {
  /*//////////////////////////////////////////////////////////////
                               Actions
  //////////////////////////////////////////////////////////////*/

  function loan(
    address module,
    address borrower,
    uint256 borrowAmount,
    uint256 nonce,
    bytes memory data
  ) external;

  function fallbackMint(
    address module,
    address borrower,
    uint256 borrowAmount,
    uint256 nonce,
    bytes memory data,
    bytes32 nHash,
    bytes memory renSignature
  ) external;

  function repay(
    address module,
    address borrower,
    uint256 borrowAmount,
    uint256 nonce,
    bytes memory data,
    address lender,
    bytes32 nHash,
    bytes memory renSignature
  ) external;

  function closeExpiredLoan(
    address module,
    address borrower,
    uint256 borrowAmount,
    uint256 nonce,
    bytes memory data,
    address lender
  ) external;

  function earn() external;

  function setGlobalFees(
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 zeroFeeShareBips
  ) external;

  function setModuleGasFees(
    address module,
    uint256 loanGas,
    uint256 repayGas
  ) external;

  function addModule(
    address module,
    ModuleType moduleType,
    uint256 loanGas,
    uint256 repayGas
  ) external;

  function removeModule(address module) external;

  function pokeGlobalCache() external;

  function pokeModuleCache(address module) external;

  function initialize(
    address initialGovernance,
    uint256 zeroBorrowFeeBips,
    uint256 renBorrowFeeBips,
    uint256 zeroBorrowFeeStatic,
    uint256 renBorrowFeeStatic,
    uint256 zeroFeeShareBips,
    address initialHarvester
  ) external payable;

  /*//////////////////////////////////////////////////////////////
                               Getters
  //////////////////////////////////////////////////////////////*/

  function getConfig()
    external
    view
    returns (
      address gatewayRegistry,
      address btcEthPriceOracle,
      address gasPriceOracle,
      address renBtcConverter,
      uint256 cacheTimeToLive,
      uint256 maxLoanDuration,
      uint256 targetEthReserve,
      uint256 maxGasProfitShareBips,
      address zeroFeeRecipient
    );

  function getGlobalState()
    external
    view
    returns (
      uint256 zeroBorrowFeeBips,
      uint256 renBorrowFeeBips,
      uint256 zeroFeeShareBips,
      uint256 zeroBorrowFeeStatic,
      uint256 renBorrowFeeStatic,
      uint256 satoshiPerEth,
      uint256 gweiPerGas,
      uint256 lastUpdateTimestamp,
      uint256 totalBitcoinBorrowed,
      uint256 unburnedGasReserveShares,
      uint256 unburnedZeroFeeShares
    );

  function getModuleState(address module)
    external
    view
    returns (
      ModuleType moduleType,
      uint256 loanGasE4,
      uint256 repayGasE4,
      uint256 ethRefundForLoanGas,
      uint256 ethRefundForRepayGas,
      uint256 btcFeeForLoanGas,
      uint256 btcFeeForRepayGas,
      uint256 lastUpdateTimestamp
    );

  function getOutstandingLoan(uint256 loanId)
    external
    view
    returns (
      uint256 sharesLocked,
      uint256 actualBorrowAmount,
      uint256 lenderDebt,
      uint256 vaultExpenseWithoutRepayFee,
      uint256 expiry,
      address lender
    );

  function calculateLoanId(
    address module,
    address borrower,
    uint256 borrowAmount,
    uint256 nonce,
    bytes memory data,
    address lender
  ) external view returns (uint256);

  /*//////////////////////////////////////////////////////////////
                               Errors
  //////////////////////////////////////////////////////////////*/

  error ModuleDoesNotExist();

  error ReceiveLoanError(address module, address borrower, uint256 borrowAmount, uint256 loanId, bytes data);

  error RepayLoanError(address module, address borrower, uint256 repaidAmount, uint256 loanId, bytes data);

  error ModuleAssetDoesNotMatch(address moduleAsset);

  error InvalidModuleType();

  error InvalidDynamicBorrowFee();

  error LoanDoesNotExist(uint256 loanId);

  error LoanIdNotUnique(uint256 loanId);

  error InvalidNullValue();

  error InvalidSelector();

  error LoanNotExpired(uint256 loanId);

  /*//////////////////////////////////////////////////////////////
                                Events
  //////////////////////////////////////////////////////////////*/

  event LoanCreated(address lender, address borrower, uint256 loanId, uint256 assetsBorrowed, uint256 sharesLocked);

  event LoanClosed(uint256 loanId, uint256 assetsRepaid, uint256 sharesUnlocked, uint256 sharesBurned);

  event ModuleStateUpdated(address module, ModuleType moduleType, uint256 loanGasE4, uint256 repayGasE4);

  event GlobalStateConfigUpdated(uint256 dynamicBorrowFee, uint256 staticBorrowFee);

  event GlobalStateCacheUpdated(uint256 satoshiPerEth, uint256 getGweiPerGas);

  event FeeSharesMinted(uint256 gasReserveFees, uint256 gasReserveShares, uint256 zeroFees, uint256 zeroFeeShares);

  event FeeSharesBurned(uint256 gasReserveFees, uint256 gasReserveShares, uint256 zeroFees, uint256 zeroFeeShares);
}