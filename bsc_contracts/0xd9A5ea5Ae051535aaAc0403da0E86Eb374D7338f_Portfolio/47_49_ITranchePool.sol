// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import { IPortfolio } from "./IPortfolio.sol";
import { IDepositController } from "./IDepositController.sol";
import { IWithdrawController } from "./IWithdrawController.sol";
import { IERC4626Upgradeable } from "openzeppelin-contracts-upgradeable/contracts/interfaces/IERC4626Upgradeable.sol";

interface ITranchePool is IERC4626Upgradeable {
    error PortfolioAlreadySet();
    error NotPortfolio();
    error PortfolioPaused();
    error MaxDepositExceeded();
    error MaxMintExceeded();
    error MaxWithdrawExceeded();
    error MaxRedeemExceeded();
    error InsufficientAllowance();

    event DepositControllerChanged(IDepositController indexed controller);
    event DepositFeePaid(address indexed receiver, uint256 fee);

    event WithdrawControllerChanged(IWithdrawController indexed controller);
    event WithdrawFeePaid(address indexed receiver, uint256 fee);

    event CeilingChanged(uint256 newCeiling);

    /// @notice the associated portfolio for this tranche pool
    /// @return portfolio The associated portfolio
    function portfolio() external view returns (IPortfolio portfolio);

    /// @notice the ceiling for this tranche pool
    /// @return ceiling The ceiling value
    function ceiling() external view returns (uint256 ceiling);

    /// @notice available liquidity tracked by the token balance tracker
    /// @return The available liquidity
    function availableLiquidity() external view returns (uint256);

    /// @notice the waterfall index for this tranche pool. 0 is equity and 1 is senior
    /// @return waterfallIndex The waterfall index
    function waterfallIndex() external view returns (uint256 waterfallIndex);

    /// @notice Converts a given amount of assets to shares (rounded up)
    /// @param assets The amount of assets to convert
    /// @return shares The equivalent amount of shares
    function convertToSharesCeil(uint256 assets) external view returns (uint256 shares);

    /// @notice Converts a given amount of shares to assets (rounded up)
    /// @param shares The amount of shares to convert
    /// @return assets The equivalent amount of assets
    function convertToAssetsCeil(uint256 shares) external view returns (uint256 assets);

    /// @notice Sets the portfolio for this tranche pool
    /// @param _portfolio The new portfolio to set
    /// @custom:role - manager
    function setPortfolio(IPortfolio _portfolio) external;

    /// @notice Sets the deposit controller for this tranche pool
    /// @param newController The new deposit controller to set
    /// @custom:role - manager
    function setDepositController(IDepositController newController) external;

    /// @notice Sets the withdraw controller for this tranche pool
    /// @param newController The new withdraw controller to set
    /// @custom:role - manager
    function setWithdrawController(IWithdrawController newController) external;

    /// @notice Sets the ceiling for this tranche pool
    /// @param newCeiling The new ceiling to set
    /// @custom:role - manager
    function setCeiling(uint256 newCeiling) external;

    /// @notice Called when the portfolio starts
    /// @return The balance of the tranche pool
    function onPortfolioStart() external returns (uint256);

    /// @notice Increases the token balance of the tranche pool by the given amount
    /// @param amount The amount to increase the token balance by
    function increaseTokenBalance(uint256 amount) external;
}