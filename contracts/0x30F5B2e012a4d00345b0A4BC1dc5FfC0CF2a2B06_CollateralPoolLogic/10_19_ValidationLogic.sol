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

    uint256 public constant VERSION = 1;

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
            reserve.configuration.mode == DataTypes.AssetMode.OnlyReserve ||
            reserve.configuration.mode == DataTypes.AssetMode.ReserveAndLong,
            "reserve mode disabled"
        );
        require(reserve.configuration.state == DataTypes.AssetState.Active, Errors.POOL_INACTIVE);
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
            reserve.configuration.mode == DataTypes.AssetMode.OnlyReserve ||
            reserve.configuration.mode == DataTypes.AssetMode.ReserveAndLong,
            "reserve mode disabled"
        );
        require(reserve.configuration.state != DataTypes.AssetState.Disabled, Errors.POOL_ACTIVE);
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
        require(collateral.configuration.state == DataTypes.AssetState.Active, Errors.POOL_INACTIVE);
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
        require(collateral.configuration.state != DataTypes.AssetState.Disabled, Errors.POOL_ACTIVE);
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
        require(currCollateralSupply >= amount, Errors.NOT_ENOUGH_POOL_BALANCE);
        require(
            (userCollateral - amount) == 0 || (userCollateral - amount) >= collateral.configuration.minBalance,
            "collateral will under the minimum collateral balance"
        );
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
        DataTypes.AssetState state,
        DataTypes.AssetMode mode
    ) internal view {
        require(
            state == DataTypes.AssetState.Active &&
            (mode == DataTypes.AssetMode.OnlyReserve ||
            mode == DataTypes.AssetMode.ReserveAndLong),
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
        DataTypes.AssetState state,
        DataTypes.AssetMode mode
    ) internal view {
        require(
            state == DataTypes.AssetState.Active &&
            (mode == DataTypes.AssetMode.OnlyLong ||
            mode == DataTypes.AssetMode.ReserveAndLong),
            Errors.POOL_INACTIVE
        );
        require(userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(userPosition > 0, Errors.NOT_ENOUGH_LONG_BALANCE);
        require(amount > 0, Errors.INVALID_AMOUNT_INPUT);
    }

    /**
     * @notice Validate a Trade
     * @param shortReserve Shorting reserve
     * @param longReserve Longing reserve
     * @param shortingAssetPosition User shorting asset position
     * @param params ValidateTradeParams object
     **/
    function validateTrade(
        DataTypes.ReserveData memory shortReserve,
        DataTypes.ReserveData memory longReserve,
        int256 shortingAssetPosition,
        DataTypes.ValidateTradeParams memory params
    ) internal view {
        require(shortReserve.asset != longReserve.asset, Errors.CANNOT_TRADE_SAME_ASSET);
        // is pool active
        require(
            shortReserve.configuration.mode == DataTypes.AssetMode.ReserveAndLong ||
            shortReserve.configuration.mode == DataTypes.AssetMode.OnlyReserve,
            "asset cannot short"
        );
        require(
            longReserve.configuration.mode == DataTypes.AssetMode.ReserveAndLong ||
            longReserve.configuration.mode == DataTypes.AssetMode.OnlyLong,
            "asset cannot long"
        );
        require(shortReserve.configuration.state == DataTypes.AssetState.Active, Errors.POOL_INACTIVE);
        require(longReserve.configuration.state == DataTypes.AssetState.Active, Errors.POOL_INACTIVE);

        // user constraint
        require(params.userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(params.amountToTrade != 0, Errors.INVALID_ZERO_AMOUNT);

        // max short amount
        require(params.amountToTrade <= params.maxAmountToTrade, Errors.NOT_ENOUGH_USER_LEVERAGE);

        uint256 amountToBorrow;

        if (shortingAssetPosition < 0) {
            // Already negative on short side, so the entire trading amount will be borrowed
            amountToBorrow = params.amountToTrade;
        } else {
            // Not negative on short side: there may be something to sell before borrowing
            if (uint256(shortingAssetPosition) < params.amountToTrade) {
                amountToBorrow = params.amountToTrade - uint256(shortingAssetPosition);
            }
            // else, curr position is long and has enough to fill the trade
        }


        // check available reserve
        if (amountToBorrow > 0) {
            require(amountToBorrow <= params.currShortReserveAvailableSupply, Errors.NOT_ENOUGH_POOL_BALANCE);
        }
    }
}