// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@mean-finance/oracles/solidity/interfaces/ITokenPriceOracle.sol';
import './IDCAPermissionManager.sol';

/**
 * @title The interface for all state related queries
 * @notice These methods allow users to read the hubs's current values
 */
interface IDCAHubParameters {
  /**
   * @notice Returns how much will the amount to swap differ from the previous swap. f.e. if the returned value is -100, then the amount to swap will be 100 less than the swap just before it
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA One of the pair's token
   * @param tokenB The other of the pair's token
   * @param swapIntervalMask The byte representation of the swap interval to check
   * @param swapNumber The swap number to check
   * @return swapDeltaAToB How much less of token A will the following swap require
   * @return swapDeltaBToA How much less of token B will the following swap require
   */
  function swapAmountDelta(
    address tokenA,
    address tokenB,
    bytes1 swapIntervalMask,
    uint32 swapNumber
  ) external view returns (uint128 swapDeltaAToB, uint128 swapDeltaBToA);

  /**
   * @notice Returns the sum of the ratios reported in all swaps executed until the given swap number
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA One of the pair's token
   * @param tokenB The other of the pair's token
   * @param swapIntervalMask The byte representation of the swap interval to check
   * @param swapNumber The swap number to check
   * @return accumRatioAToB The sum of all ratios from A to B
   * @return accumRatioBToA The sum of all ratios from B to A
   */
  function accumRatio(
    address tokenA,
    address tokenB,
    bytes1 swapIntervalMask,
    uint32 swapNumber
  ) external view returns (uint256 accumRatioAToB, uint256 accumRatioBToA);

  /**
   * @notice Returns swapping information about a specific pair
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA One of the pair's token
   * @param tokenB The other of the pair's token
   * @param swapIntervalMask The byte representation of the swap interval to check
   * @return performedSwaps How many swaps have been executed
   * @return nextAmountToSwapAToB How much of token A will be swapped on the next swap
   * @return lastSwappedAt Timestamp of the last swap
   * @return nextAmountToSwapBToA How much of token B will be swapped on the next swap
   */
  function swapData(
    address tokenA,
    address tokenB,
    bytes1 swapIntervalMask
  )
    external
    view
    returns (
      uint32 performedSwaps,
      uint224 nextAmountToSwapAToB,
      uint32 lastSwappedAt,
      uint224 nextAmountToSwapBToA
    );

  /**
   * @notice Returns the byte representation of the set of actice swap intervals for the given pair
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA The smaller of the pair's token
   * @param tokenB The other of the pair's token
   * @return The byte representation of the set of actice swap intervals
   */
  function activeSwapIntervals(address tokenA, address tokenB) external view returns (bytes1);

  /**
   * @notice Returns how much of the hub's token balance belongs to the platform
   * @param token The token to check
   * @return The amount that belongs to the platform
   */
  function platformBalance(address token) external view returns (uint256);
}

/**
 * @title The interface for all position related matters
 * @notice These methods allow users to create, modify and terminate their positions
 */
interface IDCAHubPositionHandler {
  /// @notice The position of a certain user
  struct UserPosition {
    // The token that the user deposited and will be swapped in exchange for "to"
    IERC20Metadata from;
    // The token that the user will get in exchange for their "from" tokens in each swap
    IERC20Metadata to;
    // How frequently the position's swaps should be executed
    uint32 swapInterval;
    // How many swaps were executed since deposit, last modification, or last withdraw
    uint32 swapsExecuted;
    // How many "to" tokens can currently be withdrawn
    uint256 swapped;
    // How many swaps left the position has to execute
    uint32 swapsLeft;
    // How many "from" tokens there are left to swap
    uint256 remaining;
    // How many "from" tokens need to be traded in each swap
    uint120 rate;
  }

  /// @notice A list of positions that all have the same `to` token
  struct PositionSet {
    // The `to` token
    address token;
    // The position ids
    uint256[] positionIds;
  }

