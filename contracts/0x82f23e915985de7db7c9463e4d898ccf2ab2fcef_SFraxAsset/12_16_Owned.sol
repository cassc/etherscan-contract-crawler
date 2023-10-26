// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

// ==========================================================
// ======================= Owned.sol ========================
// ==========================================================

import "../Sweep/ISweep.sol";

contract Owned {
    ISweep public immutable sweep;

    // Errors
    error NotGovernance();
    error NotMultisigOrGov();
    error ZeroAddressDetected();

    constructor(address _sweep) {
        if(_sweep == address(0)) revert ZeroAddressDetected();

        sweep = ISweep(_sweep);
    }

    modifier onlyGov() {
        if (msg.sender != sweep.owner()) revert NotGovernance();
        _;
    }

    modifier onlyMultisigOrGov() {
        if (msg.sender != sweep.fastMultisig() && msg.sender != sweep.owner())
            revert NotMultisigOrGov();
        _;
    }
}