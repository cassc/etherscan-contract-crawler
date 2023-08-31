// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IContractMetadata.sol";

abstract contract ContractMetadata is IContractMetadata {
    string public override contractURI;

    function setContractURI(string memory _uri) external override {
        if (!_canSetContractURI()) {
            revert("Not authorized");
        }

        _setupContractURI(_uri);
    }

    function _setupContractURI(string memory _uri) internal {
        string memory prevURI = contractURI;
        contractURI = _uri;

        emit ContractURIUpdated(prevURI, _uri);
    }

    function _canSetContractURI() internal view virtual returns (bool);
}