  /**
   * @notice Emitted when a position is terminated
   * @param user The address of the user that terminated the position
   * @param recipientUnswapped The address of the user that will receive the unswapped tokens
   * @param recipientSwapped The address of the user that will receive the swapped tokens
   * @param positionId The id of the position that was terminated
   * @param returnedUnswapped How many "from" tokens were returned to the caller
   * @param returnedSwapped How many "to" tokens were returned to the caller
   */
  event Terminated(
    address indexed user,
    address indexed recipientUnswapped,
    address indexed recipientSwapped,
    uint256 positionId,
    uint256 returnedUnswapped,
    uint256 returnedSwapped
  );

  /**
   * @notice Emitted when a position is created
   * @param depositor The address of the user that creates the position
   * @param owner The address of the user that will own the position
   * @param positionId The id of the position that was created
   * @param fromToken The address of the "from" token
   * @param toToken The address of the "to" token
   * @param swapInterval How frequently the position's swaps should be executed
   * @param rate How many "from" tokens need to be traded in each swap
   * @param startingSwap The number of the swap when the position will be executed for the first time
   * @param lastSwap The number of the swap when the position will be executed for the last time
   * @param permissions The permissions defined for the position
   */
  event Deposited(
    address indexed depositor,
    address indexed owner,
    uint256 positionId,
    address fromToken,
    address toToken,
    uint32 swapInterval,
    uint120 rate,
    uint32 startingSwap,
    uint32 lastSwap,
    IDCAPermissionManager.PermissionSet[] permissions
  );

  /**
   * @notice Emitted when a position is created and extra data is provided
   * @param positionId The id of the position that was created
   * @param data The extra data that was provided
   */
  event Miscellaneous(uint256 positionId, bytes data);

  /**
   * @notice Emitted when a user withdraws all swapped tokens from a position
   * @param withdrawer The address of the user that executed the withdraw
   * @param recipient The address of the user that will receive the withdrawn tokens
   * @param positionId The id of the position that was affected
   * @param token The address of the withdrawn tokens. It's the same as the position's "to" token
   * @param amount The amount that was withdrawn
   */
  event Withdrew(address indexed withdrawer, address indexed recipient, uint256 positionId, address token, uint256 amount);

  /**
   * @notice Emitted when a user withdraws all swapped tokens from many positions
   * @param withdrawer The address of the user that executed the withdraws
   * @param recipient The address of the user that will receive the withdrawn tokens
   * @param positions The positions to withdraw from
   * @param withdrew The total amount that was withdrawn from each token
   */
  event WithdrewMany(address indexed withdrawer, address indexed recipient, PositionSet[] positions, uint256[] withdrew);

  /**
   * @notice Emitted when a position is modified
   * @param user The address of the user that modified the position
   * @param positionId The id of the position that was modified
   * @param rate How many "from" tokens need to be traded in each swap
   * @param startingSwap The number of the swap when the position will be executed for the first time
   * @param lastSwap The number of the swap when the position will be executed for the last time
   */
  event Modified(address indexed user, uint256 positionId, uint120 rate, uint32 startingSwap, uint32 lastSwap);

  /// @notice Thrown when a user tries to create a position with the same `from` & `to`
  error InvalidToken();

  /// @notice Thrown when a user tries to create a position with a swap interval that is not allowed
  error IntervalNotAllowed();

  /// @notice Thrown when a user tries operate on a position that doesn't exist (it might have been already terminated)
  error InvalidPosition();

  /// @notice Thrown when a user tries operate on a position that they don't have access to
  error UnauthorizedCaller();

  /// @notice Thrown when a user tries to create a position with zero swaps
  error ZeroSwaps();

  /// @notice Thrown when a user tries to create a position with zero funds
  error ZeroAmount();

  /// @notice Thrown when a user tries to withdraw a position whose `to` token doesn't match the specified one
  error PositionDoesNotMatchToken();

  /// @notice Thrown when a user tries create or modify a position with an amount too big
  error AmountTooBig();

