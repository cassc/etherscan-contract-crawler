//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

pragma experimental ABIEncoderV2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "@openzeppelin-v4/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../PriceAccumulator.sol";
import "../../../libraries/SafeCastExt.sol";
import "../../../libraries/uniswap-lib/FullMath.sol";

contract UniswapV3PriceAccumulator is PriceAccumulator {
    using AddressLibrary for address;
    using SafeCastExt for uint256;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    address public immutable uniswapFactory;

    bytes32 public immutable initCodeHash;

    uint24[] public poolFees;

    constructor(
        address uniswapFactory_,
        bytes32 initCodeHash_,
        uint24[] memory poolFees_,
        address quoteToken_,
        uint256 updateTheshold_,
        uint256 minUpdateDelay_,
        uint256 maxUpdateDelay_
    ) PriceAccumulator(quoteToken_, updateTheshold_, minUpdateDelay_, maxUpdateDelay_) {
        uniswapFactory = uniswapFactory_;
        initCodeHash = initCodeHash_;
        poolFees = poolFees_;
    }

    /// @inheritdoc PriceAccumulator
    function canUpdate(bytes memory data) public view virtual override returns (bool) {
        address token = abi.decode(data, (address));

        if (token == address(0) || token == quoteToken) {
            // Invalid token
            return false;
        }

        (bool hasLiquidity, ) = calculateWeightedPrice(token);
        if (!hasLiquidity) {
            // Can't update if there's no liquidity (reverts)
            return false;
        }

        return super.canUpdate(data);
    }

    function calculatePriceFromSqrtPrice(
        address token,
        address quoteToken_,
        uint160 sqrtPriceX96,
        uint128 tokenAmount
    ) internal pure returns (uint256 price) {
        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtPriceX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtPriceX96) * sqrtPriceX96;
            price = token < quoteToken_
                ? FullMath.mulDiv(ratioX192, tokenAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, tokenAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, 1 << 64);
            price = token < quoteToken_
                ? FullMath.mulDiv(ratioX128, tokenAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, tokenAmount, ratioX128);
        }
    }

    /**
     * @notice Calculates the price of a token across all chosen pools.
     * @dev Uses harmonic mean, weighted by in-range liquidity.
     * @dev When the price equals 0, a price of 1 is actually returned.
     * @param token The token to get the price for.
     * @return hasLiquidity True if at least one of the chosen pools has [enough] in-range liquidity.
     * @return price The price of the specified token in terms of the quote token, scaled by the quote token decimal
     *  places. If hasLiquidity equals false, the returned price will always equal 0.
     */
    function calculateWeightedPrice(address token) internal view returns (bool hasLiquidity, uint256 price) {
        uint24[] memory _poolFees = poolFees;

        uint128 wholeTokenAmount = computeWholeUnitAmount(token);

        uint256 numerator;
        uint256 denominator;

        for (uint256 i = 0; i < _poolFees.length; ++i) {
            address pool = computeAddress(uniswapFactory, initCodeHash, getPoolKey(token, quoteToken, _poolFees[i]));

            if (pool.isContract()) {
                uint256 liquidity = IUniswapV3Pool(pool).liquidity(); // Note: returns uint128
                if (liquidity == 0) {
                    // No in-range liquidity, so ignore
                    continue;
                }

                // Shift liquidity for more precise calculations as we divide this by the pool price
                // This is safe as liquidity < 2^128
                liquidity = liquidity << 120;

                (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();

                // Add 1 to all prices to prevent divide by 0
                // This should realistically never overflow
                uint256 poolPrice = calculatePriceFromSqrtPrice(token, quoteToken, sqrtPriceX96, wholeTokenAmount) + 1;

                // Supports up to 256 pools with max liquidity (2^128) before overflowing (with liquidity << 120)
                numerator += liquidity;

                // Note: (liquidity / poolPrice) will equal 0 if liquidity < poolPrice, but
                // for this to happen, price would have to be insanely high
                // (over 18 figures left of the decimal w/ 18 decimal places)
                denominator += liquidity / poolPrice;
            }
        }

        if (denominator == 0) {
            // No in-range liquidity (or very little) in all of the pools
            return (false, 0);
        }

        return (true, numerator / denominator);
    }

    function fetchPrice(address token) internal view virtual override returns (uint112) {
        require(token != quoteToken, "UniswapV3PriceAccumulator: IDENTICAL_ADDRESSES");
        require(token != address(0), "UniswapV3PriceAccumulator: ZERO_ADDRESS");

        (bool hasLiquidity, uint256 _price) = calculateWeightedPrice(token);

        // Note: Will cause prices calculated from accumulations to be fixed to the last price
        require(hasLiquidity, "UniswapV3PriceAccumulator: NO_LIQUIDITY");

        return _price.toUint112();
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(
        address factory,
        bytes32 _initCodeHash,
        PoolKey memory key
    ) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            _initCodeHash
                        )
                    )
                )
            )
        );
    }

    function computeWholeUnitAmount(address token) internal view returns (uint128 amount) {
        amount = uint128(10)**IERC20Metadata(token).decimals();
    }
}