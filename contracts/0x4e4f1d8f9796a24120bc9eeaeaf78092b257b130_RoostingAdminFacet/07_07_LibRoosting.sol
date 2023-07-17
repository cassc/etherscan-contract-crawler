// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library LibRoosting {
    using BitMaps for BitMaps.BitMap;

    bytes32 constant ROOSTING_STORAGE_POSITION = keccak256("owls.roosting.storage");
    bytes32 constant ROOSTING_CYCLE_STORAGE_OFFSET = 0xF100000000000000000000000000000000000000000000000000000000000000;
    bytes32 constant ROOSTING_GROUP_STORAGE_OFFSET = 0xF200000000000000000000000000000000000000000000000000000000000000;
    bytes32 constant ROOSTING_GROUP_OWLS_STORAGE_OFFSET = 0xF300000000000000000000000000000000000000000000000000000000000000;
    uint256 constant ROOSTING_GROUP_OWLS_ID_MASK = 0x000000000000000000000000000000000000000000000000000000000000FFFF;
    enum RoostingCycle { Preroosting, Roosting, Postroosting }
    enum RoostingState { NotRoosted, Roosted, RoostingClaimed }

    error InvalidArrayLength();
    error NotRoostingAdmin();

    struct RoostingStorage {
        RoostingCycle roostingCycle;
        uint32 currentRoostingCycle;
        mapping(address => bool) roostingAdmins;
    }

    struct RoostingCycleStorage {
        uint16 roostingGroupSize;
        uint16 numRoosted;
        BitMaps.BitMap tokenIdsRoosted;
    }

    struct RoostingGroupStorage {
        address roostedBy;
        uint16 owlsRoosted;
        RoostingState roostingState;
    }

    struct RoostingGroupOwlsStorage {
        uint256 owlIds; //packed owl token ids, 16 bits per owl id
    }

    struct RoostingViewData {
        uint32 roostingCycleId;
        uint16 roostingGroupSize;
        uint16 numRoosted;
        RoostingGroupStorage[] roostingGroups;
        uint256[][] roostingGroupOwlIds;
    }

    function roostingStorage() internal pure returns (RoostingStorage storage rs) {
        bytes32 position = ROOSTING_STORAGE_POSITION;
        assembly {
            rs.slot := position
        }
    }

    function roostingCycleStorage(uint32 roostingCycleIndex) internal pure returns (RoostingCycleStorage storage rcs) {
        bytes32 offset = ROOSTING_CYCLE_STORAGE_OFFSET;
        assembly {
            rcs.slot := add(offset, roostingCycleIndex)
        }
    }

    /// @notice get the roosting group by the roosting cycle and the 1-based roosting group index
    function roostingGroupStorage(uint32 roostingCycleIndex, uint32 roostingGroupIndex) internal pure returns (RoostingGroupStorage storage rgs) {
        bytes32 offset = ROOSTING_GROUP_STORAGE_OFFSET;
        assembly {
            rgs.slot := add(add(offset, shl(32,roostingCycleIndex)), roostingGroupIndex)
        }
    }

    /// @notice get the roosting group owls based on the cycle index and the roosting group index (1 based index)
    function roostingGroupOwls(uint32 roostingCycleIndex, uint32 roostingGroupIndex) internal view returns (uint256[] memory owlIds) {
        RoostingGroupStorage storage rgs = roostingGroupStorage(roostingCycleIndex, roostingGroupIndex);
        RoostingGroupOwlsStorage storage rgos;
        owlIds = new uint256[](rgs.owlsRoosted);

        uint256 storageSlots = rgs.owlsRoosted / 16 + 1;
        uint256 owlIdIndex;
        bytes32 offset = ROOSTING_GROUP_OWLS_STORAGE_OFFSET;
        for(uint256 i;i < storageSlots;) {
            assembly {
                rgos.slot := add(add(add(offset, shl(64,roostingCycleIndex)), shl(32, roostingGroupIndex)), i)
            }
            uint256 tmpOwlIds = rgos.owlIds;
            for(uint256 j;j < 16;) {
                unchecked {
                    owlIds[owlIdIndex] = tmpOwlIds & ROOSTING_GROUP_OWLS_ID_MASK;
                    tmpOwlIds >>= 16;
                    ++owlIdIndex;
                    ++j;
                    if(owlIdIndex == rgs.owlsRoosted) { break; }
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function setRoostingGroupOwls(uint32 roostingCycleIndex, uint32 roostingGroupIndex, uint256[] memory owlIds) internal {
        RoostingGroupOwlsStorage storage rgos;

        uint256 storageSlots = owlIds.length / 16 + 1;
        uint256 owlIdIndex;
        bytes32 offset = ROOSTING_GROUP_OWLS_STORAGE_OFFSET;
        for(uint256 i;i < storageSlots;) {
            assembly {
                rgos.slot := add(add(add(offset, shl(64,roostingCycleIndex)), shl(32, roostingGroupIndex)), i)
            }
            uint256 tmpOwlIds;
            for(uint256 j;j < 16;) {
                unchecked {
                    tmpOwlIds |= owlIds[owlIdIndex] << (16 * j);
                    ++owlIdIndex;
                    ++j;
                    if(owlIdIndex == owlIds.length) { break; }
                }
            }
            rgos.owlIds = tmpOwlIds;
            unchecked {
                ++i;
            }
        }
    }

    function getRoostingKey(uint256[] memory tokenIds) internal pure returns (string memory) {
        if(tokenIds.length == 0) { revert InvalidArrayLength(); }
        bytes memory groupKey = abi.encodePacked(Strings.toString(tokenIds[0]));

        for (uint256 tIdx = 1; tIdx < tokenIds.length;) {
            groupKey = abi.encodePacked(groupKey,"_",Strings.toString(tokenIds[tIdx]));

            unchecked {
                ++tIdx;
            }
        }

        return string(groupKey);
    }

    function isTokenRoosted(uint256 tokenId) internal view returns (bool) {
        return isTokenRoosted(roostingStorage().currentRoostingCycle, tokenId);
    }

    function isTokenRoosted(uint32 roostingCycleIndex, uint256 tokenId) internal view returns (bool) {
        return roostingCycleStorage(roostingCycleIndex).tokenIdsRoosted.get(tokenId);
    }

    function setIsTokenRoosted(uint256 tokenId) internal {
         roostingCycleStorage(roostingStorage().currentRoostingCycle).tokenIdsRoosted.set(tokenId); 
    }

    function enforceIsRoostingAdmin() internal view {
        if (!roostingStorage().roostingAdmins[msg.sender]) { revert NotRoostingAdmin(); }
    }
}