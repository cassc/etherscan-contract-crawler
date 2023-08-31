// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IPriceOracle {
    function exchangePrice(
        address _token
    ) external view returns (uint256 price, uint8 decimals);

    function exchangeRate(
        address token
    ) external view returns (uint256 exchangeRate);

    function getValueOf(
        address tokenIn,
        address quote,
        uint256 amountIn
    ) external view returns (uint256 value);
}

abstract contract PriceOracle is IPriceOracle, Ownable {
    mapping(address => address) internal priceFeed;
    mapping(address => uint256) internal decimals;
    address public constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    function setPriceFeed(
        address token,
        address aggregator
    ) external onlyOwner {
        require(aggregator != address(0), "Invalid aggregator address");
        priceFeed[token] = aggregator;
    }

    function exchangePrice(
        address token
    ) public view virtual override returns (uint256 price, uint8 decimals);

    function exchangeRate(
        address token
    ) external view virtual override returns (uint256 price) {
        price = getValueOf(NATIVE_TOKEN, token, 1 ether);
        require(price != 0, "Price Oracle: Price is 0");
    }

    function getValueOf(
        address tokenIn,
        address quote,
        uint256 amountIn
    ) public view virtual override returns (uint256 value) {
        (uint256 priceIn, uint8 decimalsIn) = exchangePrice(tokenIn);
        (uint256 priceQuote, uint8 decimalsQuote) = exchangePrice(quote);

        if (
            decimalsIn + tokenDecimals(tokenIn) >
            decimalsQuote + tokenDecimals(quote)
        ) {
            value =
                (amountIn * priceIn) /
                (priceQuote *
                    10 **
                        (decimalsIn +
                            tokenDecimals(tokenIn) -
                            (tokenDecimals(quote) + decimalsQuote)));
        } else {
            value =
                ((amountIn * priceIn) *
                    10 **
                        (decimalsQuote +
                            tokenDecimals(quote) -
                            (tokenDecimals(tokenIn) + decimalsIn))) /
                priceQuote;
        }
    }

    function tokenDecimals(address _token) public view returns (uint256) {
        return
            decimals[_token] == 0
                ? IERC20Metadata(_token).decimals()
                : decimals[_token];
    }

    function setDecimals(address _token, uint256 _decimals) external onlyOwner {
        decimals[_token] = _decimals;
    }
}