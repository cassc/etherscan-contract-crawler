/*

 .d8888b.           888                .d8888b.          .d8888b.                                                 .d8888b.                                    
d88P  Y88b          888               d88P  "88b        d88P  Y88b                                               d88P  Y88b                                   
888    888          888               Y88b. d88P        888    888                                               888    888                                   
888        888  888 888888 .d88b.      "Y8888P"         888        888d888 .d88b.   .d88b.  88888b.  888  888    888         8888b.  88888b.   .d88b.     d8b 
888        888  888 888   d8P  Y8b    .d88P88K.d88P     888        888P"  d8P  Y8b d8P  Y8b 888 "88b 888  888    888  88888     "88b 888 "88b d88P"88b    Y8P 
888    888 888  888 888   88888888    888"  Y888P"      888    888 888    88888888 88888888 888  888 888  888    888    888 .d888888 888  888 888  888        
Y88b  d88P Y88b 888 Y88b. Y8b.        Y88b .d8888b      Y88b  d88P 888    Y8b.     Y8b.     888 d88P Y88b 888    Y88b  d88P 888  888 888  888 Y88b 888    d8b 
 "Y8888P"   "Y88888  "Y888 "Y8888      "Y8888P" Y88b     "Y8888P"  888     "Y8888   "Y8888  88888P"   "Y88888     "Y8888P88 "Y888888 888  888  "Y88888    Y8P 
                                                                                            888           888                                      888        
                                                                                            888      Y8b d88P                                 Y8b d88P        
                                                                                            888       "Y88P"                                   "Y88P"         

888                                           888       888 d8b 888            888      
888                                           888   o   888 Y8P 888            888      
888                                           888  d8b  888     888            888      
888     888  888 88888b.   8888b.  888d888    888 d888b 888 888 888888 .d8888b 88888b.  
888     888  888 888 "88b     "88b 888P"      888d88888b888 888 888   d88P"    888 "88b 
888     888  888 888  888 .d888888 888        88888P Y88888 888 888   888      888  888 
888     Y88b 888 888  888 888  888 888        8888P   Y8888 888 Y88b. Y88b.    888  888 
88888888 "Y88888 888  888 "Y888888 888        888P     Y888 888  "Y888 "Y8888P 888  888 
                                                                                        
                                                                                                                                       
*/

/**
 * @title  Smart Contract for the Cute & Creepy Dolls : Lunar Witch Project
 * @author SteelBalls
 * @notice NFT Minting
 */

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PaymentSplitter} from "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error InsufficientPayment();

