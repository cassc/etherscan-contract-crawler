// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRenderer.sol";

contract PaintedChecks is ERC721, Ownable {
    // Storage of each token's drawing
    mapping(uint256 => uint8[80]) drawings;
    // Whether this address already drew
    mapping(address => bool) didPaint;
    // Storage of drawing hashes, calculated through _drawingHash, to ensure uniqueness
    mapping(bytes32 => bool) drawingStore;
    // Artist
    mapping(uint256 => address) artists;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // whether minting is open
    bool public isOpen = false;
    // metadata renderer
    IPaintingRenderer public renderer;

    constructor(address _renderer) ERC721("Painted Checks", "PAINTEDCHECKS") {
        renderer = IPaintingRenderer(_renderer);
    }

    function paint(uint8[80] calldata drawing) external payable {
        // Validate 1 mint per addy
        require(didPaint[msg.sender] != true, "Can only paint once");

        // Charge
        require(
            msg.value == 0.0069 ether,
            "Painting costs 0.0069 ether to prevent spam and buy gotu a negroni"
        );

        // Test whether drawing is in bounds. I wish we could mod this in the renderer, however one could cheat the uniqueness test :(
        for (uint256 i = 0; i < 80; i++) {
            require(drawing[i] < 6, "Out of palette bounds");
        }

        // Check whether drawing exists
        bytes32 drawingHash = _drawingHash(drawing);

        require(
            drawingStore[drawingHash] != true,
            "This has already been painted"
        );

        // Check whether mint is open, may be closed later... No plans as of writing tho.
        require(isOpen == true, "Minting must be open to paint");

        // Get a new token id
        _tokenIds.increment();
        uint256 tokenid = _tokenIds.current();

        // Prevent this sender from minting again
        didPaint[msg.sender] = true;
        // Store the sender's drawing
        drawings[tokenid] = drawing;
        // Prevent this artwork from being copied
        drawingStore[drawingHash] = true;
        // Store minter aka artist
        artists[tokenid] = msg.sender;

        // Mint the token to sender
        _safeMint(msg.sender, tokenid);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw; contract balance empty");

        address _owner = owner();
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function setOpen(bool _isOpen) public onlyOwner {
        isOpen = _isOpen;
    }

    function setRenderer(address _renderer) public onlyOwner {
        renderer = IPaintingRenderer(_renderer);
    }

    function paintingExists(uint8[80] calldata drawing)
        public
        view
        returns (bool)
    {
        bytes32 drawingHash = _drawingHash(drawing);
        return drawingStore[drawingHash] == true;
    }

    function canMint(address minter) public view returns (bool) {
        return didPaint[minter] != true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return renderer.render(tokenId, drawings[tokenId]);
    }

    function artist(uint256 tokenId) public view returns (address) {
        return artists[tokenId];
    }

    function _drawingHash(uint8[80] calldata drawing)
        private
        pure
        returns (bytes32)
    {
        return keccak256((abi.encodePacked(drawing)));
    }
}