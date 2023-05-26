// SPDX-License-Identifier: MIT
// Powered by RTFKT Studios

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

abstract contract gnssInterface {
    function mintTransfer(address to, string calldata hash) public virtual returns(uint256);
}

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract GNSS is ERC1155, Ownable, ERC1155Burnable {
    uint256 tokenId = 0;
    uint256 amountMinted = 0;
    uint256 limitAmount = 10000;
    uint256 private tokenPrice = 330000000000000000; // 0.33 ETH

    address gnssContractAddress;

    mapping (address => mapping (uint256 => bool)) usedToken;
    mapping (address => uint256) authorizedContract;

    event priceChanged(uint256 newPrice);
                                
    bool salesStarted = false;
    bool migrationStarted = false;
    
    constructor() ERC1155("ipfs://QmczVPwCRwYuLB7gMf937SWGK6HBF61Wns8rud4AGstZja") {}
    
    // Set authorized contract address for minting the ERC-721 token
    function setGnssContract(address contractAddress) public onlyOwner {
        gnssContractAddress = contractAddress;
    }

    // Authorize specific smart contract to be used for minting an ERC-1155 token
    function toggleSales() public onlyOwner {
        salesStarted = !salesStarted;
    }

    // Authorize specific smart contract to be used for minting an ERC-1155 token
    function toggleMigration() public onlyOwner {
        migrationStarted = !migrationStarted;
    }
    
    // Authorize specific smart contract to be used for minting an ERC-1155 token
    function toggleContractAuthorization(address contractAddress, uint256 typeOfContract) public onlyOwner {
        authorizedContract[contractAddress] = typeOfContract;
    }

    // Check if a specific address is an authorized mintpass
    function isContractAuthorized(address contractAddress) view public returns(uint256) {
        return authorizedContract[contractAddress];
    }

    // Mint function
    function mint(uint256 amountToMint) public payable returns(uint256) {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(salesStarted == true, "Sales have not started");
        require(amountToMint <= 10, "You can't mint more than 10 per transaction!");
        uint256 amount = amountToMint;

        // Add verification on ether required to pay
        require(msg.value >= tokenPrice * amount, "Not enough money");
        
        uint256 prevTokenId = tokenId;
        tokenId++;
        require(amount + amountMinted <= limitAmount, "Limit reached");
        amountMinted = amountMinted + amount;
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
    
    // Allow to use the ERC-1155 to get the GNSS ERC-721 final token
    function migrateToken(uint256 id, string calldata hash) public returns(uint256) {
        require(migrationStarted == true, "Migration has not started");
        require(balanceOf(msg.sender, id) > 0, "Doesn't own the token"); // Check if the user own one of the ERC-1155
        burn(msg.sender, id, 1); // Burn one the ERC-1155 token
        gnssInterface gnssContract = gnssInterface(gnssContractAddress);
        uint256 mintedId = gnssContract.mintTransfer(msg.sender, hash); // Mint the ERC-721 token
        return mintedId; // Return the minted ID
    }
    
    // Check if the mintpass has been used to mint an ERC-1155
    function checkIfRedeemed(address _contractAddress, uint256 _tokenId) view public returns(bool) {
        return usedToken[_contractAddress][_tokenId];
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