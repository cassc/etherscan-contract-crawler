// SPDX-License-Identifier: GPL-3.0-or-later
// Author:                  Rhea Myers <[email protected]>
// Copyright:               2023 Myers Studio, Ltd.
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract FaceCoin is ERC721, ERC721Enumerable, Pausable, Ownable {
    uint256 constant public NUM_TOKENS = 24;
    int256 constant internal MIN_CONTRAST = 32;

    constructor() ERC721("FaceCoin", "FAC") {
        for (uint256 i = 1; i <= NUM_TOKENS; i++) {
            _safeMint(msg.sender, i);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*
      Extract 24-bit forground and background colours from the hash of
      the owner's address and the token id.
      This will usually be the first and second 3-byte runs of the hash
      bytes32, but if they are not contrasty enough we try successive 3-byte
      runs for the foreground colour until we give up and default it to
      black.
     */

    function tokenPalette(uint256 tokenId)
        public
        view
        returns (uint8[3][2] memory)
    {
        require(
            tokenId > 0 && tokenId <= NUM_TOKENS,
            "tokenId out of range"
        );
        bytes32 hash = sha256(abi.encodePacked(ownerOf(tokenId), tokenId));
        uint8[3] memory background;
        uint8[3] memory foreground;
        extractRgb(hash, 0, background);
        // Ethereum addresses are 20 bytes.
        for (uint256 i = 15; i < 32; i += 3) {
            extractRgb(hash, 1, foreground);
            if (contrastRgbs(background, foreground) <= MIN_CONTRAST) {
                break;
            }
        }
        return [background, foreground];
    }

    /*
      Extract 3 successive bytes from the hash and insert them into the bytes
      of a uint24 in order.
     */

    function extractRgb(bytes32 hash, uint256 index, uint8[3] memory rgb)
        internal
        pure
    {
        rgb[0] = uint8(hash[index]);
        rgb[1] = uint8(hash[index + 1]);
        rgb[2] = uint8(hash[index + 2]);
    }

    /*
      Get the difference (not distance) between two 24-bit rgb values
      encoded as uint24s.
    */

    function contrastRgbs(uint8[3] memory ua, uint8[3] memory ub)
        internal
        pure
        returns (int256)
    {
        return
            abs((int256(uint256(ua[0]))) - (int256(uint256(ub[0]))))
            +  abs((int256(uint256(ua[1]))) - (int256(uint256(ub[1]))))
            +  abs((int256(uint256(ua[2]))) - (int256(uint256(ub[2]))));
    }

    /*
      Solidity doesn't have this.
    */

    function abs(int256 x)
        internal
        pure
        returns (int256)
    {
        return x >= 0 ? x : -x;
    }
}