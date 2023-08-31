// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @custom:security-contact [email protected]
contract BAYCClone is ERC721, ERC721Enumerable {
    constructor() ERC721("BAYC Clone", "cBAYC") {

      _mint(address(0x42aB8ADabC9d2254C6D06929c3144C7A8E7a6A68), 2);
      _mint(address(0xA5e04825a2aD3398Ff39dd02f49529A2dC2A50B2), 3);
      _mint(address(0x57580A7e5b36Aa88f28B1d0c62AA8B19C765484D), 4);
      _mint(address(0xAeC13Fa880aBbD5Cdc5B6B4f3CE1ed25489297f2), 35);
      _mint(address(0xc1E3e4530AC5214AE6569F4DC6cA2020D5aD3E3D), 6);
      _mint(address(0x1B0e980da367dA687aeDa7eFE3bD7f0157E13cE8), 8);
      _mint(address(0x0811A66d9a41BC87750F1fA5d9395F1Eefd69C6f), 9);
      _mint(address(0xB3606914458e6988CFA7e24Ec42589B609D1B1C5), 50);
      _mint(address(0xB3606914458e6988CFA7e24Ec42589B609D1B1C5), 51);
      _mint(address(0xe54B8b5F552B903836539f1289c828eEaf3d28b6), 55);
      _mint(address(0xe54B8b5F552B903836539f1289c828eEaf3d28b6), 56);
      _mint(address(0x9972Ecf0d17282Cbaf222FA474f8E2BcE89e2c04), 13);
      _mint(address(0x3285D135fe2B2484bd6BBaEc69fbcd18dDb2f628), 20);
      _mint(address(0xB597C0ca4A721064C5DeFC0BD7f70a3Bda72ec03), 16);
      _mint(address(0x9361d935e2Aa2d998E751EA7489604217AaC91aD), 17);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://demo-assets.upclub.com/demo-collections/bayc/metadata/";
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function totalSupply() public pure override returns (uint256) {
        return 100;
    }
}