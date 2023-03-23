// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract WrappedERC721 is ERC721Enumerable, Ownable {
    // Mapping from tokenID to metadata
    mapping(uint256 => string) private _metadata;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function safeMint(
        address to,
        uint256 tokenId,
        string memory metadata
    ) public onlyOwner {
        _safeMint(to, tokenId);

        _metadata[tokenId] = metadata;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "WrappedERC721: URI query for nonexistent token"
        );

        return _metadata[tokenId];
    }

    function burn(uint256 tokenId) public onlyOwner {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);

        delete _metadata[tokenId];
    }
}