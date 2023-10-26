// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Offer, ApiCoSignedPayload} from "../DataStructure/Objects.sol";

interface ISignature {
    function offerDigest(Offer memory offer) external view returns (bytes32);

    function apiCoSignedPayloadDigest(ApiCoSignedPayload memory apiPayload) external view returns (bytes32);
}