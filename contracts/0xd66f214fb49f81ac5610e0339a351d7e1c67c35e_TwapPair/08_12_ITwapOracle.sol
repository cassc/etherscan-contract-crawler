// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

interface ITwapOracle {
    event OwnerSet(address owner);
    event UniswapPairSet(address uniswapPair);

    function decimalsConverter() external view returns (int256);

    function xDecimals() external view returns (uint8);

    function yDecimals() external view returns (uint8);

    function owner() external view returns (address);

    function uniswapPair() external view returns (address);

    function getPriceInfo() external view returns (uint256 priceAccumulator, uint32 priceTimestamp);

    function getSpotPrice() external view returns (uint256);

    function getAveragePrice(uint256 priceAccumulator, uint32 priceTimestamp) external view returns (uint256);

    function setOwner(address _owner) external;

    function setUniswapPair(address _uniswapPair) external;

    function tradeX(
        uint256 xAfter,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view returns (uint256 yAfter);

    function tradeY(
        uint256 yAfter,
        uint256 yBefore,
        uint256 xBefore,
        bytes calldata data
    ) external view returns (uint256 xAfter);

    function depositTradeXIn(
        uint256 xLeft,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view returns (uint256 xIn);

    function depositTradeYIn(
        uint256 yLeft,
        uint256 yBefore,
        uint256 xBefore,
        bytes calldata data
    ) external view returns (uint256 yIn);
}