// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '../interfaces/IStableSwapFactory.sol';
import '../interfaces/IStableSwapInfo.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@pancakeswap/v3-core/contracts/libraries/LowGasSafeMath.sol';
import '@pancakeswap/v3-core/contracts/interfaces/IPancakeV3Pool.sol';

library SmartRouterHelper {
    using LowGasSafeMath for uint256;

    /************************************************** Stable **************************************************/

    // get the pool info in stable swap
    function getStableInfo(
        address stableSwapFactory,
        address input,
        address output,
        uint256 flag
    ) public view returns (uint256 i, uint256 j, address swapContract) {
        if (flag == 2) {
            IStableSwapFactory.StableSwapPairInfo memory info = IStableSwapFactory(stableSwapFactory).getPairInfo(input, output);
            i = input == info.token0 ? 0 : 1;
            j = (i == 0) ? 1 : 0;
            swapContract = info.swapContract;
        } else if (flag == 3) {
            IStableSwapFactory.StableSwapThreePoolPairInfo memory info = IStableSwapFactory(stableSwapFactory).getThreePoolPairInfo(input, output);

            if (input == info.token0) i = 0;
            else if (input == info.token1) i = 1;
            else if (input == info.token2) i = 2;

            if (output == info.token0) j = 0;
            else if (output == info.token1) j = 1;
            else if (output == info.token2) j = 2;

            swapContract = info.swapContract;
        }

        require(swapContract != address(0), "getStableInfo: invalid pool address");
    }

    function getStableAmountsIn(
        address stableSwapFactory,
        address stableSwapInfo,
        address[] memory path,
        uint256[] memory flag,
        uint256 amountOut
    ) public view returns (uint256[] memory amounts) {
        uint256 length = path.length;
        require(length >= 2, "getStableAmountsIn: incorrect length");

        amounts = new uint256[](length);
        amounts[length - 1] = amountOut;

        for (uint256 i = length - 1; i > 0; i--) {
            uint256 last = i - 1;
            (uint256 k, uint256 j, address swapContract) = getStableInfo(stableSwapFactory, path[last], path[i], flag[last]);
            amounts[last] = IStableSwapInfo(stableSwapInfo).get_dx(swapContract, k, j, amounts[i], type(uint256).max);
        }
    }



    /************************************************** V2 **************************************************/

    // bytes32 internal constant V2_INIT_CODE_HASH = 0xd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66; // BSC TESTNET
    // bytes32 internal constant V2_INIT_CODE_HASH = 0x00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5; // BSC
    // bytes32 internal constant V2_INIT_CODE_HASH = 0x57224589c67f3f30a6b0d7a1b54cf3153ab84563bc609ef41dfb34f8b2974d2d; // ETH, GOERLI
    bytes32 internal constant V2_INIT_CODE_HASH = 0x57224589c67f3f30a6b0d7a1b54cf3153ab84563bc609ef41dfb34f8b2974d2d;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB);
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) public pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        V2_INIT_CODE_HASH
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) public view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0);
        uint256 amountInWithFee = amountIn.mul(9975);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountIn) {
        require(amountOut > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0);
        uint256 numerator = reserveIn.mul(amountOut).mul(10000);
        uint256 denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) public view returns (uint256[] memory amounts) {
        require(path.length >= 2);
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }



    /************************************************** V3 **************************************************/

    bytes32 internal constant V3_INIT_CODE_HASH = 0x6ce8eb472fa82df5469c6ab6d485f17c3ad13c8cd7af59b3d4a8026c5ce0f7e2;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
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
    ) public pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the deployer and PoolKey
    /// @param deployer The PancakeSwap V3 deployer contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address deployer, PoolKey memory key) public pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        deployer,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        V3_INIT_CODE_HASH
                    )
                )
            )
        );
    }

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getPool(
        address deployer,
        address tokenA,
        address tokenB,
        uint24 fee
    ) public pure returns (IPancakeV3Pool) {
        return IPancakeV3Pool(computeAddress(deployer, getPoolKey(tokenA, tokenB, fee)));
    }

    /// @notice Returns the address of a valid PancakeSwap V3 Pool
    /// @param deployer The contract address of the PancakeSwap V3 deployer
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address deployer,
        address tokenA,
        address tokenB,
        uint24 fee
    ) public view returns (IPancakeV3Pool pool) {
        return verifyCallback(deployer, getPoolKey(tokenA, tokenB, fee));
    }

    /// @notice Returns the address of a valid PancakeSwap V3 Pool
    /// @param deployer The contract address of the PancakeSwap V3 deployer
    /// @param poolKey The identifying key of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallback(address deployer, PoolKey memory poolKey)
        public
        view
        returns (IPancakeV3Pool pool)
    {
        pool = IPancakeV3Pool(computeAddress(deployer, poolKey));
        require(msg.sender == address(pool));
    }
}