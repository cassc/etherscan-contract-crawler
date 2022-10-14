pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

// Contracts
import "../TellerV2.sol";

contract TellerV2__Goerli_Commitment_Forwarder_Fix is TellerV2 {
    constructor(address _trustedForwarder) TellerV2(_trustedForwarder) {}

    function setLenderCommitmentForwarder(address _lenderCommitmentForwarder)
        external
    {
        require(
            lenderCommitmentForwarder == address(0),
            "Teller: lender commitment forwarder already set"
        );
        lenderCommitmentForwarder = _lenderCommitmentForwarder;
    }
}