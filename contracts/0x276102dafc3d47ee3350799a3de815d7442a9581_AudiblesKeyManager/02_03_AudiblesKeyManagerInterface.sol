// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface AudiblesKeyManagerInterface {
    event PhaseTokenUpgrade(
        uint256 indexed tokenId,
        bytes32 indexed originalData,
        bytes32 indexed newData
    );

    function increaseKeys(
        address minter,
        uint8 gridSize,
        uint8 quantity
    ) external;

    function increaseKeysBurn(address minter) external;

    function increaseKeysInscribe(address minter) external;

    function getPhaseKeys(uint16 quantity) external;

    function phaseOneUpgrade(
        uint256 tokenId,
        bytes32 originalData,
        bytes32 newData
    ) external;

    function phaseTwoUpgrade(
        uint256 tokenId,
        bytes32 originalData,
        bytes32 newData
    ) external;

    function unlockUploadImage() external;

    function batchIncreaseKeys(
        address[] calldata minters,
        uint16[] calldata amounts
    ) external;

    function setKeysPerGrid() external;
}

interface AudiblesKeyManagerIncreaseKeysInterface {
    function increaseKeys(
        address minter,
        uint8 gridSize,
        uint8 quantity
    ) external;

    function increaseKeysBurn(address minter) external;

    function increaseKeysInscribe(address minter) external;
}