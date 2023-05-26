// SPDX-License-Identifier: MIT
// OpenGem Contracts (token/ERC721/extensions/ERC721PermanentProof.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721PermanentProof is ERC721 {

    string private _permanentGlobalProof;
    mapping(uint256 => string) private _permanentTokenProofs;

    function tokenProofPermanent(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenProof = _permanentTokenProofs[tokenId];

        if (bytes(_tokenProof).length == 0) {
            return _permanentGlobalProof;
        }
        return _tokenProof;
    }

    function _setPermanentGlobalProof(string memory _globalProof) internal virtual {
        require(bytes(_permanentGlobalProof).length == 0, "ERC721PermanentProof: Proof already set");
        _permanentGlobalProof = _globalProof;
    }

    function _setPermanentTokenProof(uint256 tokenId, string memory _tokenProof) internal virtual {
        require(_exists(tokenId), "ERC721PermanentProof: Proof set of nonexistent token");
        require(bytes(_permanentTokenProofs[tokenId]).length == 0, "ERC721PermanentProof: Proof already set");
        _permanentTokenProofs[tokenId] = _tokenProof;
    }
    
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_permanentTokenProofs[tokenId]).length != 0) {
            delete _permanentTokenProofs[tokenId];
        }
    }
}