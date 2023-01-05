/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import {RecursiveProof} from "../lib/Proofs.sol";

/**
 * @title Verifier of zk-SNARK proofs
 * @author Theori, Inc.
 * @notice Provider of validity checking of zk-SNARKs
 */
interface IRecursiveVerifier {
    /**
     * @notice Checks the validity of SNARK data
     * @param proof the proof to verify
     * @return the validity of the proof
     */
    function verify(RecursiveProof calldata proof) external view returns (bool);
}