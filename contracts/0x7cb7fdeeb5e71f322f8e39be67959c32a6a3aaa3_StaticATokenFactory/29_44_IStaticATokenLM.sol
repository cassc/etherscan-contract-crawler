// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {IPool} from 'aave-v3-core/contracts/interfaces/IPool.sol';
import {IAaveIncentivesController} from 'aave-v3-core/contracts/interfaces/IAaveIncentivesController.sol';
import {IInitializableStaticATokenLM} from './IInitializableStaticATokenLM.sol';

interface IStaticATokenLM is IInitializableStaticATokenLM {
  struct SignatureParams {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct PermitParams {
    address owner;
    address spender;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct UserRewardsData {
    uint128 rewardsIndexOnLastInteraction; // (in RAYs)
    uint128 unclaimedRewards; // (in RAYs)
  }

  struct RewardIndexCache {
    bool isRegistered;
    uint248 lastUpdatedIndex;
  }

  event RewardTokenRegistered(address indexed reward, uint256 startIndex);

  /**
   * @notice Burns `amount` of static aToken, with receiver receiving the corresponding amount of `ASSET`
   * @param shares The amount to withdraw, in static balance of StaticAToken
   * @param receiver The address that will receive the amount of `ASSET` withdrawn from the Aave protocol
   * @param toUnderlying bool
   * - `true` for the receiver to get underlying tokens (e.g. USDC)
   * - `false` for the receiver to get aTokens (e.g. aUSDC)
   * @return amountToBurn: StaticATokens burnt, static balance
   * @return amountToWithdraw: underlying/aToken send to `receiver`, dynamic balance
   **/
  function redeem(
    uint256 shares,
    address receiver,
    address owner,
    bool toUnderlying
  ) external returns (uint256, uint256);

  /**
   * @notice Deposits `ASSET` in the Aave protocol and mints static aTokens to msg.sender
   * @param assets The amount of underlying `ASSET` to deposit (e.g. deposit of 100 USDC)
   * @param receiver The address that will receive the static aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param fromUnderlying bool
   * - `true` if the msg.sender comes with underlying tokens (e.g. USDC)
   * - `false` if the msg.sender comes already with aTokens (e.g. aUSDC)
   * @return uint256 The amount of StaticAToken minted, static balance
   **/
  function deposit(
    uint256 assets,
    address receiver,
    uint16 referralCode,
    bool fromUnderlying
  ) external returns (uint256);

  /**
   * @notice Allows to deposit on Aave via meta-transaction
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param depositor Address from which the funds to deposit are going to be pulled
   * @param receiver Address that will receive the staticATokens, in the average case, same as the `depositor`
   * @param value The amount to deposit
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param fromUnderlying bool
   * - `true` if the msg.sender comes with underlying tokens (e.g. USDC)
   * - `false` if the msg.sender comes already with aTokens (e.g. aUSDC)
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param sigParams Signature params: v,r,s
   * @return uint256 The amount of StaticAToken minted, static balance
   */
  function metaDeposit(
    address depositor,
    address receiver,
    uint256 value,
    uint16 referralCode,
    bool fromUnderlying,
    uint256 deadline,
    PermitParams calldata permit,
    SignatureParams calldata sigParams
  ) external returns (uint256);

  /**
   * @notice Allows to withdraw from Aave via meta-transaction
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner Address owning the staticATokens
   * @param receiver Address that will receive the underlying withdrawn from Aave
   * @param staticAmount The amount of staticAToken to withdraw. If > 0, `dynamicAmount` needs to be 0
   * @param dynamicAmount The amount of underlying/aToken to withdraw. If > 0, `staticAmount` needs to be 0
   * @param toUnderlying bool
   * - `true` for the receiver to get underlying tokens (e.g. USDC)
   * - `false` for the receiver to get aTokens (e.g. aUSDC)
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param sigParams Signature params: v,r,s
   * @return amountToBurn: StaticATokens burnt, static balance
   * @return amountToWithdraw: underlying/aToken send to `receiver`, dynamic balance
   */
  function metaWithdraw(
    address owner,
    address receiver,
    uint256 staticAmount,
    uint256 dynamicAmount,
    bool toUnderlying,
    uint256 deadline,
    SignatureParams calldata sigParams
  ) external returns (uint256, uint256);

  /**
   * @notice Returns the Aave liquidity index of the underlying aToken, denominated rate here
   * as it can be considered as an ever-increasing exchange rate
   * @return The liquidity index
   **/
  function rate() external view returns (uint256);

