// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.9;
pragma experimental ABIEncoderV2;

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v3-core/contracts/libraries/SafeCast.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/UnsafeMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "./interface/IERC721.sol";

interface IUniswapV3Pool {
    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }

    function slot0() external view returns (Slot0 memory);
}

interface IUniswapV3Factory {
    function getPool(
        address token0,
        address token1,
        uint24 fees
    ) external view returns (address);
}

contract UniswapV3PositionUtility is Ownable {
    using SafeMath for uint256;
    using SafeCast for uint256;

    address public uniswapPositionManager;
    address public uniswapFactory;
    address public VEMPContract;

    struct Position {
        // the nonce for permits
        uint96 nonce;
        // the address that is approved for spending this token
        address operator;
        // the ID of the pool with which this token is connected
        //uint80 poolId;
        address token0;
        address token1;
        uint24 fee;
        // the tick range of the position
        int24 tickLower;
        int24 tickUpper;
        // the liquidity of the position
        uint128 liquidity;
        // the fee growth of the aggregate position as of the last action on the individual position
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        // how many uncollected tokens are owed to the position, as of the last computation
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    function setUniswapPositionManager(
        address _uniswapPositionManager
    ) external onlyOwner {
        require(_uniswapPositionManager != address(0), "Zero address");
        uniswapPositionManager = _uniswapPositionManager;
    }

    function setUniswapFactory(address _uniswapFactory) external onlyOwner {
        require(_uniswapFactory != address(0), "Zero address");
        uniswapFactory = _uniswapFactory;
    }

    function setVEMPContract(address _VEMPContract) external onlyOwner {
        require(_VEMPContract != address(0), "Zero address");
        VEMPContract = _VEMPContract;
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        require(sqrtRatioAX96 > 0);

        return
            roundUp
                ? UnsafeMath.divRoundingUp(
                    FullMath.mulDivRoundingUp(
                        numerator1,
                        numerator2,
                        sqrtRatioBX96
                    ),
                    sqrtRatioAX96
                )
                : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) /
                    sqrtRatioAX96;
    }

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        return
            liquidity < 0
                ? -getAmount0Delta(
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    uint128(-liquidity),
                    false
                ).toInt256()
                : getAmount0Delta(
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    uint128(liquidity),
                    true
                ).toInt256();
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            roundUp
                ? FullMath.mulDivRoundingUp(
                    liquidity,
                    sqrtRatioBX96 - sqrtRatioAX96,
                    FixedPoint96.Q96
                )
                : FullMath.mulDiv(
                    liquidity,
                    sqrtRatioBX96 - sqrtRatioAX96,
                    FixedPoint96.Q96
                );
    }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        return
            liquidity < 0
                ? -getAmount1Delta(
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    uint128(-liquidity),
                    false
                ).toInt256()
                : getAmount1Delta(
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    uint128(liquidity),
                    true
                ).toInt256();
    }

    function getAmountAtPosition0(
        int24 tickUpper,
        int24 tickLower,
        uint128 liquidity,
        address _pairAddress
    ) internal view returns (uint256) {
        IUniswapV3Pool.Slot0 memory _slot0 = IUniswapV3Pool(_pairAddress)
            .slot0();
        uint160 sqrtPriceX96 = _slot0.sqrtPriceX96;

        int128 liquidityDelta = int128(liquidity);
        int256 amountVEMP;
        if (_slot0.tick < tickLower) {
            amountVEMP = getAmount0Delta(
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidityDelta
            );
        } else if (_slot0.tick < tickUpper) {
            amountVEMP = getAmount0Delta(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidityDelta
            );
        }
        return uint256(amountVEMP);
    }

    function getAmountAtPosition1(
        int24 tickUpper,
        int24 tickLower,
        uint128 liquidity,
        address _pairAddress
    ) internal view returns (uint256) {
        IUniswapV3Pool.Slot0 memory _slot0 = IUniswapV3Pool(_pairAddress)
            .slot0();
        uint160 sqrtPriceX96 = _slot0.sqrtPriceX96;

        int128 liquidityDelta = int128(liquidity);
        int256 amountVEMP;
        if (_slot0.tick < tickLower) {
            amountVEMP = 0;
        } else if (_slot0.tick < tickUpper) {
            amountVEMP = getAmount1Delta(
                TickMath.getSqrtRatioAtTick(tickLower),
                sqrtPriceX96,
                liquidityDelta
            );
        } else {
            amountVEMP = getAmount1Delta(
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidityDelta
            );
        }
        return uint256(amountVEMP);
    }

    function getVEMPAmount(uint256 tokenID) public view returns (uint256) {
        int24 tickUpper;
        int24 tickLower;
        uint128 liquidity;
        address token0;
        address token1;
        uint256 returnAmount;
        (
            ,
            ,
            token0,
            token1,
            ,
            tickLower,
            tickUpper,
            liquidity,
            ,
            ,
            ,

        ) = IERC721(uniswapPositionManager).positions(tokenID);
        address _pairAddress = IUniswapV3Factory(uniswapFactory).getPool(
            token0,
            token1,
            10000
        );

        if (token0 == VEMPContract) {
            returnAmount = getAmountAtPosition0(
                tickUpper,
                tickLower,
                liquidity,
                _pairAddress
            );
            return returnAmount;
        } else if (token1 == VEMPContract) {
            returnAmount = getAmountAtPosition1(
                tickUpper,
                tickLower,
                liquidity,
                _pairAddress
            );
            return returnAmount;
        } else {
            revert("not VEMP pool");
        }
    }
}