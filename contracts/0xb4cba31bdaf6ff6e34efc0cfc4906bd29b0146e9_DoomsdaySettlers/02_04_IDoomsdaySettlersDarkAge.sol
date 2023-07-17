// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

interface IDoomsdaySettlersDarkAge {
    function checkVulnerable(uint32 _tokenId) external view returns (bool);
    function getUnusedFees(uint32 _tokenId) external view returns (uint80);
    function disaster(uint32 _tokenId, uint256 _totalSupply) external returns(uint8 _type, bool destroyed);
    function reinforce(
        uint32 _tokenId,
        bytes32 _tokenHash,
        bool[4] memory _resources,
        bool _isDarkAge
    ) external returns (uint80 _cost);
}