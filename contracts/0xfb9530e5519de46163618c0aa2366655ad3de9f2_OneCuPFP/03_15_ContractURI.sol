// SPDX-License-Identifier: MIT
// Creator: @casareafer at 1TM.io
pragma solidity ^0.8.17;

contract ContractURI {
    string internal contractURI_ = "";

    function _setContractURI(string memory _contractURI) internal {
        contractURI_ = _contractURI;
    }

    function contractURI() external view returns (string memory) {
        return contractURI_;
    }
}