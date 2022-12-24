// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import './SafeOwnableInterface.sol';

abstract contract Verifier is SafeOwnableInterface {

    event VerifierChanged(address oldVerifier, address newVerifier);

    address public verifier;

    constructor(address _verifier) {
        require(_verifier != address(0), "illegal verifier");
        verifier = _verifier;
        emit VerifierChanged(address(0), _verifier);
    }

    function setVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "illegal verifier");
        emit VerifierChanged(verifier, _verifier);
        verifier = _verifier;
    }

}