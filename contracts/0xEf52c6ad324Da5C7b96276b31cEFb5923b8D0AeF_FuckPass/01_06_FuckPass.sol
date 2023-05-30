// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

//  
//  ░░░░░░░░░░░░░░░▄▄░░░░░░░░░░░
//  ░░░░░░░░░░░░░░█░░█░░░░░░░░░░     ________  __    __   ______   __    __        _______    ______    ______    ______  
//  ░░░░░░░░░░░░░░█░░█░░░░░░░░░░    /        |/  |  /  | /      \ /  |  /  |      /       \  /      \  /      \  /      \ 
//  ░░░░░░░░░░░░░░█░░█░░░░░░░░░░    $$$$$$$$/ $$ |  $$ |/$$$$$$  |$$ | /$$/       $$$$$$$  |/$$$$$$  |/$$$$$$  |/$$$$$$  |
//  ░░░░░░░░░░░░░░█░░█░░░░░░░░░░    $$ |__    $$ |  $$ |$$ |  $$/ $$ |/$$/        $$ |__$$ |$$ |__$$ |$$ \__$$/ $$ \__$$/ 
//  ██████▄███▄████░░███▄░░░░░░░    $$    |   $$ |  $$ |$$ |      $$  $$<         $$    $$/ $$    $$ |$$      \ $$      \ 
//  ▓▓▓▓▓▓█░░░█░░░█░░█░░░███░░░░    $$$$$/    $$ |  $$ |$$ |   __ $$$$$  \        $$$$$$$/  $$$$$$$$ | $$$$$$  | $$$$$$  |
//  ▓▓▓▓▓▓█░░░█░░░█░░█░░░█░░█░░░    $$ |      $$ \__$$ |$$ \__/  |$$ |$$  \       $$ |      $$ |  $$ |/  \__$$ |/  \__$$ |
//  ▓▓▓▓▓▓█░░░░░░░░░░░░░░█░░█░░░    $$ |      $$    $$/ $$    $$/ $$ | $$  |      $$ |      $$ |  $$ |$$    $$/ $$    $$/ 
//  ▓▓▓▓▓▓█░░░░░░░░░░░░░░░░█░░░░    $$/        $$$$$$/   $$$$$$/  $$/   $$/       $$/       $$/   $$/  $$$$$$/   $$$$$$/  
//  ▓▓▓▓▓▓█░░░░░░░░░░░░░░██░░░░░
//  ▓▓▓▓▓▓█████░░░░░░░░░██░░░░░
//  █████▀░░░░▀▀████████░░░░░░

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FuckPass is ERC721A, Ownable {
    uint256 public FUCKING_SUPPLY = 1000;
    uint256 MAX_PLUS_ONE = 1001;
    uint256 public FUCKING_MINT_PRICE = 0 ether;
    
    bytes32 public OGMerkleRoot = 0xfe4b9df6196c901a0106abc5a28bfdc0ab6c9557cd155b98f092b8822a360717;
    bytes32 public FLMerkleRoot = 0x77349c223424050aff31d0aa258f9f1e7af607424b42909f7a4b673dc8e58e2c;
    bytes32 public reserveMerkleRoot = 0x1bb48f0a9963c1a06f9c9c90a8db2997a5c993a051f7b7423f20a47584300edc;

    bool public preMintFuckingLive = false;
    bool public reserveMintFuckingLive = false;
    bool public publicMintFuckingLive = false;

    mapping(address => bool) public fuckingMinted;

    string public baseURI = "ipfs://QmRtT9fPQNAiJy5jXjLWZviwgRS3tPFnfB4ghiyoVSVLyQ?tokenID=";

    constructor() ERC721A("FuckPass", "FUCK") {}

    function fuckingMint(uint8 mintList, bytes32[] calldata _merkleProof) external //mintList = 0 for OG, 1 for FuckList, 2 for Reserve List
    {
        require(msg.sender == tx.origin, "You need to be a fucking human");
        require(preMintFuckingLive, "Mint isn't fucking live");
        require(!fuckingMinted[msg.sender], "You already fucking minted");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint8 quantity = 1;

        if (mintList == 0) { //OG mint
            require(MerkleProof.verify(_merkleProof, OGMerkleRoot, leaf), "Fuck that proof is wrong");
            quantity = 2;
        }
        else if (mintList == 1) { //FL mint
            require(MerkleProof.verify(_merkleProof, FLMerkleRoot, leaf),"Fuck that proof is wrong");
        }
        else { //Reserve mint
            require(reserveMintFuckingLive, "Reserve mint isn't fucking live");
            require(MerkleProof.verify(_merkleProof, reserveMerkleRoot, leaf),"Fuck that proof is wrong");
        }
        
        require(totalSupply() + quantity < MAX_PLUS_ONE, "All the fucking mints are gone");

        fuckingMinted[msg.sender] = true;
        _safeMint(msg.sender, quantity);
        
    }

    function publicFuckingMint() external
    {
        require(msg.sender == tx.origin, "You need to be a fucking human");
        require(publicMintFuckingLive, "Public mint isn't fucking live");
        require(!fuckingMinted[msg.sender], "You already fucking minted");
        require(totalSupply() < FUCKING_SUPPLY, "All the fucking mints are gone");

        fuckingMinted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function fuckingAirdrop(address[] calldata addresses, uint8 quantity) external onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(totalSupply() + quantity < MAX_PLUS_ONE, "Exceeds max supply");
            _safeMint(addresses[i], quantity, "");
        }
    }

    function fuckPreMintState() external onlyOwner
    {
        preMintFuckingLive = !preMintFuckingLive;
    }

    function fuckReserveMintState() external onlyOwner
    {
        reserveMintFuckingLive = !reserveMintFuckingLive;
    }
        
    function publicFuckingMintState() external onlyOwner
    {
        publicMintFuckingLive = !publicMintFuckingLive;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setFuckingURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setFuckingRoot(uint8 rootNum, bytes32 newRoot) public onlyOwner {
        if (rootNum == 0) {OGMerkleRoot = newRoot;}
        if (rootNum == 1) {FLMerkleRoot = newRoot;}
        if (rootNum == 2) {reserveMerkleRoot = newRoot;}
    }
    
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}