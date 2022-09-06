// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract chargedcard is ERC721A, Ownable,ReentrancyGuard {
    uint256 private constant COLLECTIONS_SIZE = 555;
    uint256 public constant MAX_PER_WALLET = 10;
    uint256 public NFTPrice = 55000000000000000;  // 0.055 ETH
    uint32 public starttime = 1659052800; 
    string private _baseTokenURI;
    
    constructor() ERC721A("Charged Card NFD", "CRD") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mint(uint256 quantity) external payable {
        // require(isActive, 'Sale is not yet active');
        require(block.timestamp >= starttime , 'Sale is not yet active');
        require(numberMinted(msg.sender) + quantity <= MAX_PER_WALLET,"qty exceeds public limit");
        require(totalSupply() + quantity <= COLLECTIONS_SIZE, "reached max supply");
        _safeMint(msg.sender, quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "transfer failed.");
    }

}