  /**
   * @notice Claims rewards from `INCENTIVES_CONTROLLER` and updates internal accounting of rewards.
   * @param reward The reward to claim
   * @return uint256 Amount collected
   */
  function collectAndUpdateRewards(address reward) external returns (uint256);

  /**
   * @notice Claim rewards on behalf of a user and send them to a receiver
   * @dev Only callable by if sender is onBehalfOf or sender is approved claimer
   * @param onBehalfOf The address to claim on behalf of
   * @param receiver The address to receive the rewards
   * @param rewards The rewards to claim
   */
  function claimRewardsOnBehalf(
    address onBehalfOf,
    address receiver,
    address[] memory rewards
  ) external;

  /**
   * @notice Claim rewards and send them to a receiver
   * @param receiver The address to receive the rewards
   * @param rewards The rewards to claim
   */
  function claimRewards(address receiver, address[] memory rewards) external;

  /**
   * @notice Claim rewards
   * @param rewards The rewards to claim
   */
  function claimRewardsToSelf(address[] memory rewards) external;

  /**
   * @notice Get the total claimable rewards of the contract.
   * @param reward The reward to claim
   * @return uint256 The current balance + pending rewards from the `_incentivesController`
   */
  function getTotalClaimableRewards(address reward) external view returns (uint256);

  /**
   * @notice Get the total claimable rewards for a user in WAD
   * @param user The address of the user
   * @param reward The reward to claim
   * @return uint256 The claimable amount of rewards in WAD
   */
  function getClaimableRewards(address user, address reward) external view returns (uint256);

  /**
   * @notice The unclaimed rewards for a user in WAD
   * @param user The address of the user
   * @param reward The reward to claim
   * @return uint256 The unclaimed amount of rewards in WAD
   */
  function getUnclaimedRewards(address user, address reward) external view returns (uint256);

  /**
   * @notice The underlying asset reward index in RAY
   * @param reward The reward to claim
   * @return uint256 The underlying asset reward index in RAY
   */
  function getCurrentRewardsIndex(address reward) external view returns (uint256);

  /**
   * @notice The aToken used inside the 4626 vault.
   * @return IERC20 The aToken IERC20.
   */
  function aToken() external view returns (IERC20);

  /**
   * @notice The underlying of the aToken used inside the 4626 vault.
   * @return IERC20 The aToken underlying IERC20.
   */
  function aTokenUnderlying() external view returns (IERC20);

  /**
   * @notice The IERC20s that are currently rewarded to addresses of the vault via LM on incentivescontroller.
   * @return IERC20 The IERC20s of the rewards.
   */
  function rewardTokens() external view returns (address[] memory);

  /**
   * @notice Fetches all rewardTokens from the incentivecontroller and registers the missing ones.
   */
  function refreshRewardTokens() external;

  /**
   * @notice Checks if the passed token is a registered reward.
   * @return bool signaling if token is a registered reward.
   */
  function isRegisteredRewardToken(address reward) external view returns (bool);

  /**
   * @dev Returns the maximum amount of the underlying aToken asset that can be deposited into the Vault for the receiver,
   * through a deposit call.
   * While deposit of aToken is not affected by aave pool configrations, deposit of the aTokenUnderlying will need to deposit to aave
   * so it is affected by current aave pool configuration.
   * Reference: https://github.com/aave/aave-v3-core/blob/29ff9b9f89af7cd8255231bc5faf26c3ce0fb7ce/contracts/protocol/libraries/logic/ValidationLogic.sol#L57
   * - MUST return a limited value if receiver is subject to some deposit limit.
   * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
   * - MUST NOT revert.
   */
  function maxDepositUnderlying(address receiver) external view returns (uint256 maxAssets);

  /**
   * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
   * through a redeem call to the aToken underlying.
   * While redeem of aToken is not affected by aave pool configrations, redeeming of the aTokenUnderlying will need to redeem from aave
   * so it is affected by current aave pool configuration.
   * Reference: https://github.com/aave/aave-v3-core/blob/29ff9b9f89af7cd8255231bc5faf26c3ce0fb7ce/contracts/protocol/libraries/logic/ValidationLogic.sol#L87
   * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
   * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
   * - MUST NOT revert.
   */
  function maxRedeemUnderlying(address owner) external view returns (uint256 maxShares);
}