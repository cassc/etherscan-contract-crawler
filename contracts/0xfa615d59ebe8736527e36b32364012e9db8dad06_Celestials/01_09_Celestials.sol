//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error Paused();
error SoldOut();
error SaleNotStarted();
error MintingTooMany();
error NotWhitelisted();
error Underpriced();
error MintedOut();
error MaxMints();
error ArraysDontMatch();

contract Celestials is ERC721AQueryable, Ownable{
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint public maxSupply = 2500;
    uint public whitelistPrice = .09 ether;
    uint public waitlistPrice = .09 ether;
    uint public publicPrice = .09 ether;
    uint public maxPublicMints = 6;
   
    string public baseURI;
    string public notRevealedUri;
    string public uriSuffix = ".json";

    mapping(address => uint256) public whitelistMints;
    mapping(address => uint256) public waitlistMints;
    mapping(address => uint) public publicMints;

    address signer = 0x446DAAe7bB860fe2E59378816DE272b7757D466c;

    bool public revealed;
    //False on mainnet
    enum SaleStatus  {INACTIVE,WHITELIST,WAITLIST,PUBLIC}
    SaleStatus public saleStatus = SaleStatus.INACTIVE; //todo: change on mainnet

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor()
        ERC721A("The Celestials Collection", "CLSTS")
    {
    
        setNotRevealedURI("ipfs://QmbQGmpcgoMskn1wNowHZjQYZViuSMuKSKcooYGxkrWLy7");
    
    }  


    function airdrop(address[] calldata accounts,uint[] calldata amounts) external onlyOwner{
        if(accounts.length != amounts.length) revert ArraysDontMatch();
        for(uint i; i<accounts.length;i++){
            if(totalSupply() + amounts[i] > maxSupply) revert SoldOut();
            _mint(accounts[i],amounts[i]);
        }     
    }

    /*///////////////////////////////////////////////////////////////
                          MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function whitelistMint(uint amount, uint max, bytes memory signature) external payable {
        if(saleStatus != SaleStatus.WHITELIST) revert SaleNotStarted();
        if(msg.value < amount * whitelistPrice) revert Underpriced();
        bytes32 hash = keccak256(abi.encodePacked("WHITELIST",max,msg.sender));
        if(hash.toEthSignedMessageHash().recover(signature) != signer) revert NotWhitelisted();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        if(whitelistMints[msg.sender] + amount > max) revert MaxMints();

        whitelistMints[msg.sender] += amount;
        _mint(msg.sender,amount);
    }
    function waitlistMint(uint amount, uint max, bytes memory signature) external payable {
        if(saleStatus != SaleStatus.WAITLIST) revert SaleNotStarted();
        if(msg.value < amount * waitlistPrice) revert Underpriced();
        bytes32 hash = keccak256(abi.encodePacked("WAITLIST",max,msg.sender));
        if(hash.toEthSignedMessageHash().recover(signature) != signer) revert NotWhitelisted();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        if(waitlistMints[msg.sender] + amount > max) revert MaxMints();

        waitlistMints[msg.sender] += amount;
        _mint(msg.sender,amount);
    }
    function publicMint(uint amount) external payable {
        if(saleStatus != SaleStatus.PUBLIC) revert SaleNotStarted();
        if(msg.value < amount * publicPrice) revert Underpriced();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        if(publicMints[msg.sender] + amount > maxPublicMints) revert MaxMints();

        publicMints[msg.sender] += amount;
        _mint(msg.sender,amount);
    }
    /*///////////////////////////////////////////////////////////////
                          MINTING UTILITIES
    //////////////////////////////////////////////////////////////*/
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
            require(_maxSupply <= maxSupply,"Can Only Decrease Supply");
            maxSupply = _maxSupply; 
    }
    function setWhitelistPrice(uint price) external onlyOwner {
        whitelistPrice = price;
    }

    function setWaitlistPrice(uint price) external onlyOwner {
        waitlistPrice = price;
    }
    function setPublicPrice(uint price) external onlyOwner {
        publicPrice = price;
    }

    function setWhitelistOn() external onlyOwner {
        saleStatus = SaleStatus.WHITELIST;
    }
    function setWaitlistOn() external onlyOwner {
        saleStatus = SaleStatus.WAITLIST;
    }
    function setPublicOn() external onlyOwner {
        saleStatus = SaleStatus.PUBLIC;
    }
    function turnAllSalesOff() external onlyOwner{
        saleStatus = SaleStatus.INACTIVE;
    }
    function setMaxPublicMints(uint newMax) external onlyOwner{
        maxPublicMints = newMax;
    }

    function setSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }

    function switchReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    /*///////////////////////////////////////////////////////////////
                                METADATA
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _toString(tokenId),uriSuffix))
                : "";
    }

    /*///////////////////////////////////////////////////////////////
                           WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

      function withdraw() public  onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

   

}