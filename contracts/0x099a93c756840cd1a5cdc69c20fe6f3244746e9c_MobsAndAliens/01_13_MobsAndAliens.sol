//Mob's & Aliens

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./erc721a/contracts/ERC721A.sol";

contract MobsAndAliens is Ownable, ERC721A {

    bool private publicSale = false;
    bool private whitelistSale = false;

    bytes32 public merkleRoot;

    uint public maxSupply = 10000;
    uint public price = 0.03 ether;
    uint public maxPerTx = 30;
    
    constructor() ERC721A("Mobs and Aliens", "MBNAL") {}

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function toggleWhitelistSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }
    
    function setPrice(uint p) external onlyOwner {
        price = p;
    }

    function setMaxSupply(uint ms) external onlyOwner {
        maxSupply = ms;
    }
    
    function setMaxTx(uint mt) external onlyOwner {
        maxPerTx = mt;
    }

    //metadata URI
    string internal baseTokenURI;
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function setMerkleRoot(bytes32 r) external onlyOwner {
        merkleRoot = r;
    }

    function withdrawOwner() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function devMint(address to, uint quantity) external onlyOwner {
        require(quantity + totalSupply() <= maxSupply, "ERROR: Sold out");
        _mint(to, quantity);
    }

    function whitelistMint(uint qty, bytes32[] memory proof) external payable {
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "ERROR: Not whitelisted.");
        require(whitelistSale, "ERROR: Whitelist sale is not Active.");
        _mint(qty);
    }
    
    function publicMint(uint quantity) external payable {
        require(publicSale, "ERROR: Public sale is not active.");
        _mint(quantity);
    }

    function _mint(uint quantity) internal {
        require(quantity <= maxPerTx && quantity > 0, "ERROR: Invalid quantity or Max Per Tx.");
        require(quantity + totalSupply() <= maxSupply, "ERROR: Sold out");
        if(balanceOf(_msgSender()) == 0) {
            require(msg.value >= price * (quantity - 1), "ERROR: Incorrect value");
        } else {
            require(msg.value >= price * quantity, "ERROR: Incorrect value");
        }
        _mint(_msgSender(), quantity);
    }
}