// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract XNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    constructor(address owner, address minter, uint256 royalty) ERC721("PROJECT XENO", "XENO_NFT") {
        _minter = minter;
        _transferOwnership(owner);
        _royalty = royalty;
    }
    address private _minter;
    uint256 private _royalty;

    modifier onlyAuth() {
        require(_msgSender() == getMinter() || _msgSender() == owner(), "caller is not authorized.");
        _;
    }

    function mint(string memory uri, uint256 tokenId) public onlyAuth {
        _safeMint(owner(), tokenId);
        _setTokenURI(tokenId, uri);
    }

    function safeMint(address to, uint256 tokenId, string memory uri)
        public
        onlyAuth
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

   function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isMined(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }

    function getMinter() public view returns(address) {
        return _minter;
    }

    function changeMinter(address newMinter) external onlyAuth {
        require(newMinter != address(0), "Invalid address: address(0x0)");
        _minter = newMinter;
    }

    function getRoyalty() public view returns(uint256) {
        return _royalty;
    }

    function setRoyalty(uint256 royalty) external onlyAuth {
        _royalty = royalty;
    }
}