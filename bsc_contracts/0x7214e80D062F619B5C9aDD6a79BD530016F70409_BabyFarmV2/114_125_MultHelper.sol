// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/IBabyPair.sol';
import '../interfaces/IFactory.sol';

contract MultHelper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint constant public PRICE_BASE = 1e18;

    IFactory[] public factories;
    address public immutable defaultBaseToken;

    constructor(IFactory[] memory _factories, address _defaultBaseToken) {
        factories = _factories;
        defaultBaseToken = _defaultBaseToken;
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'LibraryLibraryE: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'LibraryLibraryE: ZERO_ADDRESS');
    }

    function getPrice(address token, address baseToken) public view returns (uint) {
        if (token == baseToken) {
            return PRICE_BASE;
        }
        uint price;
        uint maxReserve0;
        for (uint i = 0; i < factories.length; i ++) {
            address pair = factories[i].getPair(token, baseToken);
            if (pair == address(0)) {
                continue;
            }
            (uint reserve0, uint reserve1, ) = IBabyPair(pair).getReserves();
            (address token0, ) = sortTokens(token, baseToken);
            if (token0 == baseToken) {
                (reserve0, reserve1) = (reserve1, reserve0);
            }
            if (reserve0 > maxReserve0) {
                uint tokenDecimal = ERC20(token).decimals();
                uint baseTokenDecimal = ERC20(baseToken).decimals();
                if (tokenDecimal < baseTokenDecimal) {
                    price = reserve1.mul(PRICE_BASE).div(reserve0).div(10 ** (baseTokenDecimal - tokenDecimal));
                } else {
                    price = reserve1.mul(PRICE_BASE).mul(10 ** (baseTokenDecimal - tokenDecimal)).div(reserve0);
                }
                maxReserve0 = reserve0;
            }
        }
        return price;
    }

    function getPrices(address[] memory tokens, address baseToken) external view returns(uint[] memory prices) {
        prices = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i ++) {
            prices[i] = getPrice(tokens[i], baseToken);
        }
    }

    function getDefaultPrices(address[] memory tokens) external view returns(uint[] memory prices) {
        prices = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i ++) {
            prices[i] = getPrice(tokens[i], defaultBaseToken);
        }
    }

    function getBalanceAndDefaultPrices(address user, address[] memory tokens) external view returns(uint[] memory balances, uint[] memory prices, uint[] memory decimals) {
        balances = new uint[](tokens.length);
        prices = new uint[](tokens.length);
        decimals = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i ++) {
            balances[i] = IERC20(tokens[i]).balanceOf(user);
            balances[i] = IERC20(tokens[i]).balanceOf(user);
            decimals[i] = ERC20(tokens[i]).decimals();
            prices[i] = getPrice(tokens[i], defaultBaseToken);
        }
    }

}