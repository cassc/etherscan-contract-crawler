// SPDX-License-Identifier: MIT

/*
    Degenino Legal Overview
    1. Degenino.com Privacy Policy [https://degenino.com/pages/privacy-policy]
    2. Degenino.com Terms of Use [https://degenino.com/pages/terms-of-use]
    
    Degenino.com unavailable in US, UK, AU | 18+
*/

pragma solidity ^0.8.2;

import "./MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract MintContractInterface {
    function mintTransfer(address to) public virtual returns(uint256);
}

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract DegeninoBox is ERC1155, Ownable, ERC1155Burnable {
    using SafeMath for uint256;

    uint256 tokenId = 0;
    uint256 amountMinted = 0;
    uint256 limitAmount = 4444;
    uint256 private tokenPrice = 30000000000000000;
    mapping(address => uint256) public mintCount;

    address contractAddress;

    mapping (address => mapping (uint256 => bool)) usedToken;

    event priceChanged(uint256 newPrice);

    bool privateSales = false;
    bool publicSales = false;
    bool salesStarted = false;
    bool migrationStarted = false;

    bytes32 public merkleRoot = 0x1016c6f020c7900c54f3a574f90646928cdfe2ea4f595ad2198cb3ca1e03a129;
    
    constructor() ERC1155("ipfs://QmSHPi5jrLEjvfEG11iEaD8xZm7TXQz8hZgdgH7FahXqR8") { }

    function checkIsWhitelisted(bytes32[] memory proof) view public returns(bool){
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }
    
    // Set authorized contract address for minting the ERC-721 token
    function setContractAddress(address _contractAddress) public onlyOwner {
        contractAddress = _contractAddress;
    }

    // Authorize specific smart contract to be used for minting an ERC-1155 token
    function toggleSales() public onlyOwner {
        salesStarted = !salesStarted;
    }

    // Toggle the private sales system
    function togglePrivateSales() public onlyOwner {
        privateSales = !privateSales;
    }

    // Authorize specific smart contract to be used for minting an ERC-1155 token
    function toggleMigration() public onlyOwner {
        migrationStarted = !migrationStarted;
    }

    function devMint(uint256 amountToMint) public onlyOwner returns(uint256) {
        uint256 amount = amountToMint;
        
        uint256 prevTokenId = tokenId;
        tokenId++;
        require(amount + amountMinted <= limitAmount, "Limit reached");
        amountMinted = amountMinted + amount;
        mintCount[msg.sender] += amountToMint;
        _mint(msg.sender, tokenId, amount, "");
        return prevTokenId;
    }

    // Mint function
    function mint(uint256 amountToMint, bytes32[] calldata proof) public payable returns(uint256) {
        require(salesStarted == true, "Sales have not started");
        uint256 amount = amountToMint;

        // Note: For public sales to be active, the bool publicSales need to be true and the bool privateSales need to be false

        // If public sales is active
        if(publicSales == true) {
            require(!privateSales, "Public sales has not started");
            require(amount == 1, "You can only mint one token");
            require(mintCount[msg.sender] + 1 == 1, "You can only mint one token");
        } else { // Else if the public sales is not active
            require(privateSales, "Public sales has not started");
            // Check merkle proof
            require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not eligible for presale");
        }

        // Add verification on ether required to pay
        require(msg.value >= tokenPrice.mul(amount), "Not enough money");
        
        uint256 prevTokenId = tokenId;
        tokenId++;
        require(amount + amountMinted <= limitAmount, "Limit reached");
        amountMinted = amountMinted + amount;
        mintCount[msg.sender] += amountToMint;
        _mint(msg.sender, tokenId, amount, "");
        return prevTokenId;
    }
    
    // Allowing direct drop for gievaway
    function airdropGiveaway(address[] calldata to, uint256[] calldata amountToMint) public onlyOwner {
        for(uint256 i = 0; i < to.length; i++) {
            tokenId++;
            require(amountToMint[i] + amountMinted <= limitAmount, "Limit reached");
            amountMinted = amountMinted + amountToMint[i];
            _mint(to[i], tokenId, amountToMint[i], "");
        }
    }

    function setMaxQty (uint256 amount) public onlyOwner {
        limitAmount = amount;
    }
    
    // Allow to use the ERC-1155 to get the ERC-721 final token
    function migrateToken(uint256 id) public returns(uint256) {
        require(migrationStarted == true, "Migration has not started");
        require(balanceOf(msg.sender, id) > 0, "Doesn't own the token"); // Check if the user own one of the ERC-1155
        burn(msg.sender, id, 1); // Burn one the ERC-1155 token
        MintContractInterface nftContract = MintContractInterface (contractAddress);
        uint256 mintedId = nftContract.mintTransfer(msg.sender); // Mint the ERC-721 token
        return mintedId; // Return the minted ID
    }

    // Allow to use the ERC-1155 to get the ERC-721 final token (Forced)
    function forceMigrateToken(uint256 id) public onlyOwner {
        require(balanceOf(msg.sender, id) > 0, "Doesn't own the token");
        burn(msg.sender, id, 1); // Burn one the ERC-1155 token
        MintContractInterface
     nftContract = MintContractInterface
    (contractAddress);
        nftContract.mintTransfer(msg.sender); // Mint the ERC-721 token
    }
    
    // Check if the mintpass has been used to mint an ERC-1155
    function checkIfRedeemed(address _contractAddress, uint256 _tokenId) view public returns(bool) {
        return usedToken[_contractAddress][_tokenId];
    }
    
    // Allow toggling of public sales
    function togglePublicSales() public onlyOwner {
        publicSales = !publicSales;
    }
    
    // Get the price of the token (as changing during presale and public sale)
    function getPrice() view public returns(uint256) { 
        return tokenPrice;
    }
    
    // Get amount of 1155 minted
    function getAmountMinted() view public returns(uint256) {
        return amountMinted;
    }
    
    // Used for manual activation on dutch auction
    function setPrice(uint256 _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
        emit priceChanged(tokenPrice);
    }
    
    // Basic withdrawal of funds function in order to transfert ETH out of the smart contract
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}