// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract pixeltownwtf is Ownable, ERC721A {

    uint256 public constant SUPPLY = 3000;
    uint256 public maxMint = 3;
    bool public mintActive = true;
    string public _tokenBaseURI = "ipfs://bafybeidklanbia2su7ala354prsokwdkpoezj57p6gl3qnnjvgswwl2qpi/";

    constructor() ERC721A ("pixeltown.wtf","PIXL") {}

    function mint(uint256 quantity) external {
        require(totalSupply() < SUPPLY, "We are sold out!");
        require(mintActive, "Mint is Paused");
        require(quantity > 0, "Minimum mint is 1");
        require(quantity <= maxMint, "Exceeds max mint.");
        require( totalSupply() + quantity <= SUPPLY, "Exceeds max supply.");
        _safeMint(msg.sender, quantity);
    }

    
    function toggleMintActive() external onlyOwner {
        mintActive = !mintActive;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return _tokenBaseURI;
    }
}