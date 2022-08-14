// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PiratesMetadata is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    
    mapping(uint8 => EnumerableSet.UintSet) piratesForTribe;
    mapping(uint256 => uint8) tribeForPirate;

    function getCountForTribe(uint8 tribe) external view returns (uint256) {
        return piratesForTribe[tribe].length();
    }

    function addOneToTribe(uint8 tribe, uint256 pirateId) external onlyOwner {
        piratesForTribe[tribe].add(pirateId);
        tribeForPirate[pirateId] = tribe;
    }

    function addManyToTribe(uint8 tribe, uint256[] calldata pirateIds) external onlyOwner {
     for (uint8 i; i < pirateIds.length; i++) {
            piratesForTribe[tribe].add(pirateIds[i]);
            tribeForPirate[pirateIds[i]] =  tribe;
        }
    }

    function removeOnefromTribe(uint8 tribe, uint256 pirateId) external onlyOwner {
        piratesForTribe[tribe].remove(pirateId);
        delete tribeForPirate[pirateId];
    }

    function removeManyFromTribe(uint8 tribe, uint256[] calldata pirateIds) external onlyOwner {
     for (uint8 i; i < pirateIds.length; i++) {
            piratesForTribe[tribe].remove(pirateIds[i]);
            delete tribeForPirate[pirateIds[i]];
        }
    }

    // Don't call in transaction, O(N)
    //
    function getPiratesForTribe(uint8 tribe) external view returns (uint256[] memory) {
        uint length = piratesForTribe[tribe].length();
        uint256[] memory result = new uint256[](length);
        for (uint256 i; i < length; i++) {
            result[i] = piratesForTribe[tribe].at(i);
        }
        return result;
    }

    function getTribeForPirate(uint256 pirateId) external view returns (uint8) {
        return tribeForPirate[pirateId];
    }

}