// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract beanies is ERC721, Ownable {
    
    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmdabQ7aWrFPS3s8JU4mpTn6aiHCp7a7umsnCvP725AejK/";
    
    uint16 MAX_BEANIES = 1000;
    
    uint16 totalSupply = 0;

    constructor() ERC721("CharlesDAO", "BEANIE") {
     
    }

    function setBaseURI(string memory base) public onlyOwner {
        baseURI = base;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint() public {
        require(totalSupply + 1 < MAX_BEANIES, "All beanies have already been minted!");
       _safeMint(msg.sender, totalSupply + 1);
        totalSupply += 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}