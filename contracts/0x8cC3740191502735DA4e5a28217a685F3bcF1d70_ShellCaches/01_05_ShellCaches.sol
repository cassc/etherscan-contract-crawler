// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";

contract ShellCaches is ERC721, Ownable {

    using Strings for uint256;

    string private baseURI;
    uint256 public mintIndex = 0;

    constructor(string memory name, string memory symbol, string memory uri) ERC721(name, symbol) {
        baseURI = uri;
    }

    function mint(address to, uint256 mintAmount) external onlyOwner {

        for(uint8 i = 0; i < mintAmount; ++i) {
            _safeMint(to, mintIndex);
            mintIndex++;
        }

    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require (ownerOf[id] != address(0), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }
}