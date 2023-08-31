// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1967Proxy} from "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import {
    OwnableAccessControlUpgradeable,
    NotRoleOrOwner
} from "tl-sol-tools/upgradeable/access/OwnableAccessControlUpgradeable.sol";
import {IERC721} from "openzeppelin/interfaces/IERC721.sol";

/*//////////////////////////////////////////////////////////////////////////
                            Collector's Choice
//////////////////////////////////////////////////////////////////////////*/

/// @title CollectorsChoice.sol
/// @notice the doppelganger contract with a twist where the ability to change URIs is locked after a time period
/// @dev this works for only ERC721TL contracts, implementation contract should reflect that
/// @author transientlabs.xyz
/// @custom:version 2.6.0
contract CollectorsChoice is ERC1967Proxy {
    /*//////////////////////////////////////////////////////////////////////////
                                    Constants
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // bytes32(uint256(keccak256('erc721.tl.collectorschoice')) - 1);
    bytes32 public constant METADATA_STORAGE_SLOT = 0x42e4ec1f98e793b22ce6d3d94dac69be208b1022748a25a29587cf3b64c7a04c;

    /*//////////////////////////////////////////////////////////////////////////
                                    Events
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Event emitted when a new URI is added
    event NewURIAdded(address indexed sender, string newUri, uint256 index);

    /// @notice ERC-4906 event for when metadata is changed
    event MetadataUpdate(uint256 tokenId);

    /*//////////////////////////////////////////////////////////////////////////
                                    Errors
    //////////////////////////////////////////////////////////////////////////*/

    error Unauthorized();

    error MetadataSelectionDoesNotExist(uint256 selection);

    /*//////////////////////////////////////////////////////////////////////////
                                    Structs
    //////////////////////////////////////////////////////////////////////////*/

    struct CollectorsChoiceStorage {
        mapping(uint256 => uint256) tokens;
        string[] uris;
        uint256 uriChangeCutoff;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    Constructor
    //////////////////////////////////////////////////////////////////////////*/

    /// @param name: the name of the contract
    /// @param symbol: the symbol of the contract
    /// @param defaultRoyaltyRecipient: the default address for royalty payments
    /// @param defaultRoyaltyPercentage: the default royalty percentage of basis points (out of 10,000)
    /// @param initOwner: initial owner of the contract
    /// @param admins: array of admin addresses to add to the contract
    /// @param enableStory: a bool deciding whether to add story fuctionality or not
    /// @param blockListRegistry: address of the blocklist registry to use
    constructor(
        address implementation,
        string memory name,
        string memory symbol,
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address initOwner,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
        ERC1967Proxy(
            implementation,
            abi.encodeWithSelector(
                0x1fbd2402, // selector for "initialize(string,string,address,uint256,address,address[],bool,address)"
                name,
                symbol,
                defaultRoyaltyRecipient,
                defaultRoyaltyPercentage,
                initOwner,
                admins,
                enableStory,
                blockListRegistry
            )
        )
    {}

    /*//////////////////////////////////////////////////////////////////////////
                                Admin Write Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to add URIs to the URI array
    /// @dev requires contract admin or owner
    /// @param _newURIs: string array of URIs
    function addNewURIs(string[] calldata _newURIs) external {
        if (
            msg.sender != OwnableAccessControlUpgradeable(address(this)).owner()
                && !OwnableAccessControlUpgradeable(address(this)).hasRole(ADMIN_ROLE, msg.sender)
        ) {
            revert Unauthorized();
        }

        CollectorsChoiceStorage storage store;

        assembly {
            store.slot := METADATA_STORAGE_SLOT
        }

        for (uint256 i = 0; i < _newURIs.length; i++) {
            store.uris.push(_newURIs[i]);

            emit NewURIAdded(msg.sender, _newURIs[i], store.uris.length);
        }
    }

    /// @notice function to set the cutoff timestamp after which token URIs cannot be changed
    /// @dev requires contract admin or owner
    /// @dev cannot be set more than once
    /// @param _cutoffDatetime: timestamp in seconds after which the owners of the tokens cannot change URI
    function setCutoff(uint256 _cutoffDatetime) external {
        if (
            msg.sender != OwnableAccessControlUpgradeable(address(this)).owner()
                && !OwnableAccessControlUpgradeable(address(this)).hasRole(ADMIN_ROLE, msg.sender)
        ) {
            revert Unauthorized();
        }

        CollectorsChoiceStorage storage store;

        assembly {
            store.slot := METADATA_STORAGE_SLOT
        }

        if (store.uriChangeCutoff != 0) revert Unauthorized();

        store.uriChangeCutoff = _cutoffDatetime;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Public Write Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function for token owners to change URI for their token
    /// @dev requires msg.sender is the owner of tokenId
    /// @dev cannot change the URI after the uri change cutoff timestamp
    /// @param tokenId: token id of the token to change the URI for
    /// @param tokenUriIndex: index in the the array of the URI to point the token to
    function changeURI(uint256 tokenId, uint256 tokenUriIndex) external {
        if (IERC721(address(this)).ownerOf(tokenId) != msg.sender) revert Unauthorized();

        CollectorsChoiceStorage storage store;

        assembly {
            store.slot := METADATA_STORAGE_SLOT
        }

        if (tokenUriIndex >= store.uris.length) revert MetadataSelectionDoesNotExist(tokenUriIndex);

        if (store.uriChangeCutoff != 0 && block.timestamp > store.uriChangeCutoff) revert Unauthorized();

        store.tokens[tokenId] = tokenUriIndex;

        emit MetadataUpdate(tokenId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                External View Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to override the ERC-721 tokenURI function
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        IERC721(address(this)).ownerOf(tokenId);

        CollectorsChoiceStorage storage store;

        assembly {
            store.slot := METADATA_STORAGE_SLOT
        }

        uint256 uri_index = store.tokens[tokenId];

        return store.uris[uri_index];
    }

    /// @notice function to return how many URIs are on the contract
    /// @return uint256 with that number
    function numURIs() external view returns (uint256) {
        CollectorsChoiceStorage storage store;

        assembly {
            store.slot := METADATA_STORAGE_SLOT
        }

        return store.uris.length;
    }

    /// @notice function to get the uri change cutoff timestamp
    /// @return uint256 with that timestamp
    function getCutoff() external view returns (uint256) {
        CollectorsChoiceStorage storage store;

        assembly {
            store.slot := METADATA_STORAGE_SLOT
        }

        return store.uriChangeCutoff;
    }

    /// @notice function to get an array of all available URIs on the contract
    /// @return string array of URIs
    function viewURIOptions() external view returns (string[] memory) {
        CollectorsChoiceStorage storage store;

        assembly {
            store.slot := METADATA_STORAGE_SLOT
        }

        string[] memory options = new string[](store.uris.length);

        for (uint256 i = 0; i < store.uris.length; i++) {
            options[i] = store.uris[i];
        }

        return options;
    }
}