// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITreasury {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getRadiancePrice() external view returns (uint256);

    function buyBonds(uint256 amount, uint256 targetPrice) external;

    function redeemBonds(uint256 amount, uint256 targetPrice) external;

    function getBurnableRadianceLeft()
        external
        view
        returns (uint256 _burnableRadianceLeft);

    function epochSupplyContractionLeft() external view returns (uint256);
}