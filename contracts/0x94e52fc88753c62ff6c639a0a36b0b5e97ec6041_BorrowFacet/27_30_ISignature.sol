// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Offer} from "../DataStructure/Objects.sol";

interface ISignature {
    function offerDigest(Offer memory offer) external view returns (bytes32);
}