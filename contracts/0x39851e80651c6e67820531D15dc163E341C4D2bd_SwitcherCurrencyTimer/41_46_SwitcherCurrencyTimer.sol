// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../governance/monetary/Lockup.sol";
import "../governance/monetary/RandomInflation.sol";
import "../governance/monetary/CurrencyGovernance.sol";
import "../governance/CurrencyTimer.sol";

/** @title SwitcherCurrencyTimer
 * Delegate call function data contract for setter functions
 */
contract SwitcherCurrencyTimer is CurrencyTimer {
    address public constant TEST_FILL =
        0xDEADBEeFbAdf00dC0fFee1Ceb00dAFACEB00cEc0;

    // this is for use in test, the values are unused
    constructor()
        CurrencyTimer(
            Policy(TEST_FILL),
            CurrencyGovernance(TEST_FILL),
            RandomInflation(TEST_FILL),
            Lockup(TEST_FILL),
            ECO(TEST_FILL)
        )
    {}

    /** Function for changing the address of the governance contract for subsequent generations
     *
     * This is executed in the storage context of the CurrencyTimer contract by the proposal.
     *
     * @param _newBordaImpl The address of the new governance template contract.
     */
    function setBordaImpl(CurrencyGovernance _newBordaImpl) public {
        bordaImpl = _newBordaImpl;
    }

    /** Function for changing the address of the lockup contract for subsequent generations
     *
     * This is executed in the storage context of the CurrencyTimer contract by the proposal.
     *
     * @param _newLockupImpl The address of the new lockup template contract.
     */
    function setLockupImpl(Lockup _newLockupImpl) public {
        lockupImpl = _newLockupImpl;
    }

    /** Function for changing the address of the inflation contract for subsequent generations
     *
     * This is executed in the storage context of the CurrencyTimer contract by the proposal.
     *
     * @param _newInflationImpl The address of the new inflation template contract.
     */
    function setInflationImpl(RandomInflation _newInflationImpl) public {
        inflationImpl = _newInflationImpl;
    }
}