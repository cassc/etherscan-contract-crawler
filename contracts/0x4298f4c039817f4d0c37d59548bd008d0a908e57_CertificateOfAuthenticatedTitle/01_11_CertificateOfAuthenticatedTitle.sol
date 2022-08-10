// SPDX-License-Identifier: MIT
// Author: James Geary

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721ABurnable.sol";

contract CertificateOfAuthenticatedTitle is ERC721ABurnable, ERC2981, Ownable {
    mapping(uint256 => string) internal _textForToken;

    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {}

    function burn(uint256 tokenId) public override onlyOwner {
        require(_exists(tokenId), "Token doesn't exist");
        _burn(tokenId, true);
    }

    function mint(address to, string calldata text) public onlyOwner {
        _textForToken[_nextTokenId()] = text;
        _mint(to, 1);
    }

    function updateTokenText(uint256 tokenId, string calldata text)
        public
        onlyOwner
    {
        require(_exists(tokenId), "Token doesn't exist");
        _textForToken[tokenId] = text;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return _textForToken[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == 0x2a55205a; // ERC165 interface ID for ERC2981.
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }
}