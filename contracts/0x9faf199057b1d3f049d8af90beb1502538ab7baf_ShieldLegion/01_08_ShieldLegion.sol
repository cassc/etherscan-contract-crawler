// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";


contract ShieldLegion is ERC721A, Ownable {
    using Strings for uint256;
    
    uint256 public constant MAX_SUPPLY = 222;
    
    string public baseExtension = '.json';
    string private _baseTokenURI;

    constructor() ERC721A("The Shield Legion", "LEG") {}

    function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();
        require(bytes(base).length > 0, "baseURI not set");
        return string(abi.encodePacked(base, tokenID.toString(), baseExtension));
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /* *************** */
    /* OWNER FUNCTIONS */
    /* *************** */

    function mint(address to, uint256 quantity) external onlyOwner {
        require(quantity > 0, "quantity of tokens cannot be less than or equal to 0");
        require(totalSupply() + quantity <= MAX_SUPPLY, "exceed max supply of tokens");
        _safeMint(to, quantity);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function setBaseExtension(string memory _newExtension) public onlyOwner {
        baseExtension = _newExtension;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}