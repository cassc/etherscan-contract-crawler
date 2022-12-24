// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../governance/monetary/RandomInflation.sol";
import "../governance/monetary/InflationRootHashProposal.sol";
import "../VDF/VDFVerifier.sol";

/** @title SwitcherRandomInflation
 * Delegate call function data contract for setter functions
 */
contract SwitcherRandomInflation is RandomInflation {
    address public constant TEST_FILL =
        0xDEADBEeFbAdf00dC0fFee1Ceb00dAFACEB00cEc0;

    // this is for use in test, the values are unused
    constructor()
        RandomInflation(
            Policy(TEST_FILL),
            VDFVerifier(TEST_FILL),
            1, // random difficulty
            InflationRootHashProposal(TEST_FILL),
            ECO(TEST_FILL)
        )
    {}

    /** Function for changing the address of the inflation root hash contract for subsequent generations
     *
     * This is executed in the storage context of the RandomInflation contract by the proposal.
     *
     * @param _newIRHPImpl The address of the new inflation template contract.
     */
    function setIRHPImpl(InflationRootHashProposal _newIRHPImpl) public {
        inflationRootHashProposal = _newIRHPImpl;
    }
}