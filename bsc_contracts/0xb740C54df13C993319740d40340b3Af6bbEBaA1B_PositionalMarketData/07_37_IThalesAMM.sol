// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

import "./IPriceFeed.sol";

interface IThalesAMM {
    enum Position {
        Up,
        Down
    }

    function manager() external view returns (address);

    function availableToBuyFromAMM(address market, Position position) external view returns (uint);

    function impliedVolatilityPerAsset(bytes32 oracleKey) external view returns (uint);

    function buyFromAmmQuote(
        address market,
        Position position,
        uint amount
    ) external view returns (uint);

    function buyFromAMM(
        address market,
        Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage
    ) external returns (uint);

    function availableToSellToAMM(address market, Position position) external view returns (uint);

    function sellToAmmQuote(
        address market,
        Position position,
        uint amount
    ) external view returns (uint);

    function sellToAMM(
        address market,
        Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage
    ) external returns (uint);

    function isMarketInAMMTrading(address market) external view returns (bool);

    function price(address market, Position position) external view returns (uint);

    function buyPriceImpact(
        address market,
        Position position,
        uint amount
    ) external view returns (int);

    function priceFeed() external view returns (IPriceFeed);
}