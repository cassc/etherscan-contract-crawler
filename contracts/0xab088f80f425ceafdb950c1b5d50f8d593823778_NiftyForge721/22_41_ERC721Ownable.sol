//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';

import '../OpenSea/BaseOpenSea.sol';

/// @title ERC721Ownable
/// @author Simon Fremaux (@dievardump)
contract ERC721Ownable is OwnableUpgradeable, ERC721Upgradeable, BaseOpenSea {
    /// @notice modifier that allows higher level contracts to define
    ///         editors that are not only the owner
    modifier onlyEditor(address sender) virtual {
        require(sender == owner(), '!NOT_EDITOR!');
        _;
    }

    /// @notice constructor
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param owner_ Address to whom transfer ownership (can be address(0), then owner is deployer)
    function __ERC721Ownable_init(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address owner_
    ) internal initializer {
        __Ownable_init();
        __ERC721_init_unchained(name_, symbol_);

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

    /// @notice Allows gas-less trading on OpenSea by safelisting the Proxy of the user
    /// @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
    /// @inheritdoc	ERC721Upgradeable
    function isApprovedForAll(address owner_, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // allows gas less trading on OpenSea
        return
            super.isApprovedForAll(owner_, operator) ||
            isOwnersOpenSeaProxy(owner_, operator);
    }

    /// @notice Helper for the owner of the contract to set the new contract URI
    /// @dev needs to be owner
    /// @param contractURI_ new contract URI
    function setContractURI(string memory contractURI_)
        external
        onlyEditor(msg.sender)
    {
        _setContractURI(contractURI_);
    }

    /// @notice Helper for the owner to set OpenSea's proxy (allowing or not gas-less trading)
    /// @dev needs to be owner
    /// @param osProxyRegistry new opensea proxy registry
    function setOpenSeaRegistry(address osProxyRegistry)
        external
        onlyEditor(msg.sender)
    {
        _setOpenSeaRegistry(osProxyRegistry);
    }
}