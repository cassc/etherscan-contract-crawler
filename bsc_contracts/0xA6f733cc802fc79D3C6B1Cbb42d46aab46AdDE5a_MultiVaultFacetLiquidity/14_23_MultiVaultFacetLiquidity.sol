// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetLiquidity.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IMultiVaultToken.sol";

import "../../libraries/SafeERC20.sol";

import "../storage/MultiVaultStorage.sol";

import "../helpers/MultiVaultHelperReentrancyGuard.sol";
import "../helpers/MultiVaultHelperLiquidity.sol";
import "../helpers/MultiVaultHelperEmergency.sol";
import "../helpers/MultiVaultHelperFee.sol";
import "../helpers/MultiVaultHelperActors.sol";


contract MultiVaultFacetLiquidity is
    MultiVaultHelperEmergency,
    MultiVaultHelperReentrancyGuard,
    MultiVaultHelperLiquidity,
    MultiVaultHelperActors,
    MultiVaultHelperFee,
    IMultiVaultFacetLiquidity
{
    using SafeERC20 for IERC20;

    /// @notice The mint function transfers an asset into the protocol,
    /// which begins accumulating interest based on the current Supply Rate for the asset.
    /// @param token Underlying asset address
    /// @param amount The amount of the asset to be supplied, in units of the underlying asset
    function mint(
        address token,
        uint amount,
        address receiver
    ) external override onlyEmergencyDisabled nonReentrant {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        address lp;

        if (s.liquidity[token].activation == 0) {
            lp = _deployLPToken(token);
        } else {
            lp = _getLPToken(token);
        }

        uint lp_amount = _convertUnderlyingToLP(token, amount);

        s.liquidity[token].cash += amount;
        s.liquidity[token].supply += lp_amount;

        emit MintLiquidity(msg.sender, token, amount, lp_amount);

        IMultiVaultToken(lp).mint(receiver, amount);
    }

    /// @notice The redeem function converts a specified quantity of LP tokens
    /// into the underlying asset, and returns them to the user.
    /// @param token Underlying asset address
    /// @param amount The number of LP tokens to be redeemed
    function redeem(
        address token,
        uint amount,
        address receiver
    ) external override onlyEmergencyDisabled nonReentrant onlyActivatedLP(token) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        address lp = _getLPToken(token);

        IMultiVaultToken(lp).burn(msg.sender, amount);

        uint underlying_amount = _convertLPToUnderlying(token, amount);

        s.liquidity[token].cash -= underlying_amount;
        s.liquidity[token].supply -= amount;

        emit RedeemLiquidity(msg.sender, token, amount, underlying_amount);

        IERC20(token).safeTransfer(receiver, underlying_amount);
    }

    /// @notice Each LP token is convertible into an ever increasing quantity of the underlying asset,
    /// as interest accrues in the market.
    /// @param token Underlying token address
    function exchangeRateCurrent(
        address token
    ) external view override returns (uint) {
        return _exchangeRateCurrent(token);
    }

    /// @notice Cash is the amount of underlying balance owned by this LP token contract.
    /// @param token The address of underlying asset
    /// @return The quantity of underlying asset owned by the contract
    function getCash(
        address token
    ) external view override returns (uint) {
        return _getCash(token);
    }

    /// @notice Get LP token address by the address of the underlying asset
    /// @param token The address of underlying asset
    /// @return The address of LP token
    function getLPToken(
        address token
    ) external view override returns (address) {
        return _getLPToken(token);
    }

    function setTokenInterest(
        address token,
        uint interest
    ) external override onlyGovernanceOrManagement respectFeeLimit(interest) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.liquidity[token].interest = interest;

        emit UpdateTokenLiquidityInterest(token, interest);
    }

    function setDefaultInterest(
        uint interest
    ) external override onlyGovernanceOrManagement respectFeeLimit(interest) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.defaultInterest = interest;

        emit UpdateDefaultLiquidityInterest(interest);
    }

    function liquidity(
        address token
    ) external view override returns (Liquidity memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.liquidity[token];
    }

    function convertLPToUnderlying(
        address token,
        uint amount
    ) external view override returns (uint) {
        return _convertLPToUnderlying(token, amount);
    }

    function convertUnderlyingToLP(
        address token,
        uint amount
    ) external view override returns (uint) {
        return _convertUnderlyingToLP(token, amount);
    }
}