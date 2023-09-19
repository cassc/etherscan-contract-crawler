// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ITeamNFTManager {
    function sportsLength() external view returns (uint256);

    function owner() external view returns (address);

    function seriesForSportLength(
        uint256 _sport
    ) external view returns (uint256);

    function sports(uint256) external view returns (string memory);

    function teamNft() external view returns (address);

    function marketplace() external view returns (address);

    function nftData(
        uint256 tokenId
    )
        external
        view
        returns (
            string memory sport,
            string memory seriesName,
            string memory cityName,
            string memory teamName,
            string memory color1,
            string memory color2
        );
}