  /**
   * @notice Returns the permission manager contract
   * @return The contract itself
   */
  function permissionManager() external view returns (IDCAPermissionManager);

  /**
   * @notice Returns total created positions
   * @return The total created positions
   */
  function totalCreatedPositions() external view returns (uint256);

  /**
   * @notice Returns a user position
   * @param positionId The id of the position
   * @return position The position itself
   */
  function userPosition(uint256 positionId) external view returns (UserPosition memory position);

  /**
   * @notice Creates a new position
   * @dev Will revert:
   *      - With ZeroAddress if from, to or owner are zero
   *      - With InvalidToken if from == to
   *      - With ZeroAmount if amount is zero
   *      - With AmountTooBig if amount is too big
   *      - With ZeroSwaps if amountOfSwaps is zero
   *      - With IntervalNotAllowed if swapInterval is not allowed
   * @param from The address of the "from" token
   * @param to The address of the "to" token
   * @param amount How many "from" tokens will be swapped in total
   * @param amountOfSwaps How many swaps to execute for this position
   * @param swapInterval How frequently the position's swaps should be executed
   * @param owner The address of the owner of the position being created
   * @param permissions Extra permissions to add to the position. Can be empty
   * @return positionId The id of the created position
   */
  function deposit(
    address from,
    address to,
    uint256 amount,
    uint32 amountOfSwaps,
    uint32 swapInterval,
    address owner,
    IDCAPermissionManager.PermissionSet[] calldata permissions
  ) external returns (uint256 positionId);

  /**
   * @notice Creates a new position
   * @dev Will revert:
   *      - With ZeroAddress if from, to or owner are zero
   *      - With InvalidToken if from == to
   *      - With ZeroAmount if amount is zero
   *      - With AmountTooBig if amount is too big
   *      - With ZeroSwaps if amountOfSwaps is zero
   *      - With IntervalNotAllowed if swapInterval is not allowed
   * @param from The address of the "from" token
   * @param to The address of the "to" token
   * @param amount How many "from" tokens will be swapped in total
   * @param amountOfSwaps How many swaps to execute for this position
   * @param swapInterval How frequently the position's swaps should be executed
   * @param owner The address of the owner of the position being created
   * @param permissions Extra permissions to add to the position. Can be empty
   * @param miscellaneous Bytes that will be emitted, and associated with the position
   * @return positionId The id of the created position
   */
  function deposit(
    address from,
    address to,
    uint256 amount,
    uint32 amountOfSwaps,
    uint32 swapInterval,
    address owner,
    IDCAPermissionManager.PermissionSet[] calldata permissions,
    bytes calldata miscellaneous
  ) external returns (uint256 positionId);

  /**
   * @notice Withdraws all swapped tokens from a position to a recipient
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With ZeroAddress if recipient is zero
   * @param positionId The position's id
   * @param recipient The address to withdraw swapped tokens to
   * @return swapped How much was withdrawn
   */
  function withdrawSwapped(uint256 positionId, address recipient) external returns (uint256 swapped);

  /**
   * @notice Withdraws all swapped tokens from multiple positions
   * @dev Will revert:
   *      - With InvalidPosition if any of the position ids are invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position to any of the given positions
   *      - With ZeroAddress if recipient is zero
   *      - With PositionDoesNotMatchToken if any of the positions do not match the token in their position set
   * @param positions A list positions, grouped by `to` token
   * @param recipient The address to withdraw swapped tokens to
   * @return withdrawn How much was withdrawn for each token
   */
  function withdrawSwappedMany(PositionSet[] calldata positions, address recipient) external returns (uint256[] memory withdrawn);

  /**
   * @notice Takes the unswapped balance, adds the new deposited funds and modifies the position so that
   * it is executed in newSwaps swaps
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With AmountTooBig if amount is too big
   * @param positionId The position's id
   * @param amount Amount of funds to add to the position
   * @param newSwaps The new amount of swaps
   */
  function increasePosition(
    uint256 positionId,
    uint256 amount,
    uint32 newSwaps
  ) external;

