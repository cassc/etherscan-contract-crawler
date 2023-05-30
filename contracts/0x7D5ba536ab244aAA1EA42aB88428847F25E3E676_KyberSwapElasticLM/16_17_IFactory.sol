// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/// @title KyberSwap v2 factory
/// @notice Deploys KyberSwap v2 pools and manages control over government fees
interface IFactory {
  /// @notice Emitted when a pool is created
  /// @param token0 First pool token by address sort order
  /// @param token1 Second pool token by address sort order
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @param tickDistance Minimum number of ticks between initialized ticks
  /// @param pool The address of the created pool
  event PoolCreated(
    address indexed token0,
    address indexed token1,
    uint16 indexed swapFeeBps,
    int24 tickDistance,
    address pool
  );

  /// @notice Emitted when a new fee is enabled for pool creation via the factory
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @param tickDistance Minimum number of ticks between initialized ticks for pools created with the given fee
  event SwapFeeEnabled(uint16 indexed swapFeeBps, int24 indexed tickDistance);

  /// @notice Emitted when vesting period changes
  /// @param vestingPeriod The maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  event VestingPeriodUpdated(uint32 vestingPeriod);

  /// @notice Emitted when configMaster changes
  /// @param oldConfigMaster configMaster before the update
  /// @param newConfigMaster configMaster after the update
  event ConfigMasterUpdated(address oldConfigMaster, address newConfigMaster);

  /// @notice Emitted when fee configuration changes
  /// @param feeTo Recipient of government fees
  /// @param governmentFeeBps Fee amount, in basis points,
  /// to be collected out of the fee charged for a pool swap
  event FeeConfigurationUpdated(address feeTo, uint16 governmentFeeBps);

  /// @notice Emitted when whitelist feature is enabled
  event WhitelistEnabled();

  /// @notice Emitted when whitelist feature is disabled
  event WhitelistDisabled();

  /// @notice Returns the maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  function vestingPeriod() external view returns (uint32);

  /// @notice Returns the tick distance for a specified fee.
  /// @dev Once added, cannot be updated or removed.
  /// @param swapFeeBps Swap fee, in basis points.
  /// @return The tick distance. Returns 0 if fee has not been added.
  function feeAmountTickDistance(uint16 swapFeeBps) external view returns (int24);

  /// @notice Returns the address which can update the fee configuration
  function configMaster() external view returns (address);

  /// @notice Returns the keccak256 hash of the Pool creation code
  /// This is used for pre-computation of pool addresses
  function poolInitHash() external view returns (bytes32);

  /// @notice Fetches the recipient of government fees
  /// and current government fee charged in basis points
  function feeConfiguration() external view returns (address _feeTo, uint16 _governmentFeeBps);

  /// @notice Returns the status of whitelisting feature of NFT managers
  /// If true, anyone can mint liquidity tokens
  /// Otherwise, only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function whitelistDisabled() external view returns (bool);

  //// @notice Returns all whitelisted NFT managers
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function getWhitelistedNFTManagers() external view returns (address[] memory);

  /// @notice Checks if sender is a whitelisted NFT manager
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  /// @param sender address to be checked
  /// @return true if sender is a whistelisted NFT manager, false otherwise
  function isWhitelistedNFTManager(address sender) external view returns (bool);

  /// @notice Returns the pool address for a given pair of tokens and a swap fee
  /// @dev Token order does not matter
  /// @param tokenA Contract address of either token0 or token1
  /// @param tokenB Contract address of the other token
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @return pool The pool address. Returns null address if it does not exist
  function getPool(
    address tokenA,
    address tokenB,
    uint16 swapFeeBps
  ) external view returns (address pool);

  /// @notice Fetch parameters to be used for pool creation
  /// @dev Called by the pool constructor to fetch the parameters of the pool
  /// @return factory The factory address
  /// @return token0 First pool token by address sort order
  /// @return token1 Second pool token by address sort order
  /// @return swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @return tickDistance Minimum number of ticks between initialized ticks
  function parameters()
    external
    view
    returns (
      address factory,
      address token0,
      address token1,
      uint16 swapFeeBps,
      int24 tickDistance
    );

  /// @notice Creates a pool for the given two tokens and fee
  /// @param tokenA One of the two tokens in the desired pool
  /// @param tokenB The other of the two tokens in the desired pool
  /// @param swapFeeBps Desired swap fee for the pool, in basis points
  /// @dev Token order does not matter. tickDistance is determined from the fee.
  /// Call will revert under any of these conditions:
  ///     1) pool already exists
  ///     2) invalid swap fee
  ///     3) invalid token arguments
  /// @return pool The address of the newly created pool
  function createPool(
    address tokenA,
    address tokenB,
    uint16 swapFeeBps
  ) external returns (address pool);

  /// @notice Enables a fee amount with the given tickDistance
  /// @dev Fee amounts may never be removed once enabled
  /// @param swapFeeBps The fee amount to enable, in basis points
  /// @param tickDistance The distance between ticks to be enforced for all pools created with the given fee amount
  function enableSwapFee(uint16 swapFeeBps, int24 tickDistance) external;

  /// @notice Updates the address which can update the fee configuration
  /// @dev Must be called by the current configMaster
  function updateConfigMaster(address) external;

  /// @notice Updates the vesting period
  /// @dev Must be called by the current configMaster
  function updateVestingPeriod(uint32) external;

  /// @notice Updates the address receiving government fees and fee quantity
  /// @dev Only configMaster is able to perform the update
  /// @param feeTo Address to receive government fees collected from pools
  /// @param governmentFeeBps Fee amount, in basis points,
  /// to be collected out of the fee charged for a pool swap
  function updateFeeConfiguration(address feeTo, uint16 governmentFeeBps) external;

  /// @notice Enables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function enableWhitelist() external;

  /// @notice Disables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function disableWhitelist() external;
}