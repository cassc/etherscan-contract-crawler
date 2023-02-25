// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IBedRockCore {
    struct SafeConfig {
        uint256 expectPrice;
        address priceProvider;
        uint256 feeFreePeriod;
        uint256 hackThreshold;
        uint256 claimLockPeriod;
        uint256 depositFeePercent;
        uint256 claimFeePercent;
        uint256 poolSavingPercent;
        uint256 apy;
    }

    struct SafeState {
        bool active;
        uint256 totalSupply;
    }

    function isActive(address token) external view returns (bool);

    /**
     * @notice create a newSafe and register it to controller
     * @param token address of stableCoin, must inherit of IERC20
     * @param expectPrice expectPrice
     * @param priceProvider address of price provider, must inherit of IPriceProvider. if zero, it generates MockPriceProvider
     */
    function createSafe(
        address token,
        uint256 expectPrice,
        address priceProvider
    ) external;

    /**
     * @notice activate/deactivate safe
     * @param token address of token to remove, should be added before to safeMapping. must inherit of IBedRockSafe
     * @param flag true => activate, false => deactivate
     */
    function activateSafe(address token, bool flag) external;

    function getSafeConfig(address token) external view returns (SafeConfig memory);

    function updateSafeConfig(address token, SafeConfig memory safeConfig) external;

    function swap(uint256 amount) external;

    /** /// to add constraint
     * @param token address of token to withdraw
     * @notice user deposit his asset
     * @param amount amount to deposit
     */
    function deposit(address token, uint256 amount) external;

    /**
     * @notice user request to withdraw his asset
     * @param token address of token to withdraw
     * @param amount amount to withdraw
     * @param delay delay period in hours
     */
    function requestWithdraw(
        address token,
        uint256 amount,
        uint256 delay
    ) external;

    function requestClaim(address token, uint256 amount) external;

    function withdrawProceed(uint256 id) external;

    function releaseLockedAsset(uint256 id) external;

    function checkAllRelease() external;

    function withdrawFeePercent(address token, uint256 delay) external view returns (uint256);

    function claimLockPercent(address token) external view returns (uint256);

    function safeBalanceOf(address token, address user) external view returns (uint256);

    function safeTotalSupply(address token) external view returns (uint256);

    function isTokenHacked(address token) external view returns (bool);

    event SafeCreated(address indexed token, uint256 expectPrice, address priceProvider);
    event SafeActivated(address indexed token, bool flag);
    event ClaimProceeded(address indexed token, address claimer, uint256 claimAmount, uint256 totalPaid);

    event Paid(address indexed token, address indexed tokenForPay, address indexed claimer, uint256 payAmount);
    event Deposited(address indexed token, address indexed user, uint256 amount);
    event WithdrawRequested(
        uint256 indexed id,
        address indexed token,
        address indexed user,
        uint256 requestAmount,
        uint256 proceedAmount,
        uint256 delay
    );
    event WithdrawProceeded(uint256 indexed id);
    event AssetLocked(
        uint256 indexed id,
        address indexed token,
        address indexed user,
        uint256 requestAmount,
        uint256 lockedAmount,
        uint256 unlockTime
    );
    event LockedAssetReleased(uint256 indexed id);

    error Controller__No_Such_Safe(address);
}