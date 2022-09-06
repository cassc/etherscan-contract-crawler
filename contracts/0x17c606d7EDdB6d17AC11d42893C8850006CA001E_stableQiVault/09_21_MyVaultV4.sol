// contracts/MyVaultNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract VaultNFTv4 is ERC721, ERC721Enumerable {

    string public uri;

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    constructor(string memory name, string memory symbol, string memory _uri)
        ERC721(name, symbol)
    {
        uri = _uri;
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        require(_exists(tokenId));

        return uri;
    }
}