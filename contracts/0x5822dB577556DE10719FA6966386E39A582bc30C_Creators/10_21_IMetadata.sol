// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IControllable} from "./IControllable.sol";
import {IMetadataResolver} from "./IMetadataResolver.sol";
import {IAnnotated} from "./IAnnotated.sol";
import {ICommonErrors} from "./ICommonErrors.sol";
import {IPausable} from "./IPausable.sol";

interface IMetadata is IMetadataResolver, IPausable, IControllable, IAnnotated {
    event SetCustomURI(uint256 indexed tokenId, string customURI);
    event SetCustomResolver(uint256 indexed tokenId, IMetadataResolver customResolver);
    event SetCollectionOwner(address collection, address owner);
    event SetCreators(address oldCreators, address newCreators);
    event SetTokenURIBase(string oldBaseURI, string newBaseURI);
    event SetContractURIBase(string oldBaseURI, string newBaseURI);
    event SetDefaultCollectionOwner(address oldOwner, address newOwner);

    /// @notice Contract metadata URI for the given contract address.
    /// @param _contract address of contract.
    /// @return Metadata URI string.
    function contractURI(address _contract) external view returns (string memory);

    /// @notice Metadata URI for the given token ID.
    /// @param tokenId uint256 token ID.
    /// @return Metadata URI string.
    function uri(uint256 tokenId) external view returns (string memory);

    /// @notice Set a custom metadata URI for the given token ID. May only be
    /// called by `creators` contract.
    /// @param tokenId uint256 token ID.
    /// @param customURI string metadata URI.
    function setCustomURI(uint256 tokenId, string memory customURI) external;

    /// @notice Set a custom metadata resolver contract for the given token ID.
    /// May only be called by `creators` contract.
    /// @param tokenId uint256 token ID.
    /// @param customResolver IMetadataResolver address of a contract
    /// implementing IMetadataResolver interface.
    function setCustomResolver(uint256 tokenId, IMetadataResolver customResolver) external;

    /// @notice Set the token metadata base URI. Base URI will be concatenated
    /// with token ID and '.json' to produce a full metadata URI.
    /// May only be called by `controller` contract.
    /// @param _tokenURIBase Default URI string.
    function setTokenURIBase(string memory _tokenURIBase) external;

    /// @notice Set the contract metadata base URI. Base URI will be concatenated
    /// with contract address in hex and '.json' to produce a full metadata URI.
    /// May only be called by `controller` contract.
    /// @param _contractURIBase Default URI string.
    function setContractURIBase(string memory _contractURIBase) external;

    /// @notice Set the default collection owner. Emint1155 tokens will return
    /// this address as their owner by default. The owner address has no special
    /// permissions at the contract level, but may manage the collection on
    /// storefronts like OpenSea. May only be called by `controller` contract.
    /// @param _owner address of default owner.
    function setDefaultCollectionOwner(address _owner) external;

    /// @notice Set the collection owner for a specific collection by address.
    /// Used to override the default owner if necessary. May only be called by
    /// `controller` contract.
    /// @param collection address of token contract.
    /// @param _owner address of owner.
    function setCollectionOwner(address collection, address _owner) external;

    /// @notice Get the owner of a collection by address.
    /// @param collection address of token contract.
    /// @return address of owner.
    function owner(address collection) external view returns (address);
}