contract LunarWitch is ERC721A, DefaultOperatorFilterer, Ownable, PaymentSplitter {

    string public baseTokenURI;
    // tokenIds will range from 1-6666
    uint256 public maxTokens = 6666;
    uint256 public tokenReserve = 66;

    bool public publicMintActive = false;
    uint256 public publicMintPrice = 0.0666 ether;
    uint256 public maxTokenPurchase = 12;
    
    bool public presaleMintActive = false;
    uint256 public constant presaleMintPrice = 0.0666 ether;
    uint256 public constant presaleMintMax = 6;

    /* Merkle Tree Root
        The root hash of the Merkle Tree previously generated from our JS code. Remember to
        provide this as a bytes32 type and not a string. Should be prefixed with 0x.
    */
    bytes32 public merkleRoot;

    // Record whitelist addresses that have claimed
    mapping(address => uint256) private presaleMintedAmount; 
    
    // Team Wallets & Shares
    address[] private teamWallets = [
        0x7608E1d480B2a254A0F0814DADc00169745CF55B, 
        0xCECD66ff3D2f87d0Af011b509b832748Dc2CD8E2, 
        0xd38eF170FcB60EE0FE7478DE0C9f2b2cCF3Ab574,
        0x273012FDa2E21D982b6e11E90c55172dffDeD8B3,
        0x75710cf256C0C5d157a792CB9D7A9cCc2D7E13a7, 
        0x7d436a3736a9f83f62Af88232A6D556eC9d05C9B
    ];
    uint256[] private teamShares = [3500, 3500, 1524, 676, 500, 300];

    // Constructor
    constructor()
        PaymentSplitter(teamWallets, teamShares)
        ERC721A("Cute & Creepy Gang: Lunar Witch", "LUNAR")
    {}

    modifier onlyOwnerOrTeam() {
        require(
            teamWallets[0] == msg.sender ||
            teamWallets[1] == msg.sender || 
            teamWallets[2] == msg.sender || 
            teamWallets[3] == msg.sender ||
            teamWallets[4] == msg.sender || 
            owner() == msg.sender,
            "caller is not the Owner or a Team Member"
        );
        _;
    }

    // Set the merkle root
    function setMerkleRoot(bytes32 _merkleRootValue) external onlyOwner returns (bytes32) {
        merkleRoot = _merkleRootValue;
        return merkleRoot;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
        payable
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Mint from reserve allocation for team, promotions and giveaways
    function reserveTokens(address _to, uint256 _reserveAmount) external onlyOwner {        
        require(_reserveAmount <= tokenReserve, "RESERVE_EXCEEDED");
        require(totalSupply() + _reserveAmount <= maxTokens, "MAX_SUPPLY_EXCEEDED");

        _safeMint(_to, _reserveAmount);
        tokenReserve -= _reserveAmount;
    }

    /*
       @dev   Presale Whitelist mint
       @param _numberOfTokens Quantity to mint
       @param _merkleProof Root merkle proof to submit
    */
    function presaleWhitelistMint(uint256 _numberOfTokens, bytes32[] calldata _merkleProof) external payable {
        require(presaleMintActive, "SALE_NOT_ACTIVE");
        require(msg.sender == tx.origin, "CALLER_CANNOT_BE_CONTRACT");
        require(presaleMintedAmount[msg.sender] + _numberOfTokens <= presaleMintMax, "MAX_PRESALE_EXCEEDED");
        require(totalSupply() + _numberOfTokens <= maxTokens - tokenReserve, "MAX_SUPPLY_EXCEEDED");

        // Verify the provided _merkleProof, given to us through the API on the website
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "NOT_IN_WHITELIST");

        require(msg.value >= presaleMintPrice * _numberOfTokens, "NOT_ENOUGH_ETHER");

        // Record presale quantity minted for the wallet
        presaleMintedAmount[msg.sender] += _numberOfTokens;
        _safeMint(msg.sender, _numberOfTokens);   

    }

    /*
       @dev   Public mint
       @param _numberOfTokens Quantity to mint
    */
    function publicMint(uint _numberOfTokens) external payable {
        require(publicMintActive, "SALE_NOT_ACTIVE");
        require(msg.sender == tx.origin, "CALLER_CANNOT_BE_CONTRACT");
        require(_numberOfTokens <= maxTokenPurchase, "MAX_TOKENS_EXCEEDED");
        require(totalSupply() + _numberOfTokens <= maxTokens - tokenReserve, "MAX_SUPPLY_EXCEEDED");

        uint256 cost = _numberOfTokens * publicMintPrice;
        if (msg.value < cost) revert InsufficientPayment();
        
        _safeMint(msg.sender, _numberOfTokens);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function togglePresaleMint() external onlyOwner {
        presaleMintActive = !presaleMintActive;
    }

    function togglePublicMint() external onlyOwner {
        publicMintActive = !publicMintActive;
    }

    function setPublicMintPrice(uint256 _newPrice) external onlyOwner {
        publicMintPrice = _newPrice;
    }

    function setMaxTokenPurchase(uint256 _newMaxTokenPurchase) external onlyOwner {
        maxTokenPurchase = _newMaxTokenPurchase;
    }

    function presaleMintClaimed(address _wallet) external view returns (uint256) {
        return presaleMintedAmount[_wallet];
    }

    function setTokenReserve(uint256 _newTokenReserve) external onlyOwner {
        tokenReserve = _newTokenReserve;
    }

    function remainingSupply() external view returns (uint256) {
        return maxTokens - totalSupply();
    }

    function lowerMaxSupply(uint256 _newMax) external onlyOwner {
        require(_newMax < maxTokens, "Can only lower supply");
        require(maxTokens > totalSupply(), "Can't set below current");
        maxTokens = _newMax;
    }

    function withdrawShares() external onlyOwnerOrTeam {
        uint256 balance = address(this).balance;
        require(balance > 0);
        for (uint256 i = 0; i < teamWallets.length; i++) {
            address payable wallet = payable(teamWallets[i]);
            release(wallet);
        }
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        payable(msg.sender).transfer(address(this).balance);
    }

}