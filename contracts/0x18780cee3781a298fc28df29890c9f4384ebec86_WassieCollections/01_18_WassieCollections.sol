// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ERC1155} from "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155URIStorage} from "lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Counters} from "lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import {Base64} from "lib/openzeppelin-contracts/contracts/utils/Base64.sol";

import {IWassieCollections, CreateCollectionParams} from "./IWassieCollections.sol";

import "./errors.sol";

contract WassieCollections is IWassieCollections, ERC1155URIStorage, AccessControl {
    using Strings for uint256;
    using Counters for Counters.Counter;

    //
    // state
    //
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// next ID to mind
    Counters.Counter private nextID;

    /// collections details
    mapping(uint256 => CollectionDetails) public collections;

    /// Constructor
    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    //
    // Manager API
    //
    function createCollection(CreateCollectionParams memory _details)
        external
        onlyRole(MANAGER_ROLE)
        returns (uint16 id)
    {
        nextID.increment();
        id = uint16(nextID.current());

        // validate args
        if (
            _details.minter == address(0) || _details.mintableSupply == 0 || bytes(_details.name).length == 0
                || bytes(_details.revealedURI).length == 0 || bytes(_details.unrevealedURI).length == 0
        ) {
            revert InvalidArguments();
        }

        collections[id] = IWassieCollections.CollectionDetails({
            id: id,
            minter: _details.minter,
            totalSupply: 0,
            mintableSupply: _details.mintableSupply,
            ownerSupply: _details.ownerSupply,
            revealed: false,
            name: _details.name,
            revealedURI: _details.revealedURI,
            unrevealedURI: _details.unrevealedURI
        });
        _setURI(id, _details.unrevealedURI);

        emit Created(id);
    }

    //
    // Public API
    //

    /// @inheritdoc IWassieCollections
    function collectionDetails(uint16 _id) external view override returns (CollectionDetails memory) {
        if (collections[_id].id == 0) {
            revert InvalidCollection();
        }
        return collections[_id];
    }

    /// @inheritdoc IWassieCollections
    function reveal(uint16 _id) external {
        CollectionDetails storage details = collections[_id];

        if (msg.sender != details.minter) {
            revert NotMinter();
        }

        if (details.revealed) {
            revert AlreadyRevealed();
        }

        details.revealed = true;
        _setURI(_id, details.revealedURI);

        emit Revealed(_id);
    }

    /// @inheritdoc IWassieCollections
    function mint(uint16 _collection, address _to, uint256 _amount) external {
        CollectionDetails storage details = collections[_collection];

        if (msg.sender != details.minter) {
            revert NotMinter();
        }

        // decrements mintable supply
        // will overflow if going past the limit, which is desirable here
        // cannot be unchecked
        details.mintableSupply -= uint32(_amount);

        // updating existing total supply is safely unchecked
        unchecked {
            details.totalSupply += uint32(_amount);
        }
        _mint(_to, uint256(_collection), _amount, "");
    }

    function mintOwner(uint16 _collection, address _to, uint256 _amount) external onlyRole(MANAGER_ROLE) {
        CollectionDetails storage details = collections[_collection];

        // decrements owner supply
        // will overflow if going past the limit, which is desirable here
        // cannot be unchecked
        details.ownerSupply -= uint32(_amount);

        // updating existing total supply is safely unchecked
        unchecked {
            details.totalSupply += uint32(_amount);
        }
        _mint(_to, uint256(_collection), _amount, "");
    }

    //
    // ERC165
    //

    /// @dev See {IERC165-supportsInterface}
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}