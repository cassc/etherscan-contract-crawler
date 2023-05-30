// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./interface/Minter.sol";
import "./interface/ChainFacesHDElixir.sol";
import "./interface/ChainFacesHDRenderer.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ChainFaces HD
/// @author Kane Wallmann (Secret Project Team)
contract ChainFacesHD is Ownable, ERC721Enumerable, IERC721Receiver {

    //
    // Errors
    //
    error NotOwner();
    error InvalidERC721Token();
    error UnknownTokenId();

    //
    // Constants
    //

    uint256 constant CFA_OFFSET = 10000;
    uint256 constant DEAD_OFFSET = 40000;
    uint256 constant ELIXIR_ETA_ID = 0;

    //
    // Immutables
    //

    /// @dev Reference to ChainFaces Arena contract
    ERC721 private immutable cfa;

    /// @dev Reference to ChainFaces 1 contract
    ERC721 private immutable cf1;

    /// @dev Reference to ChainFaces HD - Elixir contract
    ChainFacesHDElixirInterface private immutable elixir;

    //
    // Public variables
    //

    ChainFacesHDRendererInterface public renderer;

    //
    // Constructor
    //

    constructor(address _renderer, address _elixir, address _cfa, address _cf1) ERC721("ChainFaces HD", "(o_o)") {
        renderer = ChainFacesHDRendererInterface(_renderer);
        elixir = ChainFacesHDElixirInterface(_elixir);
        cfa = ERC721(_cfa);
        cf1 = ERC721(_cf1);
    }

    //
    // Public functions
    //

    /// @dev Returns the token URI for a given token id
    /// @param _id The token id
    /// @return A URI for the metadata of the given token
    function tokenURI(uint256 _id) public override view returns (string memory) {
        if (ownerOf(_id) == address(0)) {
            revert UnknownTokenId();
        }

        return renderer.tokenURI(_id);
    }

    /// @dev Renders the SVG for a given token id
    /// @param _id The token id to render
    /// @return SVG image data for the given token
    function image(uint256 _id) external view returns (string memory) {
        return renderer.image(_id);
    }

    /// @dev Wraps multiple ChainFaces 1 tokens
    /// @param _ids An array of the ids of the tokens to wrap (requires approval)
    function wrapCF1Multi(uint256[] calldata _ids) external {
        for (uint256 i = 0; i < _ids.length; i++ ){
            // Attempt the transfer
            cf1.transferFrom(msg.sender, address(this), _ids[i]);
            // Mint the token
            _mintFromCF1(msg.sender, _ids[i]);
        }
    }

    /// @dev Wraps multiple ChainFaces Arena tokens
    /// @param _ids An array of the ids of the tokens to wrap (requires approval)
    function wrapCFAMulti(uint256[] calldata _ids) external {
        for (uint256 i = 0; i < _ids.length; i++ ){
            // Attempt the transfer
            cfa.transferFrom(msg.sender, address(this), _ids[i]);
            // Mint the token
            _mintFromCFA(msg.sender, _ids[i]);
        }
    }

    /// @dev Handles the receipt of ChainFaces 1 and ChainFaces Arena tokens by wrapping them
    function onERC721Received(
        address /* _operator */,
        address _from,
        uint256 _tokenId,
        bytes calldata /* _data */
    ) external override returns (bytes4) {
        if (msg.sender == address(cf1)) {
            _mintFromCF1(_from, _tokenId);
        } else if (msg.sender == address(cfa)) {
            _mintFromCFA(_from, _tokenId);
        } else {
            revert InvalidERC721Token();
        }

        return IERC721Receiver.onERC721Received.selector;
    }

    //
    // Privileged functions
    //

    /// @dev Sets the metadata renderer for this token
    function setRenderer(address _renderer) onlyOwner public {
        renderer = ChainFacesHDRendererInterface(_renderer);
    }

    //
    // Private functions
    //

    /// @dev Consumes elixir and mints CFHD for given CFA token ID
    /// @param _to The account to consume elixir from and send token to
    /// @param _tokenId The CFA token ID to mint equivalent CFHD from
    function _mintFromCFA(address _to, uint256 _tokenId) internal {
        // Consume an elixir
        elixir.consume(_to, ELIXIR_ETA_ID, 1);
        // Mint the token
        _mint(_to, _tokenId + CFA_OFFSET);
    }

    /// @dev Consumes elixir and mints CFHD for given CF1 token ID
    /// @param _to The account to send the token to
    /// @param _tokenId The CF1 token ID to mint equivalent CFHD from
    function _mintFromCF1(address _to, uint256 _tokenId) internal {
        // Mint the token
        _mint(_to, _tokenId);
    }
}