//SPDX-License-Identifier: UNLICENSED

/*
 *  MonstaNFT ERC721A Contract
 *  Created by NFTSociety.io
 */

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MonstaNFT is ERC721A, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 4445;
    uint256 public currentSupply = 0;

    uint256 public p1Minted;
    uint256 public p2Minted;

    uint256 public p1MaxPerWallet = 3;
    uint256 public p2MaxPerWallet = 2;
    uint256 public p3MaxPerWallet = 1;

    //Placeholders
    address private p1Address = address(0x4fB07000170Ab3E5Cf1d1065b590b9753F02d9b6);
    address private p2Address = address(0xcbCE91bf7A07786364d6Ac1C1188dA06d2011b8c);

    address private wallet = address(0x6242DAaBadd3c08163337Cec11Db00B9a68bD149);

    string private baseURI;
    string private notRevealedUri = "ipfs://QmSNqCjYHei1WEtPNj5cn2CS1tu2Ukv1DYftPqAGaFDQsj";

    bool public revealed = false;
    bool public baseLocked = false;

    bool public p1Opened = false;
    bool public p2Opened = false;
    bool public p3Opened = false;

    mapping(address => uint256) public p1Log;
    mapping(address => uint256) public p2Log;
    mapping(address => uint256) public mintLog;

    constructor()
        ERC721A("Monsta NFT", "Monsta")
    {
        transferOwnership(msg.sender);
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address( this ).balance;
        payable( wallet ).transfer( _balance );
    }

    function setWallet(address _newWallet) public onlyOwner {
        wallet = _newWallet;
    }

    function totalSupply() public view override returns (uint256) {
        return currentSupply;
    }

    function validateSignature( address _addr, bytes memory _s ) internal view returns (bool){
        bytes32 messageHash = keccak256(
            abi.encodePacked( address(this), msg.sender)
        );

        address signer = messageHash.toEthSignedMessageHash().recover(_s);

        if( _addr == signer ) {
            return true;
        } else {
            return false;
        }
    }

    /**
        Phase 1 of the mint
     */
    function p1Mint(uint256 _amount, bytes calldata signature) external {
        //Phase 1 opened check
        require( 
            p1Opened, 
            "Monsta NFT: Phase 1 of the mint is not opened yet." 
        );

        //Check p1 signature
        require(
            validateSignature(
                p1Address,
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );

        uint256 supply = currentSupply;
        uint256 allowedAmount = p1MaxPerWallet;

        require( 
            mintLog[ msg.sender ] + _amount <= allowedAmount, 
            "Monsta NFT: You dont have permision to mint that amount." 
        );

        require(
            supply + _amount <= maxSupply,
            "Monsta NFT: Mint too large, exceeding the collection supply"
        );


        p1Log[ msg.sender ] += _amount;
        mintLog[ msg.sender ] += _amount;

        p1Minted += _amount;
        currentSupply += _amount;

        _mint( msg.sender, _amount);
    }

    /**
        Phase 2 of the mint
     */
    function p2Mint(uint256 _amount, bytes calldata signature) external {
        //P2 mint check
        require( 
            p2Opened, 
            "Monsta NFT: Phase 2 of the mint is not opened yet." 
        );

        //Check p2 mint signature
        require(
            validateSignature(
                p2Address,
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );

        uint256 supply = currentSupply;
        uint256 allowedAmount = p2MaxPerWallet;

        require( 
            mintLog[ msg.sender ] + _amount <= allowedAmount, 
            "Monsta NFT: You dont have permision to mint that amount." 
        );

        require(
            supply + _amount <= maxSupply,
            "Monsta NFT: Mint too large, exceeding the collection supply"
        );

        p2Log[ msg.sender ] += _amount;
        mintLog[ msg.sender ] += _amount;
        
        p2Minted += _amount;
        currentSupply += _amount;

        _mint( msg.sender, _amount );
    }

    /**
        Phase 3 of the mint
     */
    function publicMint(uint256 _amount) external {
        //P1 mint check
        require( 
            p3Opened, 
            "Monsta NFT: Public mint is not opened yet." 
        );

        uint256 supply = currentSupply;
        uint256 allowedAmount = p3MaxPerWallet;

        require( 
            mintLog[ msg.sender ] + _amount <= allowedAmount, 
            "Monsta NFT: You dont have permision to mint that amount." 
        );

        require(
            supply + _amount <= maxSupply,
            "Monsta NFT: Mint too large, exceeding the collection supply"
        );

        mintLog[ msg.sender ] += _amount;
        currentSupply += _amount;

        _mint( msg.sender, _amount );
    }

    function forceMint(uint256 number, address receiver) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "Monsta NFT: You can't mint more than max supply"
        );

        currentSupply += number;

        _mint( receiver, number );
    }

    function ownerMint(uint256 number) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "Monsta NFT: You can't mint more than max supply"
        );

        currentSupply += number;

        _mint( msg.sender, number );
    }

    function p1Open() public onlyOwner { 
        p1Opened = true;
    }
    
    function p1Stop() public onlyOwner {
        p1Opened = false;
    }

    function p2Open() public onlyOwner {
        p2Opened = true;
    }
    
    function p2Stop() public onlyOwner {
        p2Opened = false;
    }

    function p3Open() public onlyOwner {
        p3Opened = true;
    }
    
    function p3Stop() public onlyOwner {
        p3Opened = false;
    }

    function p1SetMPW(uint256 n) public onlyOwner {
        p1MaxPerWallet = n;
    }

    function p2SetMPW(uint256 n) public onlyOwner {
        p2MaxPerWallet = n;
    }

    function p3SetMPW(uint256 n) public onlyOwner {
        p3MaxPerWallet = n;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require( baseLocked == false, "Base URI change has been disabled permanently");

        baseURI = _newBaseURI;
    }

    //Lock base security - your nfts can never be changed.
    function lockBase() public onlyOwner {
        baseLocked = true;
    }

    // FACTORY
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
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),'.json'))
                : "";
    }
 
}