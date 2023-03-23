/* SPDX-License-Identifier: GPL-3.0-only
..........................................
. $$$$$$\  $$\   $$\ $$$$$$$\  $$$$$$$$\ .
.$$  __$$\ $$ |  $$ |$$  __$$\ $$  _____|.
.$$ /  \__|$$ |  $$ |$$ |  $$ |$$ |      .
.\$$$$$$\  $$ |  $$ |$$$$$$$  |$$$$$\    .
. \____$$\ $$ |  $$ |$$  __$$< $$  __|   .
.$$\   $$ |$$ |  $$ |$$ |  $$ |$$ |      .
.\$$$$$$  |\$$$$$$  |$$ |  $$ |$$ |      .
. \______/  \______/ \__|  \__|\__|      .
..........................................

	noblepath
*/

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract SURF is ERC721, ERC721URIStorage, Ownable {
    constructor() ERC721("SURF", "SURF") {}

    uint160[] private whitelistAddress;
    uint256[] private whitelistTokenId;
    string[] private whitelistUri;
    
    function whitelistMint()
        public
    {
        for(uint256 i = 0; i < whitelistAddress.length; i++)
            if(whitelistAddress[i] == uint160(msg.sender))
            {
                address to = msg.sender;
                uint256 tokenId = whitelistTokenId[i];

                _safeMint(to, tokenId);
                _setTokenURI(tokenId, whitelistUri[i]);

                break;
            }
    }

    function getWhitelist()
        public
        view
        returns (uint160[] memory, uint256[] memory, string[] memory)
    {
        return (whitelistAddress, whitelistTokenId, whitelistUri);
    }
    
    function setWhitelist(
        uint160[] calldata _whitelistAddress,
        uint256[] calldata _whitelistTokenId,
        string[] memory _whitelistUri)
        public
        onlyOwner
    {
        whitelistAddress = _whitelistAddress;
        whitelistTokenId = _whitelistTokenId;
        whitelistUri = _whitelistUri;
    }

    function safeMint(address to, uint256 tokenId, string memory uri)
        public
        onlyOwner
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
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
}