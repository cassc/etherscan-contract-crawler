// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPGenesisInterface {
    function minted() external view returns (uint256);

    function mintingDatetime(uint256) external view returns (uint256);

    function updateBullBreedings(uint256) external;

    function ownerOf(uint256) external view returns (address);

    function breedings(uint256) external view returns (uint256);

    function maxBreedings() external view returns (uint256);

    function generateGodBull() external;

    function refund(address, uint256) external payable;

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;

    function genesisTimestamp() external view returns (uint256);
}