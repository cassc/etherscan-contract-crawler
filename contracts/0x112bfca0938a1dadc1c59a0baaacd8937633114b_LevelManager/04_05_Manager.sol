//SPDX-License-Identifier: LICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;

contract Manager {
    address public immutable cardContract;

    constructor(address _cardContract) {
        cardContract = _cardContract;
    }

    /// modifier functions
    modifier onlyFromCardContract() {
        require(msg.sender == cardContract, "oc");
        _;
    }
}