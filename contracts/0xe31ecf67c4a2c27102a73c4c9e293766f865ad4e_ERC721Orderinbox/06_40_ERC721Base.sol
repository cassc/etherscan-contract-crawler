// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//

import "./ERC721Core.sol";
import "./ERC721DefaultApproval.sol"; 
import "../AutoTokenId.sol";

abstract contract ERC721Base is ERC721Core, ERC721DefaultApproval, AutoTokenId {

    struct Mint721AutoIdData {
        string uri;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
        bytes[] signatures;
    }

    function setDefaultApproval(address operator, bool hasApproval) external onlyOwner {
        _setDefaultApproval(operator, hasApproval);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721DefaultApproval) view returns (bool) {
        return ERC721DefaultApproval._isApprovedOrOwner(spender, tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override(ERC721Upgradeable, ERC721DefaultApproval) returns (bool) {
        return ERC721DefaultApproval.isApprovedForAll(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC721Core) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721Core) {
        return super._beforeTokenTransfer(from, to, tokenId);
    }

    // These should be set by the Orderinbox admin only
    function _baseURI() internal view virtual override(ERC721Upgradeable, ERC721Core) returns (string memory) {
        return super._baseURI();
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, ERC721Core) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721Core) onlyCreators(tokenId) {
        return super._burn(tokenId);
    }

    function _mintAndTransfer(Mint721AutoIdData memory data, address to) internal virtual {

        super._mintAndTransfer(
            LibERC721Mint.Mint721Data(
                getNextTokenId(),
                data.uri, 
                data.creators,
                data.royalties,
                data.signatures,
                true),  // We mark it with auto id so the signature validation is either skipped or ignored on the token id
            to);

        AutoTokenId._increment();
    }    

    uint256[256] private __gap;
}