  /**
   * @notice Withdraws the specified amount from the unswapped balance and modifies the position so that
   * it is executed in newSwaps swaps
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With ZeroSwaps if newSwaps is zero and amount is not the total unswapped balance
   * @param positionId The position's id
   * @param amount Amount of funds to withdraw from the position
   * @param newSwaps The new amount of swaps
   * @param recipient The address to send tokens to
   */
  function reducePosition(
    uint256 positionId,
    uint256 amount,
    uint32 newSwaps,
    address recipient
  ) external;

  /**
   * @notice Terminates the position and sends all unswapped and swapped balance to the specified recipients
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With ZeroAddress if recipientUnswapped or recipientSwapped is zero
   * @param positionId The position's id
   * @param recipientUnswapped The address to withdraw unswapped tokens to
   * @param recipientSwapped The address to withdraw swapped tokens to
   * @return unswapped The unswapped balance sent to `recipientUnswapped`
   * @return swapped The swapped balance sent to `recipientSwapped`
   */
  function terminate(
    uint256 positionId,
    address recipientUnswapped,
    address recipientSwapped
  ) external returns (uint256 unswapped, uint256 swapped);
}

/**
 * @title The interface for all swap related matters
 * @notice These methods allow users to get information about the next swap, and how to execute it
 */
interface IDCAHubSwapHandler {
  /// @notice Information about a swap
  struct SwapInfo {
    // The tokens involved in the swap
    TokenInSwap[] tokens;
    // The pairs involved in the swap
    PairInSwap[] pairs;
  }

  /// @notice Information about a token's role in a swap
  struct TokenInSwap {
    // The token's address
    address token;
    // How much will be given of this token as a reward
    uint256 reward;
    // How much of this token needs to be provided by swapper
    uint256 toProvide;
    // How much of this token will be paid to the platform
    uint256 platformFee;
  }

  /// @notice Information about a pair in a swap
  struct PairInSwap {
    // The address of one of the tokens
    address tokenA;
    // The address of the other token
    address tokenB;
    // The total amount of token A swapped in this pair
    uint256 totalAmountToSwapTokenA;
    // The total amount of token B swapped in this pair
    uint256 totalAmountToSwapTokenB;
    // How much is 1 unit of token A when converted to B
    uint256 ratioAToB;
    // How much is 1 unit of token B when converted to A
    uint256 ratioBToA;
    // The swap intervals involved in the swap, represented as a byte
    bytes1 intervalsInSwap;
  }

  /// @notice A pair of tokens, represented by their indexes in an array
  struct PairIndexes {
    // The index of the token A
    uint8 indexTokenA;
    // The index of the token B
    uint8 indexTokenB;
  }

  /**
   * @notice Emitted when a swap is executed
   * @param sender The address of the user that initiated the swap
   * @param rewardRecipient The address that received the reward
   * @param callbackHandler The address that executed the callback
   * @param swapInformation All information related to the swap
   * @param borrowed How much was borrowed
   * @param fee The swap fee at the moment of the swap
   */
  event Swapped(
    address indexed sender,
    address indexed rewardRecipient,
    address indexed callbackHandler,
    SwapInfo swapInformation,
    uint256[] borrowed,
    uint32 fee
  );

  /// @notice Thrown when pairs indexes are not sorted correctly
  error InvalidPairs();

  /// @notice Thrown when trying to execute a swap, but there is nothing to swap
  error NoSwapsToExecute();

  /**
   * @notice Returns all information related to the next swap
   * @dev Will revert with:
   *      - With InvalidTokens if tokens are not sorted, or if there are duplicates
   *      - With InvalidPairs if pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
   * @param tokens The tokens involved in the next swap
   * @param pairs The pairs that you want to swap. Each element of the list points to the index of the token in the tokens array
   * @param calculatePrivilegedAvailability Some accounts get privileged availability and can execute swaps before others. This flag provides
   *        the possibility to calculate the next swap information for privileged and non-privileged accounts
   * @param oracleData Bytes to send to the oracle when executing a quote
   * @return swapInformation The information about the next swap
   */
  function getNextSwapInfo(
    address[] calldata tokens,
    PairIndexes[] calldata pairs,
    bool calculatePrivilegedAvailability,
    bytes calldata oracleData
  ) external view returns (SwapInfo memory swapInformation);

  /**
   * @notice Executes a flash swap
   * @dev Will revert with:
   *      - With InvalidTokens if tokens are not sorted, or if there are duplicates
   *      - With InvalidPairs if pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
   *      - With Paused if swaps are paused by protocol
   *      - With NoSwapsToExecute if there are no swaps to execute for the given pairs
   *      - With LiquidityNotReturned if the required tokens were not back during the callback
   * @param tokens The tokens involved in the next swap
   * @param pairsToSwap The pairs that you want to swap. Each element of the list points to the index of the token in the tokens array
   * @param rewardRecipient The address to send the reward to
   * @param callbackHandler Address to call for callback (and send the borrowed tokens to)
   * @param borrow How much to borrow of each of the tokens in tokens. The amount must match the position of the token in the tokens array
   * @param callbackData Bytes to send to the caller during the callback
   * @param oracleData Bytes to send to the oracle when executing a quote
   * @return Information about the executed swap
   */
  function swap(
    address[] calldata tokens,
    PairIndexes[] calldata pairsToSwap,
    address rewardRecipient,
    address callbackHandler,
    uint256[] calldata borrow,
    bytes calldata callbackData,
    bytes calldata oracleData
  ) external returns (SwapInfo memory);
}

/**
 * @title The interface for handling all configuration
 * @notice This contract will manage configuration that affects all pairs, swappers, etc
 */
interface IDCAHubConfigHandler {
  /**
   * @notice Emitted when a new oracle is set
   * @param oracle The new oracle contract
   */
  event OracleSet(ITokenPriceOracle oracle);

  /**
   * @notice Emitted when a new swap fee is set
   * @param feeSet The new swap fee
   */
  event SwapFeeSet(uint32 feeSet);

  /**
   * @notice Emitted when new swap intervals are allowed
   * @param swapIntervals The new swap intervals
   */
  event SwapIntervalsAllowed(uint32[] swapIntervals);

  /**
   * @notice Emitted when some swap intervals are no longer allowed
   * @param swapIntervals The swap intervals that are no longer allowed
   */
  event SwapIntervalsForbidden(uint32[] swapIntervals);

  /**
   * @notice Emitted when a new platform fee ratio is set
   * @param platformFeeRatio The new platform fee ratio
   */
  event PlatformFeeRatioSet(uint16 platformFeeRatio);

  /**
   * @notice Emitted when allowed states of tokens are updated
   * @param tokens Array of updated tokens
   * @param allowed Array of new allow state per token were allowed[i] is the updated state of tokens[i]
   */
  event TokensAllowedUpdated(address[] tokens, bool[] allowed);

  /// @notice Thrown when trying to interact with an unallowed token
  error UnallowedToken();

  /// @notice Thrown when set allowed tokens input is not valid
  error InvalidAllowedTokensInput();

  /// @notice Thrown when trying to set a fee higher than the maximum allowed
  error HighFee();

  /// @notice Thrown when trying to set a fee that is not multiple of 100
  error InvalidFee();

  /// @notice Thrown when trying to set a fee ratio that is higher that the maximum allowed
  error HighPlatformFeeRatio();

  /**
   * @notice Returns the max fee ratio that can be set
   * @dev Cannot be modified
   * @return The maximum possible value
   */
  // solhint-disable-next-line func-name-mixedcase
  function MAX_PLATFORM_FEE_RATIO() external view returns (uint16);

  /**
   * @notice Returns the fee charged on swaps
   * @return swapFee The fee itself
   */
  function swapFee() external view returns (uint32 swapFee);

  /**
   * @notice Returns the price oracle contract
   * @return oracle The contract itself
   */
  function oracle() external view returns (ITokenPriceOracle oracle);

  /**
   * @notice Returns how much will the platform take from the fees collected in swaps
   * @return The current ratio
   */
  function platformFeeRatio() external view returns (uint16);

  /**
   * @notice Returns the max fee that can be set for swaps
   * @dev Cannot be modified
   * @return maxFee The maximum possible fee
   */
  // solhint-disable-next-line func-name-mixedcase
  function MAX_FEE() external view returns (uint32 maxFee);

  /**
   * @notice Returns a byte that represents allowed swap intervals
   * @return allowedSwapIntervals The allowed swap intervals
   */
  function allowedSwapIntervals() external view returns (bytes1 allowedSwapIntervals);

  /**
   * @notice Returns if a token is currently allowed or not
   * @return Allowed state of token
   */
  function allowedTokens(address token) external view returns (bool);

  /**
   * @notice Returns token's magnitude (10**decimals)
   * @return Stored magnitude for token
   */
  function tokenMagnitude(address token) external view returns (uint120);

  /**
   * @notice Returns whether swaps and deposits are currently paused
   * @return isPaused Whether swaps and deposits are currently paused
   */
  function paused() external view returns (bool isPaused);

  /**
   * @notice Sets a new swap fee
   * @dev Will revert with HighFee if the fee is higher than the maximum
   * @dev Will revert with InvalidFee if the fee is not multiple of 100
   * @param fee The new swap fee
   */
  function setSwapFee(uint32 fee) external;

  /**
   * @notice Sets a new price oracle
   * @dev Will revert with ZeroAddress if the zero address is passed
   * @param oracle The new oracle contract
   */
  function setOracle(ITokenPriceOracle oracle) external;

  /**
   * @notice Sets a new platform fee ratio
   * @dev Will revert with HighPlatformFeeRatio if given ratio is too high
   * @param platformFeeRatio The new ratio
   */
  function setPlatformFeeRatio(uint16 platformFeeRatio) external;

  /**
   * @notice Adds new swap intervals to the allowed list
   * @param swapIntervals The new swap intervals
   */
  function addSwapIntervalsToAllowedList(uint32[] calldata swapIntervals) external;

  /**
   * @notice Removes some swap intervals from the allowed list
   * @param swapIntervals The swap intervals to remove
   */
  function removeSwapIntervalsFromAllowedList(uint32[] calldata swapIntervals) external;

  /// @notice Pauses all swaps and deposits
  function pause() external;

  /// @notice Unpauses all swaps and deposits
  function unpause() external;
}

/**
 * @title The interface for handling platform related actions
 * @notice This contract will handle all actions that affect the platform in some way
 */
interface IDCAHubPlatformHandler {
  /**
   * @notice Emitted when someone withdraws from the paltform balance
   * @param sender The address of the user that initiated the withdraw
   * @param recipient The address that received the withdraw
   * @param amounts The tokens (and the amount) that were withdrawn
   */
  event WithdrewFromPlatform(address indexed sender, address indexed recipient, IDCAHub.AmountOfToken[] amounts);

  /**
   * @notice Withdraws tokens from the platform balance
   * @param amounts The amounts to withdraw
   * @param recipient The address that will receive the tokens
   */
  function withdrawFromPlatformBalance(IDCAHub.AmountOfToken[] calldata amounts, address recipient) external;
}

interface IDCAHub is IDCAHubParameters, IDCAHubConfigHandler, IDCAHubSwapHandler, IDCAHubPositionHandler, IDCAHubPlatformHandler {
  /// @notice Specifies an amount of a token. For example to determine how much to borrow from certain tokens
  struct AmountOfToken {
    // The tokens' address
    address token;
    // How much to borrow or withdraw of the specified token
    uint256 amount;
  }

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when the expected liquidity is not returned in flash swaps
  error LiquidityNotReturned();

  /// @notice Thrown when a list of token pairs is not sorted, or if there are duplicates
  error InvalidTokens();
}