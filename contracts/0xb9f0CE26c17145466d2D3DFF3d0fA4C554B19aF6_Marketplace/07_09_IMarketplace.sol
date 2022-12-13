// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMarketplace {
    function buyToken(uint256 amount) external;

    function buyNFT(string memory membershipType) external;

    function setKangaPOSAddress(address kangaPOSAddress) external;

    function upsertNFTSaleTypeData(
        string memory membershipType,
        uint256 quantity,
        bool isEnabled,
        uint256 price,
        uint256 validity
    ) external;

    function remainingTokenSupply() external view returns (uint256);

    function remainingNFTSupplyByType(string memory membershipType) external view returns (uint256);

    function beTokensPriceInUSDT(uint256 amount) external view returns (uint256);
}