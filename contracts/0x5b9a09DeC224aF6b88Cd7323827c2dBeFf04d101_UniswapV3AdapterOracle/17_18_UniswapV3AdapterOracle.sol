// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import './UsingBaseOracle.sol';
import '../BlueBerryErrors.sol';
import '../interfaces/IBaseOracle.sol';
import '../interfaces/uniswap/v3/IUniswapV3Pool.sol';
import '../libraries/UniV3/OracleLibrary.sol';

contract UniswapV3AdapterOracle is IBaseOracle, UsingBaseOracle, Ownable {
    event SetPoolETH(address token, address pool);
    event SetPoolStable(address token, address pool);
    event SetTimeAgo(address token, uint32 timeAgo);

    mapping(address => uint32) public timeAgos; // Mapping from token address to elapsed time from checkpoint
    mapping(address => address) public stablePools; // Mapping from token address to token/(USDT/USDC/DAI) pool address

    constructor(IBaseOracle _base) UsingBaseOracle(_base) {}

    /// @dev Set price reference for Stable pair
    /// @param tokens list of tokens to set reference
    /// @param pools list of reference pool contract addresses
    function setStablePools(address[] calldata tokens, address[] calldata pools)
        external
        onlyOwner
    {
        if (tokens.length != pools.length) revert INPUT_ARRAY_MISMATCH();
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            if (tokens[idx] == address(0) || pools[idx] == address(0))
                revert ZERO_ADDRESS();
            stablePools[tokens[idx]] = pools[idx];
            emit SetPoolStable(tokens[idx], pools[idx]);
        }
    }

    /// @dev Set timeAgos for each token
    /// @param tokens list of tokens to set timeAgos
    /// @param times list of timeAgos to set to
    function setTimeAgos(address[] calldata tokens, uint32[] calldata times)
        external
        onlyOwner
    {
        if (tokens.length != times.length) revert INPUT_ARRAY_MISMATCH();
        for (uint256 idx = 0; idx < tokens.length; idx++) {
            if (tokens[idx] == address(0)) revert ZERO_ADDRESS();
            if (times[idx] < 10) revert TOO_LOW_MEAN(times[idx]);
            timeAgos[tokens[idx]] = times[idx];
            emit SetTimeAgo(tokens[idx], times[idx]);
        }
    }

    /// @dev Return the USD based price of the given input, multiplied by 10**18.
    /// @param token The ERC-20 token to check the value.
    function getPrice(address token) external view override returns (uint256) {
        uint32 secondsAgo = timeAgos[token];
        if (secondsAgo == 0) revert NO_MEAN(token);

        address stablePool = stablePools[token];
        if (stablePool == address(0)) revert NO_STABLEPOOL(token);

        address token0 = IUniswapV3Pool(stablePool).token0();
        address token1 = IUniswapV3Pool(stablePool).token1();
        token1 = token0 == token ? token1 : token0; // get stable token address
        uint256 stableDecimals = uint256(IERC20Metadata(token1).decimals());
        uint256 tokenDecimals = uint256(IERC20Metadata(token).decimals());
        (int24 arithmeticMeanTick, ) = OracleLibrary.consult(
            stablePool,
            secondsAgo
        );
        uint256 quoteTokenAmountForStable = OracleLibrary.getQuoteAtTick(
            arithmeticMeanTick,
            uint128(10**tokenDecimals),
            token,
            token1
        );

        return
            (quoteTokenAmountForStable * base.getPrice(token1)) /
            10**stableDecimals;
    }
}