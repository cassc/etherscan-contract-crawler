// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./interface/Minter.sol";
import "./interface/ChainFacesHDRenderer.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ChainFaces HD - Undead
/// @author Kane Wallmann (Secret Project Team)
contract ChainFacesHDUndead is Ownable, ERC721Enumerable, MinterInterface {

    //
    // Errors
    //
    error NotShrine();
    error NotOwner();
    error UnknownTokenId();


    //
    // Constants
    //

    uint256 constant DEAD_OFFSET = 40000;

    //
    // Immutables
    //

    /// @dev Reference to the shrine contract
    address public immutable shrine;

    //
    // Public variables
    //

    /// @dev Reference to the metadata renderer contract where calls to tokenURI are delegated to
    ChainFacesHDRendererInterface public renderer;

    //
    // Modifiers
    //

    // Only if called by shrine
    modifier onlyShrine() {
        if(msg.sender != shrine) {
            revert NotShrine();
        }
        _;
    }

    //
    // Constructor
    //

    constructor(address _renderer, address _shrine) ERC721("ChainFaces HD Undead", "(X_X)") {
        renderer = ChainFacesHDRendererInterface(_renderer);
        shrine = _shrine;
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
        if (ownerOf(_id) == address(0)) {
            revert UnknownTokenId();
        }

        return renderer.image(_id);
    }

    //
    // Privileged functions
    //

    /// @dev Sets the metadata renderer for this token
    function setRenderer(address _renderer) external onlyOwner {
        renderer = ChainFacesHDRendererInterface(_renderer);
    }

    /// @dev Used by shrine to mint a resurrected dead ChainFace Arena tokens
    function mint(address _to, uint256 _id) external override onlyShrine {
        _mint(_to, DEAD_OFFSET + _id);
    }
}