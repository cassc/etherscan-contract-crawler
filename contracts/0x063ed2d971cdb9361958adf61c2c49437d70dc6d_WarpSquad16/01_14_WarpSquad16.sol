// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract WarpSquad16 is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Maximum supply of the NFT
    uint256 public constant MAX_SUPPLY = 16;

    // solhint-disable-next-line
    constructor() ERC721("Warp Squad 16", "WS16") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmY4GnpgS3eF95qShPDGr7zLXwffBbybF2aeY4mqoEZcCm/";
    }

    function safeMint(address to, uint256 quantity) public onlyOwner {
        require(
            super.totalSupply() + quantity <= MAX_SUPPLY,
            "total supply will exceed limit"
        );

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}