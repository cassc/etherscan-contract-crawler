//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/// @title NFBaseModuleSlim
/// @author Simon Fremaux (@dievardump)
contract NFBaseModuleSlim is ERC165 {
    event NewContractURI(string contractURI);

    string private _contractURI;

    constructor(string memory contractURI_) {
        _setContractURI(contractURI_);
    }

    function contractURI() external view virtual returns (string memory) {
        return _contractURI;
    }

    function _setContractURI(string memory contractURI_) internal {
        _contractURI = contractURI_;
        emit NewContractURI(contractURI_);
    }
}