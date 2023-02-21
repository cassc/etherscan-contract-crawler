// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../types/DataTypes.sol";
import "../math/MathUtils.sol";
import "../helpers/Errors.sol";

library ValidationLogic {
    using MathUtils for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant VERSION = 2;

    /**
     * @notice Validate a Deposit to Reserve
     * @param reserve reserve
     * @param amount amount
     **/
    function validateDepositReserve(
        DataTypes.ReserveData memory reserve,
        uint256 amount
    ) internal pure {
        require(
            reserve.configuration.state == DataTypes.AssetState.Active ||
            reserve.configuration.state == DataTypes.AssetState.PausedTrading,
            Errors.POOL_INACTIVE
        );
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
    }

    /**
     * @notice Validate a Withdraw from Reserve
     * @param reserve reserve
     * @param amount amount
     **/
    function validateWithdrawReserve(
        DataTypes.ReserveData memory reserve,
        uint256 currReserveSupply,
        uint256 amount
    ) internal pure {
        require(
            reserve.configuration.state == DataTypes.AssetState.Active ||
            reserve.configuration.state == DataTypes.AssetState.PausedTrading ||
            reserve.configuration.state == DataTypes.AssetState.Withdrawing,
            Errors.POOL_INACTIVE
        );
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
        require(currReserveSupply >= amount, Errors.NOT_ENOUGH_POOL_BALANCE);
    }

    /**
     * @notice Validate a Deposit to Collateral
     * @param collateral collateral
     * @param userLastTradeBlock userLastTradeBlock
     * @param amount amount
     * @param userCollateral userCollateral
     **/
    function validateDepositCollateral(
        DataTypes.CollateralData memory collateral,
        uint256 userLastTradeBlock,
        uint256 amount,
        uint256 userCollateral
    ) internal view {
        require(userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(collateral.configuration.mode == DataTypes.AssetMode.Active, Errors.POOL_INACTIVE);
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
        require(
            (userCollateral + amount) >= collateral.configuration.minBalance,
            "collateral will under the minimum collateral balance"
        );
    }

    /**
     * @notice Validate a Withdraw from Collateral
     * @param collateral collateral
     * @param userLastTradeBlock userLastTradeBlock
     * @param amount amount
     * @param userCollateral userCollateral
     **/
    function validateWithdrawCollateral(
        DataTypes.CollateralData memory collateral,
        uint256 userLastTradeBlock,
        uint256 amount,
        uint256 userCollateral,
        uint256 currCollateralSupply
    ) internal view {
        require(userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(
            collateral.configuration.mode == DataTypes.AssetMode.Active ||
            collateral.configuration.mode == DataTypes.AssetMode.Withdrawing,
            Errors.POOL_INACTIVE
        );
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
        require(currCollateralSupply >= amount, Errors.NOT_ENOUGH_POOL_BALANCE);
        require(
            (userCollateral - amount) == 0 || (userCollateral - amount) >= collateral.configuration.minBalance,
            "collateral will under the minimum collateral balance"
        );
    }

    function validateClaimReinvestmentRewards(
        DataTypes.CollateralData memory collateral
    ) internal pure {
        require(
            collateral.configuration.mode == DataTypes.AssetMode.Active ||
            collateral.configuration.mode == DataTypes.AssetMode.Withdrawing,
            Errors.POOL_INACTIVE
        );
        require(collateral.reinvestment != address(0), Errors.INVALID_POOL_REINVESTMENT);
    }

    /**
     * @notice Validate Short Repayment
     * @param userLastTradeBlock userLastTradeBlock
     * @param user user
     * @param asset asset
     * @param amount amount
     **/
    function validateRepayShort(
        int256 currNormalizedPosition,
        uint256 userLastTradeBlock,
        address user,
        address asset,
        uint256 amount,
        DataTypes.AssetState state
    ) internal view {
        require(
            state == DataTypes.AssetState.Active ||
            state == DataTypes.AssetState.PausedTrading ||
            state == DataTypes.AssetState.Withdrawing,
            Errors.POOL_INACTIVE
        );
        require(userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(currNormalizedPosition < 0, Errors.INVALID_POSITION_TYPE);
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
        /*
        TODO: is allowance checked can be omitted?
        it will still revert during transfer if amount is not enough
        */
        require(
            IERC20Upgradeable(asset).allowance(user, address(this)) >= amount,
            "need to approve first"
        );
    }

    /**
     * @notice Validate a Withdraw Long
     * @param userPosition User position
     * @param userLastTradeBlock userLastTradeBlock
     **/
    function validateWithdrawLong(
        int256 userPosition,
        uint256 userLastTradeBlock,
        uint256 amount,
        DataTypes.AssetState state
    ) internal view {
        require(
            state == DataTypes.AssetState.Active ||
            state == DataTypes.AssetState.PausedTrading ||
            state == DataTypes.AssetState.Withdrawing,
            Errors.POOL_INACTIVE
        );
        require(userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(userPosition > 0, Errors.NOT_ENOUGH_LONG_BALANCE);
        require(amount > 0, Errors.INVALID_AMOUNT_INPUT);
    }

    /**
     * @notice Validate a Trade
     * @param sellingAssetReserve Shorting reserve
     * @param buyingAssetReserve Longing reserve
     * @param sellingAssetPosition User shorting asset position
     * @param params ValidateTradeParams object
     **/
    function validatePreTrade(
        DataTypes.ReserveData memory sellingAssetReserve,
        DataTypes.ReserveData memory buyingAssetReserve,
        int256 sellingAssetPosition,
        int256 buyingAssetPosition,
        DataTypes.ValidateTradeParams memory params
    ) internal view {
        require(sellingAssetReserve.asset != buyingAssetReserve.asset, Errors.CANNOT_TRADE_SAME_ASSET);

        // user constraint
        require(params.userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(params.amountToTrade != 0, Errors.INVALID_ZERO_AMOUNT);

        // max short amount
        require(params.amountToTrade <= params.maxAmountToTrade, Errors.NOT_ENOUGH_USER_LEVERAGE);

        uint256 amountToBorrow;

        if (sellingAssetPosition < 0) {
            // Already negative on short side, so the entire trading amount will be borrowed
            amountToBorrow = params.amountToTrade;
        } else {
            // Not negative on short side: there may be something to sell before borrowing
            if (uint256(sellingAssetPosition) < params.amountToTrade) {
                amountToBorrow = params.amountToTrade - uint256(sellingAssetPosition);
            }
            // else, curr position is long and has enough to fill the trade
        }

        // check available reserve
        if (amountToBorrow > 0) {
            require(amountToBorrow <= params.currShortReserveAvailableSupply, Errors.NOT_ENOUGH_POOL_BALANCE);
        }

        int256 nextSellingAssetPosition = sellingAssetPosition - int256(params.amountToTrade);
        require(
            sellingAssetReserve.configuration.state == DataTypes.AssetState.Active ||
            (sellingAssetReserve.configuration.state == DataTypes.AssetState.Withdrawing && nextSellingAssetPosition >= 0),
            Errors.ASSET_CANNOT_SHORT
        );

        // this is a pre-check of buying asset state
        // buying position's amount must not be greater than 0 when state is Withdrawing
        // user should not be able to create more positive position since we are preparing to retire the asset
        require(
            buyingAssetReserve.configuration.state == DataTypes.AssetState.Active ||
            (buyingAssetReserve.configuration.state == DataTypes.AssetState.Withdrawing && buyingAssetPosition < 0),
            Errors.ASSET_CANNOT_LONG
        );
    }

    function validatePostTrade(
        DataTypes.ReserveData memory buyingAssetReserve,
        int256 buyingAssetPosition,
        uint256 receivedAmount
    ) internal pure {
        // this is a post-check of buying asset state
        int256 nextAssetPosition = buyingAssetPosition + int256(receivedAmount);

        if (buyingAssetReserve.configuration.state == DataTypes.AssetState.Withdrawing) {
            require(nextAssetPosition <= 0, Errors.ASSET_CANNOT_LONG);
        }
    }

    function validateLiquidationTrade(
        DataTypes.AssetState sellingAssetState,
        DataTypes.AssetState buyingAssetState,
        int256 sellingAssetPosition,
        int256 buyingAssetPosition,
        uint256 amountToTrade
    ) internal pure {
        int256 nextSellingAssetPosition = sellingAssetPosition - int256(amountToTrade);
        require(
            sellingAssetState == DataTypes.AssetState.Active ||
            (sellingAssetState == DataTypes.AssetState.Withdrawing && nextSellingAssetPosition >= 0) ||
            sellingAssetState == DataTypes.AssetState.LiquidatorOnly,
            Errors.POOL_INACTIVE
        );
        require(
            buyingAssetState == DataTypes.AssetState.Active ||
            (buyingAssetState == DataTypes.AssetState.Withdrawing && buyingAssetPosition < 0) ||
            buyingAssetState == DataTypes.AssetState.LiquidatorOnly,
            Errors.POOL_INACTIVE
        );
    }
}