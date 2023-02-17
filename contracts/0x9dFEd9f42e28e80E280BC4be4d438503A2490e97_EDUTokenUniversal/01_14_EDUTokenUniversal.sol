// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IERC721Mintable.sol";

/// @title Empatika Decentralized University Events
/// @notice Compatible with EventController which was originally desined to work with ERC-721
contract EDUTokenUniversal is ERC1155, AccessControl, IERC721Mintable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Defines how `balanceOf` and `safeMint` behaves
    /// @dev Allows this contract to be compatible with EventController
    uint256 public currentEventTokenId = 0;

    mapping(uint256 => uint256) private _supplies;

    string private _contractMetadataUri;

    constructor(
        string memory tokenMetadataBaseUri_,
        string memory contractMetadataUri_,
        uint256 initEventTokenId_
    )
        ERC1155(tokenMetadataBaseUri_)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        currentEventTokenId = initEventTokenId_;
        _contractMetadataUri = contractMetadataUri_;
    }

    /// @notice Retrieve metadata uri compatible with Opensea
    /// @return URL to fetch metadata for contract
    function contractURI()
        external
        view
        returns (string memory)
    {
        return _contractMetadataUri;
    }

    /// @notice Retrieve metadata uri compatible with Opensea
    /// @return URL to fetch metadata for the token
    function uri(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory baseUri = super.uri(tokenId);
        return string.concat(
            baseUri,
            Strings.toString(tokenId)
        );
    }

    /// @notice Retrieve the current available supply for the token
    /// @return Supply left
    function supply(uint256 tokenId_)
        external
        view
        returns (uint256)
    {
        return _supplies[tokenId_];
    }

    /// @notice Retrieve balance of the account for the `currentEventTokenId`
    /// @dev Originally it's ERC-721 function, but huddle01 uses it
    /// @return Balance of the `currentEventTokenId` for the account
    function balanceOf(address account)
        external
        view
        returns (uint256)
    {
        require(account != address(0), "Zero address");
        return balanceOf(account, currentEventTokenId);
    }

    function _beforeMint(uint256 tokenId, uint256 amount)
        internal
        view
    {
        require(_supplies[tokenId] >= amount, "No supply");
    }

    function _afterMint(uint256 tokenId, uint256 amount)
        internal
    {
        _supplies[tokenId] -= amount;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        external
        onlyRole(MINTER_ROLE)
    {
        _beforeMint(id, amount);

        _mint(account, id, amount, data);

        _afterMint(id, amount);
    }

    function mintMany(address[] calldata accounts, uint256[] calldata ids, uint256[] calldata amounts, bytes memory data)
        external
        onlyRole(MINTER_ROLE)
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            _beforeMint(ids[i], amounts[i]);

            _mint(accounts[i], ids[i], amounts[i], data);

            _afterMint(ids[i], amounts[i]);
        }
    }

    /// @notice Mints 1 token of `currentEventTokenId` to the recipient
    /// @dev Is being called from EventController and is compatible with previous release of EDUToken
    /// @param to recipient of the token
    /// @return Always `currentEventTokenId`
    function safeMint(address to)
        external
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        require(balanceOf(to, currentEventTokenId) == 0, "Cannot have more than 1");

        _beforeMint(currentEventTokenId, 1);

        _mint(to, currentEventTokenId, 1, "");

        _afterMint(currentEventTokenId, 1);

        return currentEventTokenId;
    }

    function setURI(string memory tokenMetadataBaseUri_, string memory contractMetadataUri_)
        external
        onlyRole(MANAGER_ROLE)
    {
        _setURI(tokenMetadataBaseUri_);
        _contractMetadataUri = contractMetadataUri_;
    }

    /// @notice Updates `currentEventTokenId` which affects `balanceOf(address)` and `safeMint(address)`
    /// @param currentEventTokenId_ TokenID to be set as the current
    function setCurrentEventTokenId(uint256 currentEventTokenId_)
        external
        onlyRole(MANAGER_ROLE)
    {
        currentEventTokenId = currentEventTokenId_;
    }

    /// @notice Sets the current supply of a token
    /// @dev Overwrites the previous value
    /// @param tokenId_ Token to set supply for
    /// @param supply_ The new supply for the token
    function setSupply(uint256 tokenId_, uint256 supply_)
        external
        onlyRole(MANAGER_ROLE)
    {
        _supplies[tokenId_] = supply_;
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}