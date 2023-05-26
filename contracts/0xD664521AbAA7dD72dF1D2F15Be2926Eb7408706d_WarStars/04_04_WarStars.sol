/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/// @author M1LL1P3D3
/// ayo

import "solmate/tokens/ERC721.sol";
import "solmate/auth/Owned.sol";
import "Solady/utils/LibString.sol";

contract WarStars is ERC721, Owned {
 
    using LibString for uint;

    uint public mintPrice = 0.05 ether;
    uint public maxSupply = 50;
    uint private tokenCounter;
    string public baseURI;

    constructor() ERC721("WarStars", "WS") Owned(msg.sender) {}

    receive() external payable {
        uint amount = msg.value / mintPrice;
        mint(amount);
    }

    function mint(uint amount) public payable {
        require(amount + tokenCounter <= maxSupply, "Exceeds max supply");
        require(msg.value == mintPrice * amount, "Incorrect amount of Ether sent"); 
        for(uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, tokenCounter);
            tokenCounter++;
        }
    }

    function tokenURI(uint tokenID) public view override returns (string memory){
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenID.toString())) : "";
    }

    function updateBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function updateMintPrice(uint _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function updateMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}