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

contract BoneDucks is ERC721AQueryable, Ownable{
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint constant public maxSupply = 6555;
    uint public maxPublicMints = 1;

    string public baseURI;
    string public notRevealedUri;
    string public uriSuffix = ".json";

    //0 -> whitelist :: 1->public
    mapping(address => mapping(uint=>uint)) public tokenMints;

    address private signer = 0x446DAAe7bB860fe2E59378816DE272b7757D466c;
    
    bool public revealed = true;
    //False on mainnet
    enum SaleStatus  {INACTIVE,WHITELIST,PUBLIC}
    SaleStatus public saleStatus = SaleStatus.INACTIVE; 

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor()
        ERC721A("BoneDucks", "BDUCKS")
    {
        setBaseURI("ipfs://Qmeabq8sqcVAifQKv7yZKYgTaqhQ3vLwYCQdNruHJ2Zukd/");
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

    function whitelistMint(uint amount,uint max, bytes memory signature) external {
        if(saleStatus != SaleStatus.WHITELIST) revert SaleNotStarted();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        bytes32 hash = keccak256(abi.encodePacked(max,msg.sender));
        if(hash.toEthSignedMessageHash().recover(signature)!=signer) revert NotWhitelisted();
        if(tokenMints[msg.sender][0] + amount > max) revert MaxMints();
        
        tokenMints[msg.sender][0] += amount;
        _mint(msg.sender,amount);
    }
    function publicMint(uint amount) external {
        if(saleStatus != SaleStatus.PUBLIC) revert SaleNotStarted();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        if(tokenMints[msg.sender][1] + amount > maxPublicMints) revert MaxMints();

        tokenMints[msg.sender][1] += amount;
        _mint(msg.sender,amount);
    }
    function setSigner(address _signer) external onlyOwner{
        signer = _signer;
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

    function setWhitelistOn() external onlyOwner {
        saleStatus = SaleStatus.WHITELIST;
    }
    function setPublicOn() external onlyOwner {
        saleStatus = SaleStatus.PUBLIC;
    }
    function turnSalesOff() external onlyOwner{
        saleStatus = SaleStatus.INACTIVE;
    }
 
    function switchReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }
    function setMaxPublicMints(uint _maxPublicMints) external onlyOwner {
        maxPublicMints = _maxPublicMints;
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
//* Not Necessary
      function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

   

}