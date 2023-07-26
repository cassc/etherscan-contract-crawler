// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is IUniswapV3PoolImmutables, IUniswapV3PoolState {}

/// @title DexNativeRouter
/// @notice Entrance of trading native token in web3-dex
contract QueryData {
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    struct Univ3TickStruct {
        int24 tick;
        int128 liquidityNet;
    }

    function queryUniv3Ticks(address pool, int24 leftPoint, int24 rightPoint)
        public
        view
        returns (int24[] memory ticks, int128[] memory liquidityNets)
    {
        int24 pointDelta = IUniswapV3Pool(pool).tickSpacing();

        uint256 len = 200;

        ticks = new int24[](len);
        liquidityNets = new int128[](len);
        uint256 idx = 0;
        for (int24 i = leftPoint; i < rightPoint; i += pointDelta) {
            (, int128 int128liquidityNet,,,,,,) = IUniswapV3Pool(pool).ticks(i);
            if (int128liquidityNet == 0) {
                continue;
            }
            ticks[idx] = i;
            liquidityNets[idx] = int128liquidityNet;
            idx++;
            if (idx == len) {
                break;
            }
        }
    }

    function queryUniv3TicksPool(address pool, int24 leftPoint, int24 rightPoint)
        public
        view
        returns (int24[] memory efficientTicks, int128[] memory efficientLiquidityNets)
    {
        int24 pointDelta = IUniswapV3Pool(pool).tickSpacing();
        uint256 len = uint256(int256((rightPoint - leftPoint) / pointDelta));
        int24[] memory ticks = new int24[](len);
        int128[] memory liquidityNets = new int128[](len);
        uint256 idx = 0;
        uint256 efficientCount = 0;
        for (int24 i = leftPoint; i < rightPoint; i += pointDelta) {
            (, int128 int128liquidityNet,,,,,,) = IUniswapV3Pool(pool).ticks(i);
            if (int128liquidityNet == 0) {
                continue;
            }
            efficientCount++;
            ticks[idx] = i;
            liquidityNets[idx] = int128liquidityNet;
            idx++;
            if (idx == len) {
                break;
            }
        }
        efficientTicks = new int24[]((efficientCount));
        efficientLiquidityNets = new int128[](efficientCount);
        for (uint256 i = 0; i < efficientCount; i++) {
            efficientTicks[i] = ticks[i];
            efficientLiquidityNets[i] = liquidityNets[i];
        }
    }

    function queryUniv3TicksPool2(
        address pool,
        int24 leftPoint,
        int24 rightPoint,
        uint256 arraySize
    ) public view returns (int256[] memory) {
        int24 tickSpacing = IUniswapV3Pool(pool).tickSpacing();
        int24 left = leftPoint / tickSpacing / int24(256);
        uint256 initPoint = uint256(int256(leftPoint / tickSpacing % 256));
        int24 right = rightPoint / tickSpacing / int24(256);

        int256[] memory tickInfo = new int[](arraySize);

        uint256 index = 0;
        while (left < right + 1) {
            uint256 res = IUniswapV3Pool(pool).tickBitmap(int16(left));
            if (res > 0) {
                res = res >> initPoint;
                for (uint256 i = initPoint; i < 256; i++) {
                    uint256 isInit = res & 0x01;
                    if (isInit > 0) {
                        int256 tick = int256((256 * left + int256(i)) * tickSpacing);
                        (, int128 liquidityNet,,,,,,) =
                            IUniswapV3Pool(pool).ticks(int24(int256(tick)));

                        tickInfo[index] = int256(tick << 128) + liquidityNet;

                        index++;
                    }
                    if (index == arraySize) break;
                    res = res >> 1;
                }
            }
            initPoint = 0;
            left++;
        }
        uint256 len = index;

        assembly {
            mstore(tickInfo, len)
        }
        return tickInfo;
    }

    function queryUniv3TicksPool3(address pool, int24 leftPoint, int24 rightPoint)
        public
        view
        returns (bytes memory)
    {
        int24 tickSpacing = IUniswapV3Pool(pool).tickSpacing();
        int24 left = leftPoint / tickSpacing / int24(256);
        uint256 initPoint = uint256(int256(leftPoint / tickSpacing % 256));
        int24 right = rightPoint / tickSpacing / int24(256);

        bytes memory tickInfo = hex"";

        uint256 index = 0;
        while (left < right + 1) {
            uint256 res = IUniswapV3Pool(pool).tickBitmap(int16(left));
            if (res > 0) {
                res = res >> initPoint;
                for (uint256 i = initPoint; i < 256; i++) {
                    uint256 isInit = res & 0x01;
                    if (isInit > 0) {
                        int256 tick = int256((256 * left + int256(i)) * tickSpacing);
                        (, int128 liquidityNet,,,,,,) =
                            IUniswapV3Pool(pool).ticks(int24(int256(tick)));

                        int256 data = int256(tick << 128) + liquidityNet;
                        tickInfo = bytes.concat(tickInfo, bytes32(uint256(data)));

                        index++;
                    }

                    res = res >> 1;
                }
            }
            initPoint = 0;
            left++;
        }

        return tickInfo;
    }
}

import "forge-std/test.sol";
import "forge-std/console2.sol";

contract POC is Test {
    IUniswapV3Pool WETH_USDC = IUniswapV3Pool(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640);
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //1
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //0
    QueryData query;

    function setUp() public {
        vm.createSelectFork("https://eth.llamarpc.com", 12544978 + 1);
        query = new QueryData();
    }

    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        require(
            deployer == 0x358506b4C5c441873AdE429c5A2BE777578E2C6f, "deployer not correct"
        );
        vm.createSelectFork("https://eth.llamarpc.com");
        vm.startBroadcast(deployer);
        require(block.chainid == 1, "must be mainnet");
        query = new QueryData();
        console2.log("query address", address(query));
        vm.stopBroadcast();
    }

    function test_query() public {
        (int256[] memory tickInfo) = query.queryUniv3TicksPool2(
            address(WETH_USDC), int24(69080), int24(414490), uint256(10)
        );
        for (uint256 i = 0; i < tickInfo.length; i++) {
            console2.log("tick: %d", int128(tickInfo[i] >> 128));
            console2.log("l: %d", int128(tickInfo[i]));
        }
    }

    function test_query3() public {
        (bytes memory tickInfo) =
            query.queryUniv3TicksPool3(address(WETH_USDC), int24(-69080), int24(414490));
        uint256 len;
        uint256 offset;
        console2.logBytes(tickInfo);

        assembly {
            len := mload(tickInfo)
            offset := add(tickInfo, 32)
        }
        for (uint256 i = 0; i < len / 32; i++) {
            int256 res;
            assembly {
                res := mload(offset)
                offset := add(offset, 32)
            }
            console2.log("tick: %d", int128(res >> 128));
            console2.log("l: %d", int128(res));
        }
    }
}