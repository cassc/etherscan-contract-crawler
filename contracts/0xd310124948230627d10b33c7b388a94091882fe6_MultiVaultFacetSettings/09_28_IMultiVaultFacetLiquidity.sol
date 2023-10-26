// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultFacetLiquidity {
    struct Liquidity {
        uint activation;
        uint supply;
        uint cash;
        uint interest;
    }

    function mint(
        address token,
        uint amount,
        address receiver
    ) external;

    function redeem(
        address token,
        uint amount,
        address receiver
    ) external;

    function exchangeRateCurrent(
        address token
    ) external view returns(uint);

    function getCash(
        address token
    ) external view returns(uint);

    function getSupply(
        address token
    ) external view returns(uint);

    function getLPToken(
        address token
    ) external view returns (address);

    function setTokenInterest(
        address token,
        uint interest
    ) external;

    function setDefaultInterest(
        uint interest
    ) external;

    function liquidity(
        address token
    ) external view returns (Liquidity memory);

    function convertLPToUnderlying(
        address token,
        uint amount
    ) external view returns (uint);

    function convertUnderlyingToLP(
        address token,
        uint amount
    ) external view returns (uint);
}