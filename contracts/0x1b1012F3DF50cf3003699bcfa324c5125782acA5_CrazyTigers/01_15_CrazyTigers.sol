//SPDX-License-Identifier: Unlicense
// Art by @walshe_steve // Copyright © Steve Walshe
// Code by @0xGeeLoko


/* 

             (`-')  (`-')  _   (`-')                 (`-')      _                (`-')  _   (`-')  (`-').-> 
 _        <-.(OO )  (OO ).-/   ( OO).->    .->       ( OO).->  (_)        .->    ( OO).-/<-.(OO )  ( OO)_   
 \-,-----.,------,) / ,---.  ,(_/----. ,--.'  ,-.    /    '._  ,-(`-') ,---(`-')(,------.,------,)(_)--\_)  
  |  .--./|   /`. ' | \ /`.\ |__,    |(`-')'.'  /    |'--...__)| ( OO)'  .-(OO ) |  .---'|   /`. '/    _ /  
 /_) (`-')|  |_.' | '-'|_.' | (_/   / (OO \    /     `--.  .--'|  |  )|  | .-, \(|  '--. |  |_.' |\_..`--.  
 ||  |OO )|  .   .'(|  .-.  | .'  .'_  |  /   /)        |  |  (|  |_/ |  | '.(_/ |  .--' |  .   .'.-._)   \ 
(_'  '--'\|  |\  \  |  | |  ||       | `-/   /`         |  |   |  |'->|  '-'  |  |  `---.|  |\  \ \       / 
   `-----'`--' '--' `--' `--'`-------'   `--'           `--'   `--'    `-----'   `------'`--' '--' `-----'  

 */

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./MerkleDistributor.sol";


contract CrazyTigers is ERC721A, MerkleDistributor, Ownable, ReentrancyGuard {
    using Strings for string;
    
    uint256 public mintPrice = 9000000000000000;
    uint256 public maxSupply = 3333;
    uint256 public maxReserve = 667;
    uint256 public maxDev = 333;
    uint256 public maxAllow = 2;
    uint256 public maxPublic = 6;
    uint256 public maxVip = 1;

    mapping(address => uint256) public vipWalletMints;
    address payable private founderWallet = payable(0xe03064F8fB12B6457A04166e1462889b98323931);
    address payable private artistWallet = payable(0x7fF7549e6594B24c88c4f08BCBb67Aa6fC549175);

    string internal baseTokenUri;
    bool public saleActive;
    bool public saleOver;
    uint256 public reserveSupply;
    uint256 public devSupply;

    
    
    

    
    constructor() ERC721A('Crazy Tigers','CT') {}


    modifier ableToMint(uint256 numberOfTokens) {
        require(totalSupply() + numberOfTokens <= maxSupply, 'Purchase would exceed Max Token Supply');
        _;
    }

    modifier ableToVipMint(uint256 numberOfTokens) {
        require(totalSupply() + numberOfTokens <= maxReserve, 'Purchase would exceed max VIP reserve');
        _;
    }
    
    modifier isPublicSaleActive() {
        require(saleActive, 'Public sale is not active');
        _;
    }
    modifier isVipSaleOver() {
        require(saleOver, 'Vip sale is not over');
        _;
    }
    /**
     * allow list
     */
    function setAllowListActive(bool allowListActive) external onlyOwner {
    _setAllowListActive(allowListActive);
    }
    
    function setAllowList(bytes32 merkleRoot) external onlyOwner {
        _setAllowList(merkleRoot);
    }
    

    /**
     * tokens
     */
    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }
    

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'Token does not exist!');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId), '.json'));
    }


    /**
     * admin
     */
    
    function devMint(uint256 numberOfTokens) 
    external 
    onlyOwner
    ableToMint(numberOfTokens)
    nonReentrant {
        require(numberOfTokens > 0, "Must mint at least one");
        require(devSupply + numberOfTokens <= maxDev, 'minted out team reserve');
        
        devSupply += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }
    

    function setSaleActive(bool state) external onlyOwner {
        saleActive = state;
    }

    function setVipSaleOver(bool state) external onlyOwner {
        saleOver = state;
    }
    

    /**
     * public
     */

    function vipMint(uint256 numberOfTokens, bytes32[] memory merkleProof) 
    external 
    isAllowListActive
    ableToClaim(msg.sender, merkleProof) 
    ableToVipMint(numberOfTokens)
    nonReentrant {
        require(numberOfTokens > 0, "Must mint at least one");
        require(reserveSupply + numberOfTokens <= maxReserve, 'minted out VIP reserve');
        require(vipWalletMints[msg.sender] + numberOfTokens <= maxVip, 'exceed max wallet');
        
        reserveSupply += numberOfTokens;
        vipWalletMints[msg.sender] += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function allowListMint(uint256 numberOfTokens, bytes32[] memory merkleProof) 
    external
    payable
    isAllowListActive
    isVipSaleOver
    ableToClaim(msg.sender, merkleProof)
    tokensAvailable(msg.sender, numberOfTokens, maxAllow)
    ableToMint(numberOfTokens)
    nonReentrant 
    {
        require(numberOfTokens > 0, "Must mint at least one");
        require(numberOfTokens * mintPrice == msg.value, 'Ether value sent is not correct');
        
        _setAllowListMinted(msg.sender, numberOfTokens);
        _safeMint(msg.sender, numberOfTokens);
    }

    function publicMint(uint256 numberOfTokens) 
    external
    payable
    isPublicSaleActive
    ableToMint(numberOfTokens)
    nonReentrant
    {
        require(numberOfTokens > 0, "Must mint at least one");
        require(numberOfTokens <= maxPublic, 'Exceeded max token purchase');
        require(numberOfTokens * mintPrice == msg.value, 'Ether value sent is not correct');
        
       
        _safeMint(msg.sender, numberOfTokens);

    }

    /**
     * withdraw
     */

    function withdraw() external nonReentrant
    {
        require(msg.sender == founderWallet || msg.sender == artistWallet || msg.sender == owner(), "Invalid sender");
        (bool success, ) = founderWallet.call{value: address(this).balance / 100 * 75}("");
        (bool success2, ) = artistWallet.call{value: address(this).balance / 100 * 40}(""); 
        (bool success3, ) = owner().call{value: address(this).balance}(""); 
        require(success, "Transfer 1 failed");
        require(success2, "Transfer 2 failed");
        require(success3, "Transfer 3 failed");
    }
    
}