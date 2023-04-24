// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol';
import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAPermissionManager.sol';
import './ILegacyDCAHub.sol';
import './ISharedTypes.sol';

/**
 * @notice This contract exposes many utils that are also available through libraries. The idea is to make
 *         these functions available here, so others don't need to deploy new contracts
 */
interface IDCAHubCompanionLibrariesHandler {
  /**
   * @notice Takes a list of pairs and returns how it would look like to execute a swap for all of them
   * @dev Please note that this function is very expensive. Ideally, it would be used for off-chain purposes
   * @param hub The address of the DCAHub
   * @param pairs The pairs to be involved in the swap
   * @param calculatePrivilegedAvailability Some accounts get privileged availability and can execute swaps before others. This flag provides
   *        the possibility to calculate the next swap information for privileged and non-privileged accounts
   * @param oracleData Bytes to send to the oracle when executing a quote
   * @return How executing a swap for all the given pairs would look like
   */
  function getNextSwapInfo(
    IDCAHub hub,
    Pair[] calldata pairs,
    bool calculatePrivilegedAvailability,
    bytes calldata oracleData
  ) external view returns (IDCAHub.SwapInfo memory);

  /**
   * @notice Takes a list of pairs and returns how it would look like to execute a swap for all of them
   * @dev Please note that this function is very expensive. Ideally, it would be used for off-chain purposes
   * @param hub The address of the DCAHub
   * @param pairs The pairs to be involved in the swap
   * @return How executing a swap for all the given pairs would look like
   */
  function legacyGetNextSwapInfo(ILegacyDCAHub hub, Pair[] calldata pairs) external view returns (ILegacyDCAHub.SwapInfo memory);

  /**
   * @notice Returns how many seconds left until the next swap is available for a list of pairs
   * @dev Tokens in pairs may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param hub The address of the DCAHub
   * @param pairs Pairs to check
   * @param calculatePrivilegedAvailability Some accounts get privileged availability and can execute swaps before others. This flag provides
   *        the possibility to calculate the seconds until next swap for privileged and non-privileged accounts
   * @return The amount of seconds until next swap for each of the pairs
   */
  function secondsUntilNextSwap(
    IDCAHub hub,
    Pair[] calldata pairs,
    bool calculatePrivilegedAvailability
  ) external view returns (uint256[] memory);
}

interface IDCAHubCompanionHubProxyHandler {
  /// @notice Thrown when a user tries operate on a position that they don't have access to
  error UnauthorizedCaller();

  /**
   * @notice Creates a new position
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param from The address of the "from" token
   * @param to The address of the "to" token
   * @param amount How many "from" tokens will be swapped in total
   * @param amountOfSwaps How many swaps to execute for this position
   * @param swapInterval How frequently the position's swaps should be executed
   * @param owner The address of the owner of the position being created
   * @param miscellaneous Bytes that will be emitted, and associated with the position. If empty, no event will be emitted
   * @return positionId The id of the created position
   */
  function deposit(
    IDCAHub hub,
    address from,
    address to,
    uint256 amount,
    uint32 amountOfSwaps,
    uint32 swapInterval,
    address owner,
    IDCAPermissionManager.PermissionSet[] calldata permissions,
    bytes calldata miscellaneous
  ) external payable returns (uint256 positionId);

  /**
   * @notice Creates a new position using the entire balance available on the contract
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param from The address of the "from" token
   * @param to The address of the "to" token
   * @param amountOfSwaps How many swaps to execute for this position
   * @param swapInterval How frequently the position's swaps should be executed
   * @param owner The address of the owner of the position being created
   * @param miscellaneous Bytes that will be emitted, and associated with the position. If empty, no event will be emitted
   * @return positionId The id of the created position
   */
  function depositWithBalanceOnContract(
    IDCAHub hub,
    address from,
    address to,
    uint32 amountOfSwaps,
    uint32 swapInterval,
    address owner,
    IDCAPermissionManager.PermissionSet[] calldata permissions,
    bytes calldata miscellaneous
  ) external payable returns (uint256 positionId);

  /**
   * @notice Call the hub and withdraws all swapped tokens from a position to a recipient
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param positionId The position's id
   * @param recipient The address to withdraw swapped tokens to
   * @return swapped How much was withdrawn
   */
  function withdrawSwapped(
    IDCAHub hub,
    uint256 positionId,
    address recipient
  ) external payable returns (uint256 swapped);

  /**
   * @notice Call the hub and withdraws all swapped tokens from multiple positions
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param positions A list positions, grouped by `to` token
   * @param recipient The address to withdraw swapped tokens to
   * @return withdrawn How much was withdrawn for each token
   */
  function withdrawSwappedMany(
    IDCAHub hub,
    IDCAHub.PositionSet[] calldata positions,
    address recipient
  ) external payable returns (uint256[] memory withdrawn);

  /**
   * @notice Call the hub and takes the unswapped balance, adds the new deposited funds and modifies the position so that
   * it is executed in `newSwaps` swaps
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param positionId The position's id
   * @param amount Amount of funds to add to the position
   * @param newSwaps The new amount of swaps
   */
  function increasePosition(
    IDCAHub hub,
    uint256 positionId,
    uint256 amount,
    uint32 newSwaps
  ) external payable;

  /**
   * @notice Call the hub and takes the unswapped balance, adds the Companion's current balance and modifies the position so that
   * it is executed in `newSwaps` swaps
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param positionId The position's id
   * @param newSwaps The new amount of swaps
   */
  function increasePositionWithBalanceOnContract(
    IDCAHub hub,
    uint256 positionId,
    uint32 newSwaps
  ) external payable;

  /**
   * @notice Call the hub and withdraws the specified amount from the unswapped balance and modifies the position so that
   * it is executed in newSwaps swaps
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param positionId The position's id
   * @param amount Amount of funds to withdraw from the position
   * @param newSwaps The new amount of swaps
   * @param recipient The address to send tokens to
   */
  function reducePosition(
    IDCAHub hub,
    uint256 positionId,
    uint256 amount,
    uint32 newSwaps,
    address recipient
  ) external payable;

  /**
   * @notice Calls the hub and terminates the position and sends all unswapped and swapped balance to the specified recipients
   * @dev Meant to be used as part of a multicall
   * @param hub The address of the DCAHub
   * @param positionId The position's id
   * @param recipientUnswapped The address to withdraw unswapped tokens to
   * @param recipientSwapped The address to withdraw swapped tokens to
   * @return unswapped The unswapped balance sent to `recipientUnswapped`
   * @return swapped The swapped balance sent to `recipientSwapped`
   */
  function terminate(
    IDCAHub hub,
    uint256 positionId,
    address recipientUnswapped,
    address recipientSwapped
  ) external payable returns (uint256 unswapped, uint256 swapped);

  /**
   * @notice Calls the permission manager and sets multiple permissions via signature
   * @param permissionManager The address of the permission manager
   * @param permissions The permissions to set
   * @param deadline The deadline timestamp by which the call must be mined for the approve to work
   * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function multiPermissionPermit(
    IDCAPermissionManager permissionManager,
    IDCAPermissionManager.PositionPermissions[] calldata permissions,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;

  /**
   * @notice Calls the permission manager and sets permissions via signature
   * @param permissionManager The address of the permission manager
   * @param permissions The permissions to set
   * @param tokenId The token's id
   * @param deadline The deadline timestamp by which the call must be mined for the approve to work
   * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function permissionPermit(
    IDCAPermissionManager permissionManager,
    IDCAPermissionManager.PermissionSet[] calldata permissions,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable;
}

interface IDCAHubCompanion is IDCAHubCompanionLibrariesHandler, IDCAHubCompanionHubProxyHandler {}