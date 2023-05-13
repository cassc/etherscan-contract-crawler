pragma solidity 0.6.7;

import {GebSafeManager} from "geb-safe-manager/GebSafeManager.sol";

contract GetSafes {
    function getSafesAsc(address manager, address guy) external view returns (uint[] memory ids, address[] memory safes, bytes32[] memory collateralTypes) {
        uint count = GebSafeManager(manager).safeCount(guy);
        ids = new uint[](count);
        safes = new address[](count);
        collateralTypes = new bytes32[](count);
        uint i = 0;
        uint id = GebSafeManager(manager).firstSAFEID(guy);

        while (id > 0) {
            ids[i] = id;
            safes[i] = GebSafeManager(manager).safes(id);
            collateralTypes[i] = GebSafeManager(manager).collateralTypes(id);
            (,id) = GebSafeManager(manager).safeList(id);
            i++;
        }
    }

    function getSafesDesc(address manager, address guy) external view returns (uint[] memory ids, address[] memory safes, bytes32[] memory collateralTypes) {
        uint count = GebSafeManager(manager).safeCount(guy);
        ids = new uint[](count);
        safes = new address[](count);
        collateralTypes = new bytes32[](count);
        uint i = 0;
        uint id = GebSafeManager(manager).lastSAFEID(guy);

        while (id > 0) {
            ids[i] = id;
            safes[i] = GebSafeManager(manager).safes(id);
            collateralTypes[i] = GebSafeManager(manager).collateralTypes(id);
            (id,) = GebSafeManager(manager).safeList(id);
            i++;
        }
    }
}