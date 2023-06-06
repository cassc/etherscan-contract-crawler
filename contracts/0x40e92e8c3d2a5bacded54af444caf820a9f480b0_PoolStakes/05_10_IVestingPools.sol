// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PoolParams } from "./Types.sol";

interface IVestingPools {
    /**
     * @notice Returns Token address.
     */
    function token() external view returns (address);

    /**
     * @notice Returns the wallet address of the specified pool.
     */
    function getWallet(uint256 poolId) external view returns (address);

    /**
     * @notice Returns parameters of the specified pool.
     */
    function getPool(uint256 poolId) external view returns (PoolParams memory);

    /**
     * @notice Returns the amount that may be vested now from the given pool.
     */
    function releasableAmount(uint256 poolId) external view returns (uint256);

    /**
     * @notice Returns the amount that has been vested from the given pool
     */
    function vestedAmount(uint256 poolId) external view returns (uint256);

    /**
     * @notice Vests the specified amount from the given pool to the pool wallet.
     * If the amount is zero, it vests the entire "releasable" amount.
     * @dev Pool wallet may call only.
     * @return released - Amount released.
     */
    function release(uint256 poolId, uint256 amount)
        external
        returns (uint256 released);

    /**
     * @notice Vests the specified amount from the given pool to the given address.
     * If the amount is zero, it vests the entire "releasable" amount.
     * @dev Pool wallet may call only.
     * @return released - Amount released.
     */
    function releaseTo(
        uint256 poolId,
        address account,
        uint256 amount
    ) external returns (uint256 released);

    /**
     * @notice Updates the wallet for the given pool.
     * @dev (Current) wallet may call only.
     */
    function updatePoolWallet(uint256 poolId, address newWallet) external;

    /**
     * @notice Adds new vesting pools with given wallets and parameters.
     * @dev Owner may call only.
     */
    function addVestingPools(
        address[] memory wallets,
        PoolParams[] memory params
    ) external;

    /**
     * @notice Update `start` and `duration` for the given pool.
     * @param start - new (UNIX) time vesting starts at
     * @param vestingDays - new period in days, when vesting lasts
     * @dev Owner may call only.
     */
    function updatePoolTime(
        uint256 poolId,
        uint32 start,
        uint16 vestingDays
    ) external;

    /// @notice Emitted on an amount vesting.
    event Released(uint256 indexed poolId, address to, uint256 amount);

    /// @notice Emitted on a pool wallet update.
    event WalletUpdated(uint256 indexedpoolId, address indexed newWallet);

    /// @notice Emitted on a new pool added.
    event PoolAdded(
        uint256 indexed poolId,
        address indexed wallet,
        uint256 allocation
    );

    /// @notice Emitted on a pool params update.
    event PoolUpdated(
        uint256 indexed poolId,
        uint256 start,
        uint256 vestingDays
    );
}