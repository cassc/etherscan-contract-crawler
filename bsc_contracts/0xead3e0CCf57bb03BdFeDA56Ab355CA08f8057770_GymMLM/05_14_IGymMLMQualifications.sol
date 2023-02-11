// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IGymMLMQualifications {
    struct RockstarLevel {
        uint64 qualificationLevel;
        uint64 usdAmountVault;
        uint64 usdAmountFarm;
        uint64 usdAmountPool;
    }

    function addDirectPartner(address, address) external;

    function getUserCurrentLevel(address) external view returns (uint32);

    function directPartners(address) external view returns (address[] memory);

    function getRockstarAmount(uint32 _rank) external view returns (RockstarLevel memory);

    function updateRockstarRank(
        address,
        uint8,
        bool
    ) external;

    function getDirectPartners(address) external view returns (address[] memory);
}