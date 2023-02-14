// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

pragma solidity 0.7.6;

interface IUniswapV2FactoryForBaseSwapper {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2PairForBaseSwapper {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

contract BaseSwapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2FactoryForBaseSwapper public immutable factory;
    uint public immutable factoryNumerator;
    uint public immutable factoryDenominator;
    address public immutable wNative;

    mapping(address => address[]) swapPaths;

    event SwapPathSet(address indexed token, address[] indexed path);
    event LogConvert(
        address indexed server,
        address indexed token,
        uint256 amount,
        uint256 amountBANANA
    );

    function swapPathFor(address token) public view returns (address[] memory swapPath) {
        return swapPaths[token];
    }

    constructor(
        address _factory,
        uint _factoryNumerator,
        uint _factoryDenominator,
        address _wNative
    ) {
        factory = IUniswapV2FactoryForBaseSwapper(_factory);

        factoryNumerator= _factoryNumerator;
        factoryDenominator= _factoryDenominator;

        wNative = _wNative;
    }

    function setSwapPathInternal(address token, address[] calldata swapPath) internal {
        // Checks
        uint pathLength = swapPath.length;
        require(pathLength > 0, "NO_PATH_GIVEN");
        require(pathLength > 2, "PATH_IS_MIN_TWO_TOKENS");
        require(swapPath[0] == token, "MUST_START_WITH_ORIGIN");
        for (uint i = 1; i < pathLength; i ++) {
            address bridgeAsset = swapPath[i];
            require(bridgeAsset != token, "CANNOT_BRIDGE_WITH_SELF");
        }

        swapPaths[token] = swapPath;

        emit SwapPathSet(token, swapPath);
    }

    function _convertByPath(address[] memory path, uint amountInOriginal) internal returns (uint amountOut) {
        uint fromTokenIndex = 0;
        uint toTokenIndex = 1;
        uint amountInForSwap = amountInOriginal;

        while (toTokenIndex < path.length) {
            // swap
            amountOut = _swapTokensInternal(path[fromTokenIndex], path[toTokenIndex], amountInForSwap, address(this));
            amountInForSwap = amountOut;

            // increase index
            fromTokenIndex++;
            toTokenIndex++;
        }
    }

    function _swapTokensInternal(
        address fromToken,
        address toToken,
        uint256 amountIn,
        address to
    ) internal returns (uint256 amountOut) {
        // Checks
        IUniswapV2PairForBaseSwapper pair = IUniswapV2PairForBaseSwapper(factory.getPair(fromToken, toToken));
        require(address(pair) != address(0), "BaseSwapper: Cannot convert - NoPair");

        // Interactions
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(factoryNumerator);
        if (fromToken == pair.token0()) {
            amountOut = amountInWithFee.mul(reserve1) / reserve0.mul(factoryDenominator).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, to, new bytes(0));
            // TODO: Add maximum slippage?
        } else {
            amountOut = amountInWithFee.mul(reserve0) / reserve1.mul(factoryDenominator).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, to, new bytes(0));
            // TODO: Add maximum slippage?
        }
    }
}