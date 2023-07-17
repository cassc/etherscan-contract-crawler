// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { LibRoosting } from "../libraries/LibRoosting.sol";
import { LibOwls } from "../libraries/LibOwls.sol";

contract RoostingFacet {
    event Roosted(uint256[] tokenIds, LibRoosting.RoostingState roosted);
    event RoostingCycleChange(LibRoosting.RoostingCycle roostingCycle);

    error RoostingNotEnabled();
    error InvalidRoostingGroupSize();
    error OwlAlreadyRoosted();
    error NotOwnerOfOwl(); 
    error IdsNotSorted();

    function _roost(uint256[] calldata tokenIds) internal {
        LibRoosting.RoostingStorage storage rs = LibRoosting.roostingStorage();
        LibRoosting.RoostingCycleStorage storage rcs = LibRoosting.roostingCycleStorage(rs.currentRoostingCycle);
        if(rs.roostingCycle != LibRoosting.RoostingCycle.Preroosting) { revert RoostingNotEnabled(); }
        if(tokenIds.length != rcs.roostingGroupSize) { revert InvalidRoostingGroupSize(); }

        uint256 prev;
        for (uint256 tIdx; tIdx < tokenIds.length;) {
            uint256 id = tokenIds[tIdx];

            if(LibRoosting.isTokenRoosted(id)) { revert OwlAlreadyRoosted(); }
            if(IERC721(LibOwls.owlsStorage().owlsContract).ownerOf(id) != msg.sender) { revert NotOwnerOfOwl(); }
            LibRoosting.setIsTokenRoosted(id);

            if (tIdx > 0) {
                if(id < prev) { revert IdsNotSorted(); }
            }
            prev = id;

            unchecked {
                ++tIdx;
            }
        }

        unchecked {
            ++rcs.numRoosted;
        }
        LibRoosting.RoostingGroupStorage storage rgs = LibRoosting.roostingGroupStorage(rs.currentRoostingCycle, rcs.numRoosted);
        rgs.roostedBy = msg.sender;
        rgs.owlsRoosted = uint16(tokenIds.length);
        rgs.roostingState = LibRoosting.RoostingState.Roosted;
        LibRoosting.setRoostingGroupOwls(rs.currentRoostingCycle, rcs.numRoosted, tokenIds);
        emit Roosted(tokenIds, LibRoosting.RoostingState.Roosted);
    }

    /// @notice Roost a group of owls into the tree of life
    /// @param tokenIds Contains the token ids to roost in sorted order
    function roost(uint256[] calldata tokenIds) external {
        _roost(tokenIds);
    }

    /// @notice Roost multiple groups of owls into the tree of life
    /// @param groups Contains the token ids to roost in sorted order for each group
    function roostMultiple(uint256[][] calldata groups) external {
        for (uint256 gIdx; gIdx < groups.length;) {
            _roost(groups[gIdx]);

            unchecked {
                ++gIdx;
            }
        }
    }

    /// @notice Starts the roosting cycle for owls registered in the preroosting phase
    function roosting() external {
        LibRoosting.enforceIsRoostingAdmin();

        LibRoosting.roostingStorage().roostingCycle = LibRoosting.RoostingCycle.Roosting;
        emit RoostingCycleChange(LibRoosting.RoostingCycle.Roosting);
    }

    /// @notice Resets all roosting state to prepare for the next roost
    function preroosting(uint16 roostingGroupSize) external {
        LibRoosting.enforceIsRoostingAdmin();
        LibRoosting.RoostingStorage storage rs = LibRoosting.roostingStorage();
        unchecked {
            ++rs.currentRoostingCycle;
            rs.roostingCycle = LibRoosting.RoostingCycle.Preroosting;
        }
        LibRoosting.RoostingCycleStorage storage rcs = LibRoosting.roostingCycleStorage(rs.currentRoostingCycle);
        rcs.roostingGroupSize = roostingGroupSize;

        emit RoostingCycleChange(LibRoosting.RoostingCycle.Preroosting);
    }

    /// @notice Post roosting stops the roosting cycle
    function postroosting() external {
        LibRoosting.enforceIsRoostingAdmin();

        LibRoosting.roostingStorage().roostingCycle = LibRoosting.RoostingCycle.Postroosting;
        emit RoostingCycleChange(LibRoosting.RoostingCycle.Postroosting);
    }

    function getAllRoostingGroups() external view returns (string[] memory) {
        LibRoosting.RoostingStorage storage rs = LibRoosting.roostingStorage();
        LibRoosting.RoostingCycleStorage storage rcs = LibRoosting.roostingCycleStorage(rs.currentRoostingCycle);
        string[] memory roostingGroups = new string[](rcs.numRoosted);
        for(uint32 i = 0;i < rcs.numRoosted;) {
            uint256[] memory owlIds = LibRoosting.roostingGroupOwls(rs.currentRoostingCycle, i+1);
            string memory groupKey = LibRoosting.getRoostingKey(owlIds);
            roostingGroups[i] = groupKey;
            unchecked {
                ++i;
            }
        }
        return roostingGroups;
    }

    function getTotalRoosted() external view returns (uint16) {
        return this.getTotalRoosted(LibRoosting.roostingStorage().currentRoostingCycle);
    }

    function getTotalRoosted(uint32 roostingCycleIndex) external view returns (uint16) {
        return LibRoosting.roostingCycleStorage(roostingCycleIndex).numRoosted;
    }

    function getRoostingGroup(uint256[] calldata tokenIds) external view returns (LibRoosting.RoostingState) {
        LibRoosting.RoostingStorage storage rs = LibRoosting.roostingStorage();
        LibRoosting.RoostingCycleStorage storage rcs = LibRoosting.roostingCycleStorage(rs.currentRoostingCycle);

        bytes32 findGroupKey = keccak256(abi.encodePacked(tokenIds));
        for(uint32 i = 0;i < rcs.numRoosted;) {
            LibRoosting.RoostingGroupStorage storage rgs = LibRoosting.roostingGroupStorage(rs.currentRoostingCycle, i+1);
            uint256[] memory owlIds = LibRoosting.roostingGroupOwls(rs.currentRoostingCycle, i+1);
            bytes32 groupKey = keccak256(abi.encodePacked(owlIds));
            if(findGroupKey == groupKey) {
                return rgs.roostingState;
            }
            unchecked {
                ++i;
            }
        }
        return LibRoosting.RoostingState.NotRoosted;
    }

    function getRoostingGroupByIndex(uint32 roostingCycleIndex, uint32 roostingGroupIndex) external view returns (uint256[] memory owlsIds) {
        owlsIds = LibRoosting.roostingGroupOwls(roostingCycleIndex, roostingGroupIndex);
    }

    function _getRoostingViewData(uint32 cycleNumber) internal view returns (LibRoosting.RoostingViewData memory rvd) {
        LibRoosting.RoostingCycleStorage storage rcs = LibRoosting.roostingCycleStorage(cycleNumber);

        rvd.roostingCycleId = cycleNumber;
        rvd.roostingGroupSize = rcs.roostingGroupSize;
        rvd.numRoosted = rcs.numRoosted;

        LibRoosting.RoostingGroupStorage[] memory rgs = new LibRoosting.RoostingGroupStorage[](rcs.numRoosted);
        uint256[][] memory rgoids = new uint256[][](rcs.numRoosted);
        for(uint32 j = 0;j < rcs.numRoosted;) {
            rgs[j] = LibRoosting.roostingGroupStorage(cycleNumber, j+1);
            uint256[] memory owlIds = LibRoosting.roostingGroupOwls(cycleNumber, j+1);
            rgoids[j] = owlIds;
            unchecked {
                ++j;
            }
        }
        rvd.roostingGroups = rgs;
        rvd.roostingGroupOwlIds = rgoids;
    }

    function getRoostingViewData() external view returns (LibRoosting.RoostingViewData[] memory rvd) {
        LibRoosting.RoostingStorage storage rs = LibRoosting.roostingStorage();
        rvd = new LibRoosting.RoostingViewData[](rs.currentRoostingCycle+1);
        for(uint32 i;i < rs.currentRoostingCycle;) {
            rvd[i] = _getRoostingViewData(i+1);
            unchecked {
                ++i;
            }
        }
    }

    function getCurrentRoostingViewData() external view returns (LibRoosting.RoostingViewData memory rvd) {
        rvd = _getRoostingViewData(LibRoosting.roostingStorage().currentRoostingCycle);
    }

    function getRoostingCycle() external view returns (LibRoosting.RoostingCycle) {
        return LibRoosting.roostingStorage().roostingCycle;
    }

    function getCurrentRoostingCycleIndex() external view returns (uint32) {
        return LibRoosting.roostingStorage().currentRoostingCycle;
    }

    function getRoostingGroupSize() external view returns (uint16) {
        return LibRoosting.roostingCycleStorage(LibRoosting.roostingStorage().currentRoostingCycle).roostingGroupSize;
    }

    function getRoostingGroupSize(uint32 roostingCycle) external view returns (uint16) {
        return LibRoosting.roostingCycleStorage(roostingCycle).roostingGroupSize;
    }
}