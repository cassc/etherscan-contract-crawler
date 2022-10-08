// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IManager} from "../interfaces/IManager.sol";
import {Range} from "../structs/SArrakisV2.sol";

library Manager {
    function getManagerFeeBPS(IManager manager_) public view returns (uint16) {
        try manager_.managerFeeBPS() returns (uint16 feeBPS) {
            return feeBPS;
        } catch {
            return 0;
        }
    }
}