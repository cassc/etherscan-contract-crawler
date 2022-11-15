// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";


contract Renascence is ERC721A, DefaultOperatorFilterer, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public publicBalance;   // internal balance of public mints to enforce limits

    bool public mintingIsActive = false;           // control if mints can proceed
    bool public reservedTokens = false;            // if team has minted tokens already
    uint256 public constant maxSupply = 4096;      // total supply
    uint256 public constant maxMint = 4;           // max per mint (non-holders)
    uint256 public constant maxWallet = 4;         // max per wallet (non-holders)
    uint256 public constant teamReserve = 96;      // amount to mint to the team
    string public baseURI;                         // base URI of hosted IPFS assets
    string public _contractURI;                    // contract URI for details

    constructor() ERC721A("Renascence", "Renascence") {}

    // Show contract URI
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // Withdraw contract balance to creator (mnemonic seed address 0)
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Flip the minting from active or paused
    function toggleMinting() external onlyOwner {
        mintingIsActive = !mintingIsActive;
    }

    // Specify a new IPFS URI for token metadata
    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    // Specify a new contract URI
    function setContractURI(string memory URI) external onlyOwner {
        _contractURI = URI;
    }

    // Reserve some tokens for giveaways
    function reserveTokens() public onlyOwner {
        // Only allow one-time reservation of tokens
        if (!reservedTokens) {
            _mintTokens(teamReserve);
            reservedTokens = true;
        }
    }

    // Internal mint function
    function _mintTokens(uint256 numberOfTokens) private {
        require(numberOfTokens > 0, "Must mint at least 1 token.");
        require(totalSupply().add(numberOfTokens) <= maxSupply, "Minting would exceed max supply.");

        // Mint number of tokens requested
        _safeMint(msg.sender, numberOfTokens);

        // Disable minting if max supply of tokens is reached
        if (totalSupply() == maxSupply) {
            mintingIsActive = false;
        }
    }

    // Mint public
    function mintPublic(uint256 numberOfTokens) external payable {
        require(mintingIsActive, "Minting is not active.");
        require(msg.sender == tx.origin, "Cannot mint from external contract.");
        require(numberOfTokens <= maxMint, "Cannot mint more than 4 during mint.");
        require(publicBalance[msg.sender].add(numberOfTokens) <= maxWallet, "Cannot mint more than 4 per wallet.");

        _mintTokens(numberOfTokens);
        publicBalance[msg.sender] = publicBalance[msg.sender].add(numberOfTokens);
    }

    /*
     * Override the below functions from parent contracts
     */

    // Always return tokenURI, even if token doesn't exist yet
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function transferFrom(address from, address to, uint256 tokenId) 
        public 
        override 
        onlyAllowedOperator(from) 
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) 
        public 
        override 
        onlyAllowedOperator(from) 
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}