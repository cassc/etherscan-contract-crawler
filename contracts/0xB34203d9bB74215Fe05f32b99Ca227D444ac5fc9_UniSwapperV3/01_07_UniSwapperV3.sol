// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Swapper} from "./../interfaces/Swapper.sol";
import {IV3SwapRouter, IUniswapV3Factory, IQuoter} from "./../interfaces/UniV3.sol";

// Non documented uniswap interface
interface UniFactoryProvider {
    function factory() external view returns(IUniswapV3Factory);
}

contract UniSwapperV3 is Swapper, Ownable {

    IV3SwapRouter public amm;
    IUniswapV3Factory public factory;
    IQuoter public quoter;
    uint24[] public fees;

    constructor(address amm_, address quoter_) {
        setDex(amm_);
        quoter = IQuoter(quoter_);
    }

    function setDex(address amm_) public onlyOwner {
        amm = IV3SwapRouter(amm_);
        factory = UniFactoryProvider(amm_).factory();
    }

    function setQuoter(address quoter_) public onlyOwner {
        quoter = IQuoter(quoter_);
    }

    function setFeesLevels(uint24[] memory fees_) external {
        fees = fees_;
    }

    function getBestFees(address tokenA, address tokenB) internal view returns (address, uint24) {
        if (tokenA == tokenB) {
            return (address(0), 0);
        }
        for (uint256 i = 0; i < fees.length; i++) {
            address pool = factory.getPool(tokenA, tokenB, fees[i]);
            if (pool != address(0)) {
                return (pool, fees[i]);
            }
        }
        return (address(0), 0);
    }

    function swap(address tokenA, address tokenB, uint256 amount, address recipient) external override payable returns (uint256) {
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amount), "UniswapperV3/transfer-failed");
        IERC20(tokenA).approve(address(amm), amount);

        (,uint24 fee) = getBestFees(tokenA, tokenB);
        require(fee != 0, "UniswapperV3/no-pool");

        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams(
        {
            tokenIn : tokenA,
            tokenOut : tokenB,
            fee : fee,
            recipient : recipient,
            amountIn : amount,
            amountOutMinimum : 0,
            sqrtPriceLimitX96 : 0
        });
        return amm.exactInputSingle(params);
    }

    function isTokenSupported(address bridgeToken, address token) public override view returns(bool) {
        if (bridgeToken == token) {
            return true;
        } else {
            (address pool,) = getBestFees(bridgeToken, token);
            return pool != address(0);
        }
    }

    function isTokensSupported(address bridgeToken, address[] memory tokens) external override view returns(bool[] memory) {
        bool[] memory results = new bool[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            results[i] = isTokenSupported(bridgeToken, tokens[i]);
        }
        return results;
    }

    function isPairsSupported(address[][] calldata tokens) external override view returns(bool[] memory) {
        bool[] memory results = new bool[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            (address pool,) = getBestFees(tokens[i][0], tokens[i][1]);
            results[i] = pool != address(0);
        }
        return results;
    }

    // do not used on-chain, gas inefficient!
    function quote(address tokenA, address tokenB, uint256 amount) external override returns (uint256) {
        (, uint24 fee) = getBestFees(tokenA, tokenB);
        return quoter.quoteExactInputSingle(
            tokenA, tokenB, fee, amount, 0
        );
    }
}