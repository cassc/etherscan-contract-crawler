// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
pragma abicoder v2;

import {IVaultAddressesProvider} from './IVaultAddressesProvider.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';

interface IVault {
  /**
   * @dev Emitted on deposit()
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the oTokens
   * @param amount The amount deposited
   **/
  event Deposit(
    address indexed user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  event FundDeposit(address indexed from, uint256 amount);

  /**
   * @dev Emitted on withdraw()
   * @param user The address initiating the withdrawal, owner of oTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed user, address indexed to, uint256 amount);

  event FundWithdraw(address indexed to, uint256 amount);

  event FundAddressUpdated(address indexed newFundAddress);

  event NetValueUpdated(uint256 previousNetValue, uint256 newNetValue, uint256 previousLiquidityIndex, uint256 newLiquidityIndex, int256 currentLiquidityRate);

  event PeriodInitialized(uint256 previousLiquidityIndex, uint40 purchaseBeginTimestamp, uint40 purchaseEndTimestamp, uint40 redemptionBeginTimestamp, uint16 managementFeeRate, uint16 performanceFeeRate);

  event PurchaseEndTimestampMoved(uint40 previousTimestamp, uint40 newTimetamp);

  event RedemptionBeginTimestampMoved(uint40 previousTimestamp, uint40 newTimetamp);

  event PurchaseBeginTimestampMoved(uint40 previousTimestamp, uint40 newTimetamp);

  event AddedToWhitelist(address indexed user, uint256 expirationTime);

  event RemoveFromWhitelist(address indexed user);

  event WhitelistExpirationUpdated(uint256 newExpiration);

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying oTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the oTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of oTokens
   *   is a different wallet
   **/
  function deposit(
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external returns (uint256);

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent oTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole oToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    uint256 amount,
    address to
  ) external returns (uint256);

  function depositFund(uint256 amount) external;

  function withdrawFund(uint256 amount) external returns (uint256);

  function initReserve(address oToken, address fundAddress) external;

  function addToWhitelist(address user) external;

  function batchAddToWhitelist(address[] memory users) external;

  function removeFromWhitelist(address user) external;

  function batchRemoveFromWhitelist(address[] memory users) external;

  function isInWhitelist(address user) external returns (bool);

  function getUserExpirationTimestamp(address user) external returns(uint256);

  /**
   * @dev Returns the configuration of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration()
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  function setConfiguration(uint256 configuration) external;

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome() external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @return The state of the reserve
   **/
  function getReserveData() external view returns (DataTypes.ReserveData memory);

  function getAddressesProvider() external view returns (IVaultAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);

  function setFuncAddress(address fundAddress) external;

  function getWhitelistExpiration() external returns(uint256);

  function setWhitelistExpiration(uint256 expiration) external;

  function initializeNextPeriod(uint16 managementFeeRate, uint16 performanceFeeRate, 
    uint128 purchaseUpperLimit,
    uint128 softUpperLimit,
    uint40 purchaseBeginTimestamp, uint40 purchaseEndTimestamp, 
    uint40 redemptionBeginTimestamp)
    external;

  function moveTheLockPeriod(uint40 newPurchaseEndTimestamp) external;

  function moveTheRedemptionPeriod(uint40 newRedemptionBeginTimestamp) external;

  function moveThePurchasePeriod(uint40 newPurchaseBeginTimestamp) external;
}