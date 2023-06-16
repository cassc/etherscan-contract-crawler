//
// _____/\\\\\\\\\\\____/\\\________/\\\__/\\\\\\\\\\\__/\\\\\_____/\\\__/\\\________/\\\_        
//  ___/\\\/////////\\\_\/\\\_______\/\\\_\/////\\\///__\/\\\\\\___\/\\\_\///\\\____/\\\/__       
//   __\//\\\______\///__\/\\\_______\/\\\_____\/\\\_____\/\\\/\\\__\/\\\___\///\\\/\\\/____      
//    ___\////\\\_________\/\\\\\\\\\\\\\\\_____\/\\\_____\/\\\//\\\_\/\\\_____\///\\\/______     
//     ______\////\\\______\/\\\/////////\\\_____\/\\\_____\/\\\\//\\\\/\\\_______\/\\\_______    
//      _________\////\\\___\/\\\_______\/\\\_____\/\\\_____\/\\\_\//\\\/\\\_______\/\\\_______   
//       __/\\\______\//\\\__\/\\\_______\/\\\_____\/\\\_____\/\\\__\//\\\\\\_______\/\\\_______  
//        _\///\\\\\\\\\\\/___\/\\\_______\/\\\__/\\\\\\\\\\\_\/\\\___\//\\\\\_______\/\\\_______ 
//         ___\///////////_____\///________\///__\///////////__\///_____\/////________\///________
//
// @jonathansnow

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ShinyFeathers is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;
    string private _baseTokenURI;

    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant MAX_PER_MINT = 5;
    uint256 public featherPrice = 0.1 ether;
    uint256 public numberAvailable;

    bool public claimIsActive;
    bool public saleIsActive;
    bool public burnIsActive;

    address r1 = 0x54681ac94D4e3C8F58F54B576B654DC2D1950ae0; // Treasury
    address r2 = 0xe7f995Cd15C47Db20dCC9fD3410627003b1Ca994; // Design
    address r3 = 0x320562F05bAEEed8Aa76a0110008Bf0C8C156A8F; // Admin
    address r4 = 0x3E7898c5851635D5212B07F0124a15a2d3C547EB; // Dev
    address r5 = 0x2C6B8C19dd7174F6e0cc56424210F19EeFe62f94; // Dev

    mapping(address => uint256) public whitelist;

    constructor() ERC721("ShinyFeathers", "FTHRS") {
        _nextTokenId.increment();   // Start Token Ids at 1
        claimIsActive = false;      // Set claim to inactive
        saleIsActive = false;       // Set sale to inactive
        burnIsActive = false;       // Set burn to inactive
        numberAvailable = 1000;     // Set initial number of available tokens
    }

    // Function to handle the public mint
    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active yet.");
        require(numberOfTokens > 0, "Quantity must be greater than 0.");
        require(numberOfTokens <= MAX_PER_MINT, "Exceeds max per mint.");
        require(totalSupply() + numberOfTokens <= numberAvailable, "Exceeds max available.");
        require(msg.value >= numberOfTokens * featherPrice, "Wrong ETH value sent.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
        }
    }

    // Function to handle the whitelisted free mint
    function claim(uint256 numberOfTokens) public {
        require(claimIsActive, "Claiming is not active yet.");
        require(numberOfTokens > 0, "Quantity must be greater than 0.");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Exceeds max supply.");
        require(whitelist[msg.sender] > 0, "You have no feathers to claim");
        require(numberOfTokens <= whitelist[msg.sender], "Unable to claim that many feathers.");
        
        // Update the number of feathers claimed for the sender address
        whitelist[msg.sender] = whitelist[msg.sender] - numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
        }
    }

    // Function to allow a user to burn their feather
    function burn(uint256 tokenId) public virtual {
        require(burnIsActive, "Burning is not active.");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not authorized to burn.");
        _burn(tokenId);
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    // Function to return the number of feathers available to mint
    function feathersAvailable() public view returns (uint256) {
        return numberAvailable - totalSupply();
    }

    // Function to return the rnumber of feathers remaining to mint
    function feathersRemaining() public view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    // Function to return how many feathers have been minted
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    // Function to add multiple addresses to the whitelist or update the claim amount
    function massUpdateWhitelist(address[] memory addresses, uint256[] memory mintAmounts) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            updateWhitelist(addresses[i], mintAmounts[i]);
        }
    }

    // Function to add an address to the whitelist or update the claim amount
    function updateWhitelist(address userAddress, uint256 quantity) public onlyOwner {
        whitelist[userAddress] = quantity;
    }

    // Function to return the number of feathers available to claim by an address
    function getWhitelistBalance(address userAddress) public view returns (uint256)  {
        return whitelist[userAddress];
    } 

    // Function to increase the number of feathers available to mint
    function increaseAvailable(uint256 newNumberAvailable) external onlyOwner {
        require(newNumberAvailable <= MAX_SUPPLY, "Exceeds max supply.");
        require(newNumberAvailable > numberAvailable, "New amount too low.");
        numberAvailable = newNumberAvailable;
    }

    // Function to override the baseURI function
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Function to set the baseURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Function to flip claim on or off
    function toggleClaim() public onlyOwner {
        claimIsActive = !claimIsActive;
    }

    // Function to flip the sale on or off
    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // Function to flip burning on or off
    function toggleBurn() public onlyOwner {
        burnIsActive = !burnIsActive;
    }

    // Function to change the price of feathers
    function changeSalePrice(uint256 newPrice) external onlyOwner {
        featherPrice = newPrice;
    }

    // Function to update the treasury address
    function updateTreasury(address newAddress) external onlyOwner {
        r1 = newAddress;
    }

    // Function to withdraw ETH balance with splits
    function withdrawBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(r1).transfer((balance * 72) / 100);  // 72% - Treasury
        payable(r2).transfer((balance * 10) / 100);  // 10% - Design
        payable(r3).transfer((balance * 6) / 100);   // 6%  - Admin
        payable(r4).transfer((balance * 6) / 100);   // 6%  - Dev
        payable(r5).transfer((balance * 6) / 100);   // 6%  - Dev
        payable(r1).transfer(address(this).balance); // Transfer remaining balance to treasury
    }

}