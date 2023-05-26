// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "ens-contracts/wrapper/NameWrapper.sol";
import "ens-contracts/registry/ENS.sol";

/**
 * @title NamewrapperFunctions
 * @author hodl.esf.eth
 * @dev NamewrapperFunctions contract contains functions to perform batch operations on the NameWrapper contract
 * we inherit the storefront contract from this so the users don't have to performa extra approvals on
 * the NameWrapper contract.
 * @notice Contract written by ENS Vision
 */
abstract contract NamewrapperFunctions {
    NameWrapper public immutable nameWrapper;
    ENS public immutable ens;

    bytes32 private constant ETH_NODE =
        0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    constructor(NameWrapper _nameWrapper, ENS _ens) {
        nameWrapper = _nameWrapper;
        ens = _ens;
    }

    /**
     * @notice Batch Delete Subdomains
     * @dev batchDeleteSubdomains function performs a batch deletion of subdomains.
     * Can only be called by the owner of the domain(s). And will only work if the
     * PARANT_CANNOT_CONTROL fuse is not set.
     * @param _parentNamehash Hash of the parent domain
     * @param _labels Array of labels to delete
     *
     */
    function batchDeleteSubdomains(
        bytes32 _parentNamehash,
        string[] calldata _labels
    ) external {
        require(
            msg.sender == nameWrapper.ownerOf(uint256(_parentNamehash)),
            "not owner of domain"
        );

        for (uint256 i; i < _labels.length; ) {
            nameWrapper.setSubnodeRecord(
                _parentNamehash,
                _labels[i],
                address(0),
                address(0),
                0,
                0,
                0
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Batch Unwrap Subdomains
     * @dev batchUnwrapDomains function performs a batch unwrapping of domains
     *
     * @param _labelHashes Hash of just the label array
     * @param _registrant Owner of the domain
     * @param _controller Controller address
     */
    function batchUnwrapDomains(
        bytes32[] calldata _labelHashes,
        address _registrant,
        address _controller
    ) external {
        for (uint256 i; i < _labelHashes.length; ) {
            bytes32 namehash = keccak256(
                abi.encodePacked(ETH_NODE, _labelHashes[i])
            );

            require(
                nameWrapper.ownerOf(uint256(namehash)) == msg.sender,
                "not owner of domain"
            );

            nameWrapper.unwrapETH2LD(_labelHashes[i], _registrant, _controller);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Batch Update Resolver
     * @dev batchUpdateResolver function performs a batch update of the resolver, can only
     * be called by the owner of the domain(s)
     * @param _namehashIds Array of namewrapperIds
     * @param _resolver Resolver address
     */
    function batchUpdateResolver(
        uint256[] calldata _namehashIds,
        address _resolver
    ) external {
        for (uint256 i; i < _namehashIds.length; ) {
            address tokenOwner = nameWrapper.ownerOf(_namehashIds[i]);
            require(
                tokenOwner == msg.sender ||
                    (tokenOwner == address(0) &&
                        ens.owner(bytes32(_namehashIds[i])) == msg.sender),
                "not owner of domain"
            );

            if (tokenOwner == address(0)) {
                ens.setResolver(bytes32(_namehashIds[i]), _resolver);
            } else {
                nameWrapper.setResolver(bytes32(_namehashIds[i]), _resolver);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
    * @notice Batch Update Fuses
    * @dev batchSetFuses function performs a batch update of the fuses, can only
    * be called by the owner of the domain(s). 
        ```
        CANNOT_UNWRAP = 1;
        CANNOT_BURN_FUSES = 2;
        CANNOT_TRANSFER = 4;
        CANNOT_SET_RESOLVER = 8;
        CANNOT_SET_TTL = 16;
        CANNOT_CREATE_SUBDOMAIN = 32;
        ```
    * @param _nodes Array of namewrapper domain hashes
    * @param _fuses Array of fuses, uint16.
     */
    function batchSetFuses(
        bytes32[] calldata _nodes,
        uint16[] calldata _fuses
    ) external {
        for (uint256 i; i < _nodes.length; ) {
            require(
                nameWrapper.ownerOf(uint256(_nodes[i])) == msg.sender,
                "not owner of domain"
            );

            nameWrapper.setFuses(_nodes[i], _fuses[i]);
            unchecked {
                ++i;
            }
        }
    }
}