/// SPDX-License-Identifier: MIT
/// (c) Theori, Inc. 2022
/// All rights reserved

import "../lib/Facts.sol";

pragma solidity >=0.8.0;

/**
 * @title IBatchProver
 * @author Theori, Inc.
 * @notice IBatchProver is a standard interface implemented by some Relic provers.
 *         Supports proving multiple facts ephemerally or proving and storing
 *         them in the Reliquary.
 */
interface IBatchProver {
    /**
     * @notice prove multiple facts ephemerally
     * @param proof the encoded proof, depends on the prover implementation
     * @param store whether to store the facts in the reliquary
     * @return facts the proven facts' information
     */
    function proveBatch(bytes calldata proof, bool store)
        external
        payable
        returns (Fact[] memory facts);
}