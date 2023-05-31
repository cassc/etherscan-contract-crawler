// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";


abstract contract OpenSeaContractAccessControl is AccessControl {

    /// The optional opensea metatdata URI
    string private _contractURI;


    /// Sets the optional opensea metadata URI
    function setContractURI(string calldata newContractURI) public onlyRole(DEFAULT_ADMIN_ROLE)  {
        _contractURI = newContractURI;
        emit ContractURIUpdated(newContractURI);
    }

    /// Returns the opensea contract metadata URI 
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Emitted when the receiver has been updated for an NFT contract
    /// @param contractURI The new contract URI. This should point to some file, preferably stored on ipfs.
    event ContractURIUpdated( string contractURI);

}