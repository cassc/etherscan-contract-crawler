//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../interfaces/ICurvePool.sol";
import "../interfaces/IExchangePlugin.sol";
import "../StrategyRouter.sol";

import "hardhat/console.sol";

/// On BSC Curve protocol is ACryptoS
contract CurvePlugin is IExchangePlugin, Ownable {
    error RoutedSwapFailed();
    error RouteNotFound();

    // tokenA -> tokenB -> pool to use as exchange
    mapping(address => mapping(address => address)) public pools;
    // curve-like pool -> token -> id of the token in the pool
    mapping(address => mapping(address => int128)) public coinIds;

    constructor() {}

    /// @notice Set curve-like pool to user to swap pair.
    function setCurvePool(
        address tokenA,
        address tokenB,
        address pool
    ) external onlyOwner {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pools[token0][token1] = pool;
    }

    /// @notice Cache pool's token ids.
    function setCoinIds(
        address _curvePool,
        address[] calldata tokens,
        int128[] calldata _coinIds
    ) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            coinIds[address(_curvePool)][tokens[i]] = _coinIds[i];
        }
    }

    function getExchangeProtocolFee(address tokenA, address tokenB) public view override returns (uint256 feePercent) {
        uint256 curveProtocolFeeDenominator = 1e10;
        address pool = getPool(tokenA, tokenB);
        uint256 fee = ICurvePool(pool).fee();
        // change precision from 10 to 18 decimals, 10 + (18 - 10)
        return fee * (1e18 / curveProtocolFeeDenominator); // 0.01% or 0.0001 with 18 decimals
    }

    function getAmountOut(
        uint256 amountA,
        address tokenA,
        address tokenB
    ) external view override returns (uint256 amountOut) {
        address pool = getPool(tokenA, tokenB);

        int128 _tokenAIndex = coinIds[address(pool)][tokenA];
        int128 _tokenBIndex = coinIds[address(pool)][tokenB];

        return ICurvePool(pool).get_dy(_tokenAIndex, _tokenBIndex, amountA);
    }

    function swap(
        uint256 amountA,
        address tokenA,
        address tokenB,
        address to
    ) public override returns (uint256 amountReceivedTokenB) {
        address pool = getPool(tokenA, tokenB);
        IERC20(tokenA).approve(address(pool), amountA);

        int128 _tokenAIndex = coinIds[address(pool)][tokenA];
        int128 _tokenBIndex = coinIds[address(pool)][tokenB];

        uint256 received = ICurvePool(pool).exchange(_tokenAIndex, _tokenBIndex, amountA, 0);

        IERC20(tokenB).transfer(to, received);

        return received;
    }

    function getPool(address tokenA, address tokenB) internal view returns (address) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        return pools[token0][token1];
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}