// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract JunkYardBones is Ownable, ERC721Enumerable  {
    using SafeMath for uint256;

    string private baseURI = "https://api.junkyarddogs.io/bones?tokenId=";

    constructor() ERC721("JunkYardDogsBones", "JYDB") {}

    function mint(address minter, uint tokenId) public onlyOwner {
        _safeMint(minter, tokenId);
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}