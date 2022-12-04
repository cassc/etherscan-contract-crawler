// SPDX-License-Identifier: MIT

// ⠀⠀⠀⣀⣄⣀⠀⠀⠀⠀⠀⠀⣀⣠⣀⠀⠀⠀⠀⠀
// ⠀⠀⢸⣿⣩⣿⣷⣶⣶⣶⣶⣾⣿⣍⣿⡇⠀⠀⠀⠀
// ⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⢁⣀⣀⡀⠀
// ⠀⠀⣾⣿⠟⠉⠉⠻⣿⣿⠟⠉⠉⠛⠀⣿⣿⣿⣿⣦
// ⠀⢠⣿⣿⣷⡿⢿⣾⠛⠛⣷⡿⣿⣾⣦⣈⠉⠙⠛⠋
// ⠀⠀⢿⣿⣿⣧⣤⣀⣤⣤⣀⣤⣼⣿⣿⡿⠀⣼⡿⠀
// ⠀⣀⣬⠻⠿⢿⣿⣿⣿⣿⣿⣿⡿⠿⠟⣁⠐⡿⠃⠀
// ⣸⣿⣿⠀⠀⠀⠀⠀⢠⡄⠀⠀⢀⣀⣼⣿⡆⠀⠀⠀
// ⣿⣿⣿⣷⣶⣄⠙⣧⣄⣠⣼⣿⣿⣿⣿⣿⣷⠀⠀⠀
// ⠘⢿⣿⣿⣿⣿⠀⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀
// ⣤⣄⡉⠙⠋⣁⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀
// ⠟⠉⣉⣉⡉⠙⠿⣿⣿⣿⣿⠿⠋⢉⣉⣉⠉⠻⠀⠀
// ⢠⣾⣿⣿⣿⣷⣦⡈⢻⡟⢁⣴⣾⣿⣿⣿⣷⡄⠀⠀
// ⠸⣿⣿⣿⣿⣿⣿⡇⠀⠀⢸⣿⣿⣿⣿⣿⣿⠇⠀⠀
// ⠀⠈⠉⠙⠛⠉⠉⠀⠀⠀⠀⠉⠉⠛⠋⠉⠁⠀⠀⠀

//  BOBO DEGEN APOCALYPSE PRESENTS: CATGIRL DEGEN APOCALYPSE !!!
//
//  6969 UNIQUE CATGIRLS TO KEEP YOUR BOBO WARM THIS APOCALYPSE !
//
//  3 STAGE MINT:
//  STAGE 1: AIRDROP
//  STAGE 2: FREE MINT FOR BOBOS
//  STAGE 3: PUBLIC MINT FOR 0.0069 ETH / CATGIRL
// 
//  THIS IS ART

pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

import "hardhat/console.sol";

contract Catgirls is ERC721A, Ownable, PaymentSplitter {

    address public BOBO = 0x61FE5Ff877eb105826cEC347d1826c5489460FEf;
    uint public price = 0.0069 ether;
    uint public kittySupply = 6969;
    uint freeMintThreshhold = 3469;
    bool public apocalypse = false;
    uint8 maxMint = 10;

    //  After sequential updates, you can individually select which metadata version to display for your nft
    mapping(uint => bool) custom;
    mapping(uint => uint) URIindex;
    mapping(uint => string) baseURIs;
    uint256 public newest = 0;

    // Artist and Dev fair payout 
    address[] private _payees  =  [0xaCB906C4A9C01C4344fB962A59d2fbcBA2da2a33 ,0x111BB2AaC9d9ad2C44d67Dc2200c8219eCa62939 ]; // don't forget to add real addresses
    uint256[] private _shares = [50,50];

    modifier dumbContracts() {
        require(tx.origin == msg.sender);
        _;
    }

    constructor() ERC721A("CATGIRL DEGEN APOCALYPSE", "CAT") PaymentSplitter(_payees, _shares ) {
        baseURIs[0] = "ipfs://Qmd94zbswmP9yuQn8gJ6QopN34ReDm3seVSVVkPfVhocwu/";
    }

// there's only one way here. no stopping once unleashed
    function bigRedButton() public onlyOwner{
        apocalypse = true;
    }

    function apocalypseNow() external view returns(bool) {
        return apocalypse;
    }

    function airdrop(address[] memory boborray) public onlyOwner {
        require(!apocalypse);

        for(uint i=0;i<boborray.length;i++){
            _mint(boborray[i],1);
        }
    }

    function batchAirdrop(address[] memory boborray, uint[] memory amount) public onlyOwner {
        require(!apocalypse);

        for(uint i=0;i<boborray.length;i++){
            _mint(boborray[i],amount[i]);
        }
    }

    function mint(uint8 amount) public payable dumbContracts{
        require(apocalypse, "WAIT FOR THE AIRDROP TO COMPLETE");
        require(!mintedout(), "MINTED OUT!");
        require(_totalMinted() + amount <= kittySupply, "SUPPLY LIMIT CROSSED");
        require(amount <= maxMint ,"MAX 10 CATGIRLS PER TX");

        if(_totalMinted() < freeMintThreshhold){
            require(_totalMinted() + amount <= freeMintThreshhold, "LIMIT CROSSED");
            uint held = Bobo(BOBO).balanceOf(msg.sender);
            require(held>0, "GET YOURSELF A BOBO OR TEN");
            console.log(held);
            if(held < 3){
                require(amount == 1, "YOU NEED MORE BOBOS TO MINT BIGGER BATCHES");
                _mint(msg.sender,1);
            } else if(held < 5){
                require(amount < 3, "YOU NEED MORE BOBOS TO MINT BIGGER BATCHES");
                _mint(msg.sender,amount);
            } else if(held < 10){
                require(amount < 4, "YOU NEED MORE BOBOS TO MINT BIGGER BATCHES");
                _mint(msg.sender,amount);
            } else if(held >= 10){
                require(amount <= (((held - held % 5) / 5) + 2)  , "YOU NEED MORE BOBOS TO MINT BIGGER BATCHES");
                _mint(msg.sender,amount);
            }
        }else{
            require(msg.value == amount * price, "WRONG PAYMENT VALUE"); // revise how this plays out around the threshhold
            require(_totalMinted() + amount <= kittySupply, "LIMIT CROSSED");
            _mint(msg.sender,amount);
        }
    }

    function totalMinted() external view returns(uint256){
        return _totalMinted();
    }

    function mintedout() public view returns (bool){
        return _totalMinted() >= kittySupply;
    }

    function _baseURI(uint256 tokenID) public view returns (string memory) {
        if(custom[tokenID] == true){
            return baseURIs[URIindex[tokenID]];
        } else {
            return baseURIs[newest];
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if(newest == 0){
            return bytes(baseURIs[0]).length != 0 ? string(abi.encodePacked(baseURIs[0], "hidden.json")) : '';
        }
        else {
            string memory baseURI = _baseURI(tokenId);
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
        }
    }

    function customURIindex (uint256 tokenID, uint256 index) public {
        require(index != 0,"prereveal image restricted");
        require( ownerOf(tokenID) == msg.sender, "you don't own this token");
        require((keccak256(abi.encodePacked(baseURIs[index])) != keccak256(abi.encodePacked(""))));
        URIindex[tokenID] = index;
        custom[tokenID] = true;
    }

    function trackNewestURI(uint256 tokenID) public {
        require( ownerOf(tokenID)== msg.sender, "you don't own this token");
        require(custom[tokenID] == true);
        custom[tokenID] = false;
    }
    
    function addBaseURI (string memory URI, uint index) public onlyOwner {
        require((keccak256(abi.encodePacked(baseURIs[index])) == keccak256(abi.encodePacked(""))));
        baseURIs[index] = URI;
        newest = index;
    }

    function contractURI() public view returns(string memory){
        return string(abi.encodePacked(baseURIs[newest],"contractURI.json"));
    }

    function sacrifice(uint256 tokenId) public returns(string memory) {
        _burn(tokenId, true);
        return "sacrificed";
    }
}

interface Bobo {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
}