// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface INFTingConfig {
    function buyFee() external view returns (uint256);

    function sellFee() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function maxRoyaltyFee() external view returns (uint256);

    function treasury() external view returns (address);

    function updateFee(uint256 newBuyFee, uint256 newSellFee) external;

    function updateTreasury(address newTreasury) external;
}