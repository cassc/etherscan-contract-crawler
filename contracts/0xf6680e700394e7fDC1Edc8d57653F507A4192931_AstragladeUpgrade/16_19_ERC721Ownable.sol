//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import './OpenSea/BaseOpenSea.sol';

/// @title ERC721Ownable
/// @author Simon Fremaux (@dievardump)
contract ERC721Ownable is Ownable, ERC721Enumerable, BaseOpenSea {
    /// @notice constructor
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param owner_ Address to whom transfer ownership (can be address(0), then owner is deployer)
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address owner_
    ) ERC721(name_, symbol_) {
        // set contract uri if present
        if (bytes(contractURI_).length > 0) {
            _setContractURI(contractURI_);
        }

        // set OpenSea proxyRegistry for gas-less trading if present
        if (address(0) != openseaProxyRegistry_) {
            _setOpenSeaRegistry(openseaProxyRegistry_);
        }

        // transferOwnership if needed
        if (address(0) != owner_) {
            transferOwnership(owner_);
        }
    }

    /// @notice Allows to burn a tokenId
    /// @dev Burns `tokenId`. See {ERC721-_burn}.  The caller must own `tokenId` or be an approved operator.
    /// @param tokenId the tokenId to burn
    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721Burnable: caller is not owner nor approved'
        );
        _burn(tokenId);
    }

    /// @notice Allows gas-less trading on OpenSea by safelisting the Proxy of the user
    /// @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
    /// @inheritdoc	ERC721
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // allows gas less trading on OpenSea
        if (isOwnersOpenSeaProxy(owner, operator)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /// @notice Helper for the owner of the contract to set the new contract URI
    /// @dev needs to be owner
    /// @param contractURI_ new contract URI
    function setContractURI(string memory contractURI_) external onlyOwner {
        _setContractURI(contractURI_);
    }
}