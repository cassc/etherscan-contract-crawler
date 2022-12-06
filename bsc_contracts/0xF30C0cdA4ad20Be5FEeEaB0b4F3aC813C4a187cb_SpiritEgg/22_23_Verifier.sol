// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../libraries/SafeOwnableInterface.sol';

abstract contract Verifier is SafeOwnableInterface {

    event VerifierChanged(address oldVerifier, address newVerifier);

    address public verifier;

    function setVerifier(address _verifier) external onlyOwner {
        _setVerifier(_verifier);
    }

    function _setVerifier(address _verifier) internal {
        require(_verifier != address(0), "illegal verifier");
        emit VerifierChanged(verifier, _verifier);
        verifier = _verifier;
    }

}