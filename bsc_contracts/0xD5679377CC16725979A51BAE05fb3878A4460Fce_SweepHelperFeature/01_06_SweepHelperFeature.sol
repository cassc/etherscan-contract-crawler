/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ISweepHelperFeature.sol";
import "./IPancakeRouter.sol";
import "./IUniswapQuoter.sol";


contract SweepHelperFeature is ISweepHelperFeature {

    address public immutable WETH;
    IPancakeRouter public immutable PancakeRouter;
    IUniswapQuoter public immutable UniswapQuoter;

    constructor(address weth, IPancakeRouter pancakeRouter, IUniswapQuoter uniswapQuoter) {
        WETH = weth;
        PancakeRouter = pancakeRouter;
        UniswapQuoter = uniswapQuoter;
    }

    function getSwpHelpInfos(
        address account,
        address operator,
        SwpHelpParam[] calldata params
    ) external override returns (SwpHelpInfo[] memory infos) {
        address[] memory path = new address[](2);

        infos = new SwpHelpInfo[](params.length);
        for (uint i; i < params.length; i++) {
            address erc20Token = params[i].erc20Token;

            infos[i].erc20Token = erc20Token;
            if (erc20Token == address(0)) {
                infos[i].balance = account.balance;
                infos[i].allowance = type(uint256).max;
            } else {
                infos[i].balance = balanceOf(erc20Token, account);
                infos[i].allowance = allowanceOf(erc20Token, account, operator);
            }
            infos[i].decimals = decimals(erc20Token);
            uint256 amountIn = 10 ** infos[i].decimals;

            SwpRateInfo[] memory rates = new SwpRateInfo[](params.length);
            infos[i].rates = rates;
            for (uint j; j < params.length; j++) {
                address token = params[j].erc20Token;
                rates[j].token = token;
                if (
                    token == erc20Token ||
                    token == address(0) && erc20Token == WETH ||
                    token == WETH && erc20Token == address(0)
                ) {
                    rates[j].tokenOutAmount = amountIn;
                    continue;
                }

                address tokenA = erc20Token == address(0) ? WETH : erc20Token;
                address tokenB = token == address(0) ? WETH : token;
                if (address(PancakeRouter) != address(0)) {
                    path[0] = tokenA;
                    path[1] = tokenB;
                    rates[j].tokenOutAmount = getAmountsOut(amountIn, path);
                } else if (address(UniswapQuoter) != address(0)) {
                    rates[j].tokenOutAmount = quoteExactInputSingle(tokenA, tokenB, params[i].fee, amountIn);
                }
            }
        }
        return infos;
    }

    function balanceOf(address erc20, address account) internal view returns (uint256 balance) {
        try IERC20(erc20).balanceOf(account) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }

    function decimals(address erc20) internal view returns (uint8) {
        if (erc20 == address(0) || erc20 == WETH) {
            return 18;
        }
        try IERC20Metadata(erc20).decimals() returns (uint8 _decimals) {
            return _decimals;
        } catch {
        }
        return 18;
    }

    function allowanceOf(address erc20, address owner, address spender) internal view returns (uint256 allowance) {
        try IERC20(erc20).allowance(owner, spender) returns (uint256 _allowance) {
            allowance = _allowance;
        } catch {
        }
        return allowance;
    }

    function getAmountsOut(uint256 amountIn, address[] memory path) internal view returns (uint256 amount) {
        try PancakeRouter.getAmountsOut(amountIn, path) returns (uint256[] memory _amounts) {
            amount = _amounts[1];
        } catch {
        }
        return amount;
    }

    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        try UniswapQuoter.quoteExactInputSingle(
            tokenIn,
            tokenOut,
            fee,
            amountIn,
            0
        ) returns (uint256 _amountOut) {
            amountOut = _amountOut;
        } catch {
        }
        return amountOut;
    }
}