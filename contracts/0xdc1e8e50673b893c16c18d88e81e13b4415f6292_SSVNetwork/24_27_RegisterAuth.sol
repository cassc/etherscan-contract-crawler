// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import "../interfaces/ISSVNetworkCore.sol";
import "./Types.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

struct Authorization {
    bool registerOperator;
    bool registerValidator;
}

library RegisterAuth {
    uint256 constant SSV_STORAGE_POSITION = uint256(keccak256("ssv.network.storage.auth")) - 1;

    struct AuthData {
        mapping(address => Authorization) authorization;
    }

    function load() internal pure returns (AuthData storage ad) {
        uint256 position = SSV_STORAGE_POSITION;
        assembly {
            ad.slot := position
        }
    }
}