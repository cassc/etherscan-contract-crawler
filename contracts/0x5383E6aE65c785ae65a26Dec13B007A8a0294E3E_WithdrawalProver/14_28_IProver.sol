/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

import "../lib/Facts.sol";

pragma solidity >=0.8.12;

/**
 * @title IProver
 * @author Theori, Inc.
 * @notice IProver is a standard interface implemented by some Relic provers.
 *         Supports proving a fact ephemerally or proving and storing it in the
 *         Reliquary.
 */
interface IProver {
    /**
     * @notice prove a fact ephemerally
     * @param proof the encoded proof, depends on the prover implementation
     * @param store whether to store the facts in the reliquary
     * @return fact the proven fact information
     */
    function prove(bytes calldata proof, bool store) external payable returns (Fact memory fact);
}