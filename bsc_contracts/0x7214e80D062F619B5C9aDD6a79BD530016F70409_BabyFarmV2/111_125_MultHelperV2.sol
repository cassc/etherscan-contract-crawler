// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/IBabyPair.sol';
import '../interfaces/IFactory.sol';

contract MultHelperV2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint constant public PRICE_BASE = 1e18;

    IFactory[] public factories;
    address public defaultBaseToken;
    address[] public middleTokens;

    constructor(IFactory[] memory _factories, address[] memory _middleTokens, address _defaultBaseToken) {
        factories = _factories;
        middleTokens = _middleTokens;
        defaultBaseToken = _defaultBaseToken;
    }

    function setDefaultBaseToken(address _defaultBaseToken) external onlyOwner {
        defaultBaseToken = _defaultBaseToken;
    }

    function addFactory(IFactory _factory) external onlyOwner {
        factories.push(_factory);
    }

    function delFactory(IFactory _factory) external onlyOwner {
        uint index = uint(-1);
        for (uint i = 0; i < factories.length; i ++) {
            if (factories[i] == _factory) {
                index = i;
                break;
            }
        }
        if (index != uint(-1)) {
            if (index == factories.length - 1) {
                factories[index] = factories[factories.length - 1];
            }
            factories.pop();
        }
    }

    function addMiddleTokens(address _middleToken) external onlyOwner {
        middleTokens.push(_middleToken);
    }

    function delMiddleTokens(address _middleToken) external onlyOwner {
        uint index = uint(-1);
        for (uint i = 0; i < middleTokens.length; i ++) {
            if (middleTokens[i] == _middleToken) {
                index = i;
                break;
            }
        }
        if (index != uint(-1)) {
            if (index == middleTokens.length - 1) {
                middleTokens[index] = middleTokens[middleTokens.length - 1];
            }
            middleTokens.pop();
        }
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'LibraryLibraryE: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'LibraryLibraryE: ZERO_ADDRESS');
    }

    function getPriceByPair(address pair, address token, address baseToken) internal view returns (uint price, uint tokenReserve) {
        (uint reserve0, uint reserve1, ) = IBabyPair(pair).getReserves();
        (address token0, ) = sortTokens(token, baseToken);
        if (token0 != token) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        if (reserve0 == 0 || reserve1 == 0) {
            return (0, 0);
        }
        uint tokenDecimal = ERC20(token).decimals();
        uint baseTokenDecimal = ERC20(baseToken).decimals();
        if (tokenDecimal < baseTokenDecimal) {
            price = reserve1.mul(PRICE_BASE).div(reserve0).div(10 ** (baseTokenDecimal - tokenDecimal));
        } else {
            price = reserve1.mul(PRICE_BASE).mul(10 ** (baseTokenDecimal - tokenDecimal)).div(reserve0);
        }
        tokenReserve = reserve0;
    }

    function getMiddleTokenPrice(address token, address baseToken) public view returns (uint price) {
        if (token == baseToken) {
            return PRICE_BASE;
        }
        uint maxReserve;
        for (uint i = 0; i < factories.length; i ++) {
            address pair = factories[i].getPair(token, baseToken);
            if (pair == address(0)) {
                continue;
            }
            (uint currentPrice, uint currentReserve) = getPriceByPair(pair, token, baseToken);
            if (currentReserve > maxReserve) {
                price = currentPrice;
                maxReserve = currentReserve;
            }
        }
    }

    function getTokenPrice(address token, address baseToken) public view returns (uint price) {
        if (token == baseToken) {
            return PRICE_BASE;
        }
        uint maxReserve;
        for (uint i = 0; i < factories.length; i ++) {
            for (uint j = 0; j < middleTokens.length; j ++) {
                address pair = factories[i].getPair(token, middleTokens[j]);
                if (pair == address(0)) {
                    continue;
                }
                (uint currentPrice, uint currentReserve) = getPriceByPair(pair, token, middleTokens[j]);
                if (currentReserve > maxReserve) {
                    price = currentPrice.mul(getMiddleTokenPrice(middleTokens[j], baseToken)).div(PRICE_BASE); 
                    maxReserve = currentReserve;
                }
            }
        }
    }

    function getLpPrice(address lp, address baseToken) public view returns (uint price) {
        (uint reserve0, uint reserve1, ) = IBabyPair(lp).getReserves();
        uint value = 0;
        address token = IBabyPair(lp).token0();
        price = getTokenPrice(token, baseToken);
        if (price != 0) {
            uint decimals = ERC20(token).decimals();
            value = reserve0.mul(price).mul(2).div(PRICE_BASE).div(10 ** decimals);
        } else {
            token = IBabyPair(lp).token1();
            price = getTokenPrice(token, baseToken);
            if (price == 0) {
                return 0;
            }
            uint decimals = ERC20(token).decimals();
            value = reserve1.mul(price).mul(2).div(PRICE_BASE).div(10 ** decimals);
        }
        uint totalSupply = IBabyPair(lp).totalSupply();
        return value.mul(PRICE_BASE).mul(PRICE_BASE).div(totalSupply);
    }

    function getTokenPrices(address[] memory tokens, address baseToken) external view returns(uint[] memory prices) {
        prices = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i ++) {
            prices[i] = getTokenPrice(tokens[i], baseToken);
        }
    }

    function getLpPrices(address[] memory tokens, address baseToken) external view returns(uint[] memory prices) {
        prices = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i ++) {
            prices[i] = getLpPrice(tokens[i], baseToken);
        }
    }

    function getDefaultTokenPrices(address[] memory tokens) external view returns(uint[] memory prices) {
        prices = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i ++) {
            prices[i] = getTokenPrice(tokens[i], defaultBaseToken);
        }
    }

    function getDefaultLpPrices(address[] memory tokens) external view returns(uint[] memory prices) {
        prices = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i ++) {
            prices[i] = getLpPrice(tokens[i], defaultBaseToken);
        }
    }

    function getBalanceAndDefaultTokenPrices(address user, address[] memory tokens) external view returns(uint[] memory balances, uint[] memory prices, uint[] memory decimals) {
        balances = new uint[](tokens.length);
        prices = new uint[](tokens.length);
        decimals = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i ++) {
            balances[i] = IERC20(tokens[i]).balanceOf(user);
            balances[i] = IERC20(tokens[i]).balanceOf(user);
            decimals[i] = ERC20(tokens[i]).decimals();
            prices[i] = getTokenPrice(tokens[i], defaultBaseToken);
        }
    }

    function getBalanceAndDefaultLpPrices(address user, address[] memory tokens) external view returns(uint[] memory balances, uint[] memory prices, uint[] memory decimals) {
        balances = new uint[](tokens.length);
        prices = new uint[](tokens.length);
        decimals = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i ++) {
            balances[i] = IERC20(tokens[i]).balanceOf(user);
            balances[i] = IERC20(tokens[i]).balanceOf(user);
            decimals[i] = ERC20(tokens[i]).decimals();
            prices[i] = getLpPrice(tokens[i], defaultBaseToken);
        }
    }
}