// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../pricefeed/IPriceFeed.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ICurrencyFeed {
    struct Currency {
        string   symbol;
        uint8    decimals;
        IERC20   tokenContract;
        address  priceContract;
        uint256  roundThreshold;
        bool     enabled;
    }

    struct Price {
        uint256 unitPrice;
        IPriceFeed.PriceRound priceRound;
        Currency currency;
    }

    function setPriceFeed(address priceFeed) external;
    function getPrice(string memory symbol) external view returns (Price memory);
    function getPrice(string memory symbol, uint80 roundId) external view returns (Price memory);
}