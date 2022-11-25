pragma solidity ^0.8.0;

interface IPriceStrategy3 {
    struct PriceParams {
        uint256 DECIMAL;
        uint256 TOTAL_TEAMS;
        uint256 REF_PRICE; // decimal
        uint256 num_of_teams;
        uint256 totalShares;
        uint256 shares;
        uint256 totalLiquid; // decimal
        uint256 totalLiquidReserved; // decimal
        uint256 liquid; // decimal
        uint256 liquidReserved; // decimal
        uint256 totalStrength;
        uint256 strength;
        uint256 amount;
    }

    function ammPriceBuy(PriceParams memory _priceParams)
        external
        view
        returns (uint256);

    function ammPriceSell(PriceParams memory _priceParams)
        external
        view
        returns (uint256);
}