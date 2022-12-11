// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MuonClientBase.sol";

contract MuonClient is MuonClientBase {
    constructor(uint256 _muonAppId, PublicKey memory _muonPublicKey) {
        validatePubKey(_muonPublicKey.x);

        muonAppId = _muonAppId;
        muonPublicKey = _muonPublicKey;
    }
}