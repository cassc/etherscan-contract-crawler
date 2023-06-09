//     /\
//    /  \
//   |    |
//   |BITS|
//   |    |
//   |    |
//   |    |
//  '      `
//  |      |
//  |      |
//  |______|
//   '-`'-`   .
//   / . \'\ . .'
//  ''( .'\.' ' .;'
// '.;.;' ;'.;' ..;;'
/*
 * Audited by Kurama Audits for security and integrity.
 * Audit UUID: 3e0a6a0f-1e95-4e12-a39f-7d4e4f4c7f0a
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NFTFactory is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string _baseTokenURI;

    constructor() ERC721("Bitinauts", "BTS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

   // Sets the base token URI prefix.
    function setBaseTokenURI(string memory baseTokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseTokenURI;
    }

    // Sets the base URI.
    function _baseURI() internal override view virtual returns (string memory) {
        return _baseTokenURI;
    }

    // Method use for lazy minting
    function mint(address to, uint256 _tokenId) external onlyRole(MINTER_ROLE) {
        _safeMint(to, _tokenId);
    }

    // Method use for bulk minting
    function mintBulkWithIds(address to, uint256[] memory ids) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < ids.length; i++) {
            _safeMint(to, ids[i]);
        }
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}