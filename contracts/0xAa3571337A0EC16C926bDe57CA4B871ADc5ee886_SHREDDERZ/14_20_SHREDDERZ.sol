// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721SeaDrop } from "./ERC721SeaDrop.sol";

/// @title  SHREDDERZ Dynamic NFT
/// @notice This contract is an ERC721 contract that allows for dynamic metadata
///         evolution based on off-chain data.
contract SHREDDERZ is ERC721SeaDrop {
    mapping(address => bool) public _uriSetters;
    string[] private _baseURIs;

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    error IndexOutOfRange();
    error NotURISetter();

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event SetBaseURIs(string[] baseURIs);
    event Evolve(uint256 index);
    event URISetterGranted(address setter);
    event URISetterRevoked(address setter);

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyURISetters(address setter) {
        if (!_uriSetters[setter]) revert NotURISetter();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Contract constructor.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param allowedSeadrop The authorized seadrop contract addresses.
    constructor(
        string memory name,
        string memory symbol,
        address[] memory allowedSeadrop
    ) ERC721SeaDrop(name, symbol, allowedSeadrop) {
        _uriSetters[msg.sender] = true;
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Evolves the collection's NFT metadata
    ///         NOTE: This function can only be called by an address with
    ///         URI setting privileges. This privilege can be granted to
    ///         a smart contract for automation and off-chain data integration.
    function evolveBaseURI(uint256 index) external onlyURISetters(msg.sender) {
        if (index >= _baseURIs.length) revert IndexOutOfRange();
        _tokenBaseURI = _baseURIs[index];
        emit Evolve(index);
    }

    /// @notice Sets the contract URIs.
    /// @param baseURIs The new URIs.
    function setURIS(string[] memory baseURIs) external onlyOwner {
        _baseURIs = baseURIs;
        emit SetBaseURIs(baseURIs);
    }

    /// @notice Grants baseURI setting privileges to an address.
    /// @param setter The address to grant privileges to.
    function grantURISetter(address setter) external onlyOwner {
        _uriSetters[setter] = true;
        emit URISetterGranted(setter);
    }

    /// @notice Revokes baseURI setting privileges from an address.
    /// @param setter The address to revoke privileges from.
    function revokeURISetter(address setter) external onlyOwner {
        _uriSetters[setter] = false;
        emit URISetterRevoked(setter);
    }

    /// @notice Returns the base URI for the given index.
    /// @param index The index of the base URI to return.
    function getURIS(uint256 index) external view returns (string memory) {
        if (index >= _baseURIs.length) revert IndexOutOfRange();
        return _baseURIs[index];
    }

    /// @notice Burns `tokenId`. The caller must own `tokenId` or be an
    ///         approved operator.
    /// @param tokenId The token id to burn.
    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }
}