// SPDX-License-Identifier: MIT

/// @title Interface for Ultra Sound Editions
/// @author -wizard

pragma solidity ^0.8.6;

import {IUltraSoundGridRenderer} from "./IUltraSoundGridRenderer.sol";
import {IUltraSoundDescriptor} from "./IUltraSoundDescriptor.sol";

interface IUltraSoundEditions {
    error LevelsMustMatch(uint256 tokenOneLevel, uint256 tokenTwoLevel);
    error ExceedsMaxLevel(uint16 level, uint256 maxLevel);
    error MustBeUltraSound(uint256 tokenId);
    error MustBeTokenOwner(address token, uint256 tokenId);
    error ContractNotOperator();
    error OnReceivedRequestFailure();
    error CannotRestore();
    error TooMany();

    event Redeemed(uint256 tokenId);
    event RedeemedMultiple(uint256[] tokenId);
    event Merged(uint256 tokenId, uint256 tokenIdBurned);
    event Swapped(uint256 tokenId, uint256 swappedTokenId);
    event Restored(uint256 tokenId, address by);
    event MetadataUpdate(uint256 _tokenId);
    event DescriptorUpdated(address orignal, address replaced);
    event ProofOfWorkUpdated(address orignal, address replaced);
    event UltraSoundBaseFeeUpdated(uint256 orignal, uint256 replaced);

    struct Edition {
        bool ultraSound;
        bool burned;
        uint32 seed;
        uint8 level;
        uint8 palette;
        uint32 blockNumber;
        uint64 baseFee;
        uint64 blockTime;
        uint16 mergeCount;
        uint16 ultraEdition;
    }

    function pause() external;

    function unpause() external;

    function setDescriptor(IUltraSoundDescriptor _descriptor) external;

    function setUltraSoundBaseFee(uint256 _baseFee) external;

    function toggleDegenMode() external;

    function restored() external view returns (uint256);

    function isUltraSound(uint256 tokenId)
        external
        view
        returns (bool ultraSound);

    function levelOf(uint256 tokenId) external view returns (uint256 level);

    function levelsOf(uint256[] calldata tokenIds)
        external
        view
        returns (uint256[] memory);

    function mergeCountOf(uint256 tokenId)
        external
        view
        returns (uint256 mergeCount);

    function edition(uint256 tokenId)
        external
        view
        returns (
            bool ultraSound,
            bool burned,
            uint32 seed,
            uint8 level,
            uint8 palette,
            uint32 blockNumber,
            uint64 baseFee,
            uint64 blockTime,
            uint16 mergeCount,
            uint16 ultraEdition
        );

    function mint(uint256 tokenId) external;

    function mintBulk(uint256[] calldata tokenId) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function tokenSVG(uint256 tokenId, uint8 size)
        external
        view
        returns (string memory);
}

interface IERC721Burn {
    function burn(uint256 tokenId) external;
}