// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Libs
import { ILiquidatorVault } from "../../interfaces/ILiquidatorVault.sol";
import { ImmutableModule } from "../../shared/ImmutableModule.sol";

/**
 * @title   Mock 3Crv vault for testing the Liquidator.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-10-17
 */
contract Mock3CrvReverseLiquidatorVault is ILiquidatorVault, ImmutableModule {
    using SafeERC20 for IERC20;

    // Reward tokens
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // Donated tokens
    address public CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    /// @notice Token that the liquidator sells DAI, USDC or USDT rewards for.
    address internal donateToken_;
    address public immutable liquidator;

    event DonateTokenUpdated(address token);

    /**
     * @param _nexus        Address of the Nexus contract that resolves protocol modules and roles.
     * @param _donateToken  Address of the token the rewards will be swapped for. This must be a Curve 3Pool asset (DAI, USDC or USDT).
     */
    constructor(
        address _nexus,
        address _donateToken,
        address _liquidator
    ) ImmutableModule(_nexus) {
        _setDonateToken(_donateToken);
        liquidator = _liquidator;

        _resetAllowances();
    }

    /**
     * Collects reward tokens from underlying platforms or vaults to this vault and
     * reports to the caller the amount of tokens now held by the vault.
     * This can be called by anyone but it used by the Liquidator to transfer the
     * rewards tokens from this vault to the liquidator.
     *
     * @param rewardTokens_ Array of reward tokens that were collected.
     * @param rewards The amount of reward tokens that were collected.
     * @param donateTokens The token the Liquidator swaps the reward tokens to.
     */
    function collectRewards()
        external
        virtual
        override
        returns (
            address[] memory rewardTokens_,
            uint256[] memory rewards,
            address[] memory donateTokens
        )
    {
        rewardTokens_ = new address[](3);
        rewards = new uint256[](3);
        donateTokens = new address[](3);

        rewardTokens_[0] = DAI;
        rewards[0] = IERC20(DAI).balanceOf(address(this));
        donateTokens[0] = donateToken_;

        rewardTokens_[1] = USDC;
        rewards[1] = IERC20(USDC).balanceOf(address(this));
        donateTokens[1] = donateToken_;

        rewardTokens_[2] = USDT;
        rewards[2] = IERC20(USDT).balanceOf(address(this));
        donateTokens[2] = donateToken_;
    }

    /**
     * @notice Returns all reward tokens address added to the vault.
     */
    function rewardTokens() external pure override returns (address[] memory rewardTokens_) {
        rewardTokens_ = new address[](3);
        rewardTokens_[0] = DAI;
        rewardTokens_[1] = USDC;
        rewardTokens_[2] = USDT;
    }

    /**
     * @notice Returns the token that rewards must be swapped to before donating back to the vault.
     * @return token The address of the token that reward tokens are swapped for.
     */
    function donateToken(address) external view override returns (address token) {
        token = donateToken_;
    }

    /**
     * @notice Adds tokens to the vault.
     * @param __donateToken  The address of the 3Pool token being donated (DAI, USDC or USDT).
     * @param amount         The amount of tokens being donated.
     */
    function donate(address __donateToken, uint256 amount) external override {
        require(__donateToken == CRV || __donateToken == CVX, "invalid donate token");

        IERC20(__donateToken).safeTransfer(msg.sender, amount);
    }

    /// @notice Reset allowances in the case the keeper is changed in the Nexus.
    function resetAllowances() external onlyKeeperOrGovernor {
        _resetAllowances();
    }

    function _resetAllowances() internal {
        address keeper = _keeper();

        // reward tokens to liquidator
        IERC20(DAI).safeApprove(liquidator, type(uint256).max);
        IERC20(USDC).safeApprove(liquidator, type(uint256).max);
        IERC20(USDT).safeApprove(liquidator, type(uint256).max);

        // reward tokens to keeper
        IERC20(DAI).safeApprove(keeper, type(uint256).max);
        IERC20(USDC).safeApprove(keeper, type(uint256).max);
        IERC20(USDT).safeApprove(keeper, type(uint256).max);
        // donated tokens to keeper
        IERC20(CRV).safeApprove(keeper, type(uint256).max);
        IERC20(CVX).safeApprove(keeper, type(uint256).max);
    }

    /***************************************
                    Vault Admin
    ****************************************/

    /// @dev Sets the token the rewards are swapped for and donated back to the vault.
    function _setDonateToken(address _donateToken) internal {
        require(_donateToken == CRV || _donateToken == CVX, "invalid donate token");
        donateToken_ = _donateToken;

        emit DonateTokenUpdated(_donateToken);
    }

    /**
     * @notice  Vault manager or governor sets the token the rewards are swapped for and donated back to the vault.
     * @param _donateToken the address of either CRV or CVX.
     */
    function setDonateToken(address _donateToken) external onlyKeeperOrGovernor {
        _setDonateToken(_donateToken);
    }
}