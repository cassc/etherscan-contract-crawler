// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title SmartZombieLab contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract SmartZombieLab is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint public constant MAX_TOKEN_PURCHASE = 10;
    uint public constant TOKEN_PRICE = 0.05 ether; // 50000000000000000 Wei
    bool saleIsActive = false;

    uint public maxTokenSupply;
    uint public reservedTokens;
    string public baseURI;    

    constructor(uint _maxTokenSupply) 
            ERC721("Smart Zombie Lab", "SZL") {
        require(_maxTokenSupply > 0, "_maxTokenSupply was not given");

        maxTokenSupply = _maxTokenSupply;
    }

    /**
    * Set Base URI
    */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * Set some tokens aside
     */
    function reserveTokens(uint numTokens) public onlyOwner {
        require(numTokens > 0, "numTokens was not given");
        require(totalSupply().add(numTokens) <= maxTokenSupply, "Reserving numTokens would exceed max supply of tokens");

        // reserve tokens
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
        reservedTokens = reservedTokens.add(numTokens);
    }

    /**
     * Get number of reserved tokens
     */
    function getReservedTokens() public view returns (uint256) {
        return reservedTokens;
    }

    /**
     * Activate or deactivate the sale
     */
    function activateSale(bool active) public onlyOwner {
        if (active) {
            bytes memory tempString = bytes(baseURI);
            require(tempString.length != 0, "baseURI has not been set");
        }
        
        saleIsActive = active;
    }

    /**
    * Mint Tokens
    */
    function mintTokens(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active");
        require(numberOfTokens <= MAX_TOKEN_PURCHASE, "numberOfTokens exceeds maximum per tx");
        require(totalSupply().add(numberOfTokens) <= maxTokenSupply, "Purchase would exceed max supply of tokens");
        require(TOKEN_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        uint i;
        uint supply = totalSupply();
        for(i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * Get the metadata for a given tokenId
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
            : "";
    }

    /**
     * Get current balance of contract (Owner only)
     */
    function getBalance() public view onlyOwner returns (uint)  {
        uint balance = address(this).balance;
        return balance;
    }

    /**
     * Withdraw all funds from contract (Owner only)
     */
    function withdrawFunds() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}