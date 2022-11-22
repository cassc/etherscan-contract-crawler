// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IBondStorage {
    function startBond(
        address _user,
        uint256 _principalSEuro,
        uint256 _principalOther,
        uint256 _rate,
        uint256 _maturity,
        uint256 _tokenId,
        uint128 _liquidity
    ) external;

    function refreshBondStatus(address _user) external;

    function claimReward() external;
}

interface IBondingEvent {
    function bond(
        address _user,
        uint256 _amountSeuro,
        uint256 _weeks,
        uint256 _rate
    ) external;
}

interface IRatioCalculator {
    function getRatioForSEuro(
        uint256 _amountSEuro,
        uint160 _price,
        int24 _lower,
        int24 _upper,
        bool _seuroIsToken0
    ) external pure returns (uint256);

    function getTickAt(uint160 _price) external pure returns (int24);
}