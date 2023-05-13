// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 *  @notice IGenesis is interface of genesis token
 */
interface IGenesis {
    struct GenesisInfo {
        TypeId typeId;
        uint256 slotId;
    }

    function DENOMINATOR() external view returns (uint256);

    function getGenesisInfoOf(uint256 tokenId) external view returns (GenesisInfo calldata);

    function mint(address receiver) external returns (uint256);

    function mintBatch(address receiver, uint256 times) external returns (uint256[] memory);
}

enum TypeId {
    APPRENTICE_ANGEL,
    ANGEL,
    CHIEF_ANGEL,
    GOD,
    CREATOR_GOD
}