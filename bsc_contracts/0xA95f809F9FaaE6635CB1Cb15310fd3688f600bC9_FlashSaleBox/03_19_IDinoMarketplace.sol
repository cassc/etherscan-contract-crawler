// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IDinoMarketplace {
    function createEgg(
        uint256 _eggGenes,
        uint256 _readyHatchAt,
        address _owner
    ) external returns (uint256);

    function getEggDetail(uint256 _eggId)
        external
        view
        returns (
            uint256 genes,
            address owner,
            uint256 createdAt,
            uint256 readyHatchAt,
            uint256 readyAtBlock,
            bool isAvailable
        );

    function disableEgg(uint256 _eggId) external;
}