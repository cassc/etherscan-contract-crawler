// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract OSContractURI {

    string internal _contractURI;

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string calldata uri) virtual public {
        _contractURI = uri;
    }
}