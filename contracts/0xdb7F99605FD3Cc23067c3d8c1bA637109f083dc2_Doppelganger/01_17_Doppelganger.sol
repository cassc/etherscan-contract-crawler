// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1967Proxy} from "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import {OwnableAccessControlUpgradeable, NotRoleOrOwner} from "tl-sol-tools/upgradeable/access/OwnableAccessControlUpgradeable.sol";
import {IERC721} from "openzeppelin/interfaces/IERC721.sol";

/// @title Doppelganger.sol
/// @notice Transient Labs Core Creator Contract
/// @dev this works for only ERC721TL contracts, implementation contract should reflect that
/// @author transientlabs.xyz
contract Doppelganger is ERC1967Proxy {

    /*//////////////////////////////////////////////////////////////////////////
                                    Constants
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // bytes32(uint256(keccak256('erc721.tl.doppelganger')) - 1);
    bytes32 public constant METADATA_STORAGE_SLOT = 0xe8e107277cf2bf4ca5b1c80e072dc96f1981a6e70d5a59566b0c646a780d487b;

    /*//////////////////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Event emitted when a new doppelganger is added.
    event NewDoppelgangerAdded(
        address indexed sender,
        string newUri,
        uint256 index
    );

    /// @notice Event emitted when a uri is cloned
    event Cloned(
        address indexed sender,
        uint256 tokenId,
        string newUri
    );

    /*//////////////////////////////////////////////////////////////////////////
                                    Error
    //////////////////////////////////////////////////////////////////////////*/

    error Unauthorized();

    error MetadataSelectionDoesNotExist(uint256 selection);

    /*//////////////////////////////////////////////////////////////////////////
                                    Structs
    //////////////////////////////////////////////////////////////////////////*/

    struct DoppelgangerStorage {
        mapping(uint256 => uint256) dopplegangTokens;
        string[] uris;
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

    function addDoppelgangers(string[] calldata _newDoppelgangers) external {
        if (msg.sender != OwnableAccessControlUpgradeable(address(this)).owner() && !OwnableAccessControlUpgradeable(address(this)).hasRole(ADMIN_ROLE, msg.sender)) {
            revert Unauthorized();
        }

        DoppelgangerStorage storage store;

        assembly {
            store.slot := METADATA_STORAGE_SLOT
        }

        for (uint256 i = 0; i < _newDoppelgangers.length; i++) {
            store.uris.push(_newDoppelgangers[i]);

            emit NewDoppelgangerAdded(msg.sender, _newDoppelgangers[i], store.uris.length);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Public Write Functions
    //////////////////////////////////////////////////////////////////////////*/

    function doppelgang(uint256 tokenId, uint256 tokenUriIndex) external {
        if (IERC721(address(this)).ownerOf(tokenId) != msg.sender) revert Unauthorized();

        DoppelgangerStorage storage store;

        assembly {
            store.slot := METADATA_STORAGE_SLOT
        }

        if (tokenUriIndex >= store.uris.length) revert MetadataSelectionDoesNotExist(tokenUriIndex);

        store.dopplegangTokens[tokenId] = tokenUriIndex;

        emit Cloned(msg.sender, tokenId, store.uris[tokenUriIndex]);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                External View Functions
    //////////////////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        IERC721(address(this)).ownerOf(tokenId);
        
        DoppelgangerStorage storage store;

        assembly {
            store.slot := METADATA_STORAGE_SLOT
        }

        uint256 uri_index = store.dopplegangTokens[tokenId];

        return store.uris[uri_index];
    }

    function numDoppelgangerURIs() external view returns (uint256) {
        DoppelgangerStorage storage store;

        assembly {
            store.slot := METADATA_STORAGE_SLOT
        }

        return store.uris.length;
    }

    function viewDoppelgangerOptions() external view returns (string[] memory) {
        DoppelgangerStorage storage store;

        assembly {
            store.slot := METADATA_STORAGE_SLOT
        }

        string[] memory options = new string[](store.uris.length);

        for (uint256 i = 0; i < store.uris.length; i ++) {
            options[i] = store.uris[i];
        }

        return options;
    }
}