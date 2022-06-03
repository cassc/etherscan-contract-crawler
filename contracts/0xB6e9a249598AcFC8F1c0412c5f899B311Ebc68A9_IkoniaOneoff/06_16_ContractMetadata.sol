// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";

/// @custom:version 1.0.0
/// @custom:security-contact [email protected]
abstract contract ContractMetadata is AccessControl {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bool public uriFinalized = false;
    string private _contractURI = "";

    modifier notFinalizedURI {
        require(uriFinalized == false, "URI has been finalized");
        _;
   }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory newURI)
        external
        onlyRole(URI_SETTER_ROLE)
        notFinalizedURI
    {
        _contractURI = newURI;
    }

    function finalizeURI()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        notFinalizedURI
    {
        uriFinalized = true;
    }
}