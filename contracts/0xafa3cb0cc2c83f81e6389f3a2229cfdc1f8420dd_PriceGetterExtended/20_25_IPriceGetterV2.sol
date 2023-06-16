// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "./swap-v2-lib/IApeFactory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

interface IPriceGetterV2 {
    enum Protocol {
        __,
        Both,
        V2,
        V3
    }

    function getLPPriceV2(address lp) external view returns (uint256 price);

    function getLPPricesV2(address[] calldata tokens) external view returns (uint256[] memory prices);

    function getLPPriceV2FromFactory(IApeFactory factoryV2, address lp) external view returns (uint256 price);

    function getLPPricesV2FromFactory(
        IApeFactory factoryV2,
        address[] calldata tokens
    ) external view returns (uint256[] memory prices);

    function getLPPriceV3(address token0, address token1, uint24 fee) external view returns (uint256 price);

    function getLPPricesV3(
        address[] calldata tokens0,
        address[] calldata tokens1,
        uint24[] calldata fees
    ) external view returns (uint256[] memory prices);

    function getLPPriceV3FromFactory(
        IUniswapV3Factory factoryV3,
        address token0,
        address token1,
        uint24 fee
    ) external view returns (uint256 price);

    function getLPPricesV3FromFactory(
        IUniswapV3Factory factoryV3,
        address[] calldata tokens0,
        address[] calldata tokens1,
        uint24[] calldata fees
    ) external view returns (uint256[] memory prices);

    function getPriceV2(address token) external view returns (uint256 price);

    function getPriceV2FromFactory(IApeFactory factoryV2, address token) external view returns (uint256 price);

    function getPriceV3(address token) external view returns (uint256 price);

    function getPriceV3FromFactory(IUniswapV3Factory factoryV3, address token) external view returns (uint256 price);

    function getPrice(address token, Protocol protocol) external view returns (uint256 price);

    function getPrices(address[] calldata tokens, Protocol protocol) external view returns (uint256[] memory prices);

    function getPriceFromFactory(
        address token,
        Protocol protocol,
        IApeFactory factoryV2,
        IUniswapV3Factory factoryV3
    ) external view returns (uint256 price);

    function getPricesFromFactory(
        address[] calldata tokens,
        Protocol protocol,
        IApeFactory factoryV2,
        IUniswapV3Factory factoryV3
    ) external view returns (uint256[] memory prices);

    function getNativePrice(Protocol protocol) external view returns (uint256 price);

    function getNativePriceFromFactory(
        Protocol protocol,
        IApeFactory factoryV2,
        IUniswapV3Factory factoryV3
    ) external view returns (uint256 price);
}