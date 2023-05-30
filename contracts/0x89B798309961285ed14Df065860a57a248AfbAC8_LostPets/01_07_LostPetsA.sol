//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {ILostPetsRenderer} from './interfaces/ILostPetsRenderer.sol';

contract LostPets is ERC721A, Ownable {
    ILostPetsRenderer public renderer;
    
    uint256 public constant MAX_TOKENS = 201;    
    uint256 public constant TOKEN_PRICE = 0.01 ether;

    bytes32 public root;

    bool public mintingPublic;

    mapping(address => uint256) private reserveMintCountsRemaining;

    constructor() ERC721A("Lost Pets of New York", "LOSTPETS") Ownable() {
    }

    function setMintingPublic(bool newMintingPublic) external onlyOwner
    {
        mintingPublic = newMintingPublic;
    }

    function setRenderer(ILostPetsRenderer newRenderer) external onlyOwner
    {
        renderer = newRenderer;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) { 
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
            
        return renderer.tokenURI(tokenId);
    }

    function mint(address to, uint256 count, bytes32[] calldata proof) external payable {
        require(totalSupply() + count <= MAX_TOKENS, "all lostpets claimed");
        require(msg.value == count * TOKEN_PRICE, "0.01 ETH per lostpet to mint");
        require(MerkleProof.verify(proof, root, generateMerkleLeaf(to)), "Not whitelisted");

        _safeMint(to, count);
    }

    function mintPublic(address to, uint256 count) external payable {
        require(totalSupply() + count <= MAX_TOKENS, "all lostpets claimed");
        require(msg.value == count * TOKEN_PRICE, "0.01 ETH per lostpet to mint");
        require(mintingPublic, "Not Public Mint");

        _safeMint(to, count);
    }

    function allocateReserveMint(address addr, uint256 count) public onlyOwner {
        reserveMintCountsRemaining[addr] = count;
    }

    function getNumReserveMints(address addr) public view returns (uint256) {
        return reserveMintCountsRemaining[addr];
    }

    function reserveMint(uint256 count) external {
        require(count > 0, "invalid lostpet count");
        require(reserveMintCountsRemaining[msg.sender] >= count, "Cannot mint this many reserved lostpets");
        require(totalSupply() + count <= MAX_TOKENS, "all lostpets claimed");

        reserveMintCountsRemaining[msg.sender] -= count;
        _safeMint(_msgSender(), count);
    }

    function withdraw() public onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        require(success, "Withdraw Failed");
    }

    //Whitelist Stuff
    function generateMerkleLeaf(address account) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(account))));
    }
    
    function setRoot(bytes32 newRoot) public onlyOwner {
        root = newRoot;
    }
}