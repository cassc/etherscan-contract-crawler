// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC721ContractURI is Ownable {
    /// @notice Current metadata URI for the contract
    string private _contractURI;

    /// @notice Emitted when contractURI has changed
    event ContractURIUpdated(string uri);

    /**
     * Sets the current contractURI for the contract
     *
     * @param _uri New contract URI
     */
    function setContractURI(string calldata _uri) public onlyOwner {
        _contractURI = _uri;
        emit ContractURIUpdated(_uri);
    }

    /**
     * @return Contract metadata URI for the NFT contract, used by NFT marketplaces to display collection inf
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}