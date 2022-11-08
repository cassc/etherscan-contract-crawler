// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {AggregatorV3Interface} from "./external/AggregatorV3Interface.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";

/// @title OneWayBondingCurve
/// @author Llama
/// @notice One Way Bonding Curve to purchase discounted aUSDC for BAL upto a 100k BAL Ceiling
contract OneWayBondingCurve {
    using SafeERC20 for IERC20;

    /********************************
     *   CONSTANTS AND IMMUTABLES   *
     ********************************/

    uint256 public constant BAL_AMOUNT_CAP = 100_000e18;

    IERC20 public constant BAL = IERC20(0xba100000625a3754423978a60c9317c58a424e3D);
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant AUSDC = IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);

    AggregatorV3Interface public constant BAL_USD_FEED =
        AggregatorV3Interface(0xdF2917806E30300537aEB49A7663062F4d1F2b5F);

    /*************************
     *   STORAGE VARIABLES   *
     *************************/

    /// @notice Cumulative aUSDC Purchased
    uint256 public totalAusdcPurchased;

    /// @notice Cumulative BAL Received
    uint256 public totalBalReceived;

    /**************
     *   EVENTS   *
     **************/

    event Purchase(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    /****************************
     *   ERRORS AND MODIFIERS   *
     ****************************/

    error OnlyNonZeroAmount();
    error ExcessBalAmountIn();
    error InvalidOracleAnswer();

    /*****************
     *   FUNCTIONS   *
     *****************/

    /// @notice Purchase USDC for BAL
    /// @param amountIn Amount of BAL input
    /// @param toUnderlying Whether to receive as USDC (true) or aUSDC (false)
    /// @return amountOut Amount of USDC received
    /// @dev Purchaser has to approve BAL transfer before calling this function
    function purchase(uint256 amountIn, bool toUnderlying) external returns (uint256) {
        if (amountIn == 0) revert OnlyNonZeroAmount();
        if (amountIn > availableBalToBeFilled()) revert ExcessBalAmountIn();

        uint256 amountOut = getAmountOut(amountIn);
        if (amountOut == 0) revert OnlyNonZeroAmount();

        totalBalReceived += amountIn;
        totalAusdcPurchased += amountOut;

        // Execute the purchase
        BAL.safeTransferFrom(msg.sender, AaveV2Ethereum.COLLECTOR, amountIn);
        if (toUnderlying) {
            AUSDC.safeTransferFrom(AaveV2Ethereum.COLLECTOR, address(this), amountOut);
            // Withdrawing entire aUSDC balance in this contract since we can't directly use 'amountOut' as
            // input due to +1/-1 precision issues caused by rounding on aTokens while it's being transferred.
            amountOut = AaveV2Ethereum.POOL.withdraw(address(USDC), type(uint256).max, msg.sender);
            emit Purchase(address(BAL), address(USDC), amountIn, amountOut);
        } else {
            AUSDC.safeTransferFrom(AaveV2Ethereum.COLLECTOR, msg.sender, amountOut);
            emit Purchase(address(BAL), address(AUSDC), amountIn, amountOut);
        }

        return amountOut;
    }

    /// @notice Returns how close to the 100k BAL amount cap we are
    /// @return availableBalToBeFilled the amount of BAL left to be filled
    /// @dev Purchaser check this function before calling purchase() to see if there is BAL left to be filled
    function availableBalToBeFilled() public view returns (uint256) {
        return BAL_AMOUNT_CAP - totalBalReceived;
    }

    /// @notice Returns amount of USDC that will be received after a bonding curve purchase of BAL
    /// @param amountIn the amount of BAL used to purchase
    /// @return amountOutWithBonus the amount of USDC received with 50 bps incentive included
    /// @dev Purchaser check this function before calling purchase() to see the amount of USDC you'll get for given BAL
    function getAmountOut(uint256 amountIn) public view returns (uint256) {
        /** 
            The actual calculation is a collapsed version of this to prevent precision loss:
            => amountOut = (amountBALWei / 10^balDecimals) * (chainlinkPrice / chainlinkPrecision) * 10^usdcDecimals
            => amountOut = (amountBalWei / 10^18) * (chainlinkPrice / 10^8) * 10^6
         */
        uint256 amountOut = (amountIn * getOraclePrice()) / 10**20;
        // 50 bps arbitrage incentive
        return (amountOut * 10050) / 10000;
    }

    /// @notice The peg price of the referenced oracle as USD per BAL
    function getOraclePrice() public view returns (uint256) {
        (, int256 price, , , ) = BAL_USD_FEED.latestRoundData();
        if (price <= 0) revert InvalidOracleAnswer();
        return uint256(price);
    }

    /// @notice Transfer any tokens accidentally sent to this contract to Aave V2 Collector
    /// @param tokens List of token addresses
    function rescueTokens(address[] calldata tokens) external {
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20(tokens[i]).safeTransfer(AaveV2Ethereum.COLLECTOR, IERC20(tokens[i]).balanceOf(address(this)));
        }
    }
}