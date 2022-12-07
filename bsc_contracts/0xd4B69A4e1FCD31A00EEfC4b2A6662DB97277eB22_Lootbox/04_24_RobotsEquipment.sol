pragma solidity ^0.8.4;

import "common-contracts/contracts/Governable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract RobotsEquipment is ERC721, ERC721Enumerable, Governable {

    string public baseURI;

    constructor() ERC721("Robots Equipment", "DRE") {}

    function setBaseURI(string memory newBaseURI) public onlyGovernance {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(address to, uint256 id) external onlyGovernance {
        _safeMint(to, id);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
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