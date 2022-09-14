// ░█████╗░░█████╗░██╗░░░░░██╗░░░░░███████╗░█████╗░████████╗░█████╗░██████╗░  ░█████╗░██╗░░░░░██╗░░░██╗██████╗░ 
// ██╔══██╗██╔══██╗██║░░░░░██║░░░░░██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗  ██╔══██╗██║░░░░░██║░░░██║██╔══██╗ 
// ██║░░╚═╝██║░░██║██║░░░░░██║░░░░░█████╗░░██║░░╚═╝░░░██║░░░██║░░██║██████╔╝  ██║░░╚═╝██║░░░░░██║░░░██║██████╦╝ 
// ██║░░██╗██║░░██║██║░░░░░██║░░░░░██╔══╝░░██║░░██╗░░░██║░░░██║░░██║██╔══██╗  ██║░░██╗██║░░░░░██║░░░██║██╔══██╗ 
// ╚█████╔╝╚█████╔╝███████╗███████╗███████╗╚█████╔╝░░░██║░░░╚█████╔╝██║░░██║  ╚█████╔╝███████╗╚██████╔╝██████╦╝ 
// ░╚════╝░░╚════╝░╚══════╝╚══════╝╚══════╝░╚════╝░░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝  ░╚════╝░╚══════╝░╚═════╝░╚═════╝░ 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract collector_club is ERC721A, Ownable {
    uint256 MAX_MINTS = 1;
    uint256 MAX_SUPPLY = 1001;
    uint256 public mintRate = 0 ether;
    bytes32 public root = 0xf7694b9693d0e69db369833686c5e8482df248921955b862a1e2fa7bfb3a945d;

    string private _baseTokenURI;

    constructor() ERC721A("Collector Club", "CClub") {}


    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 quantity, bytes32[] memory proof) external payable  {
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "You are not whitelisted or the proof is wrong");
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(address addr, uint quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        _safeMint(addr, quantity);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMaxMints(uint256 _MAX_MINTS) public onlyOwner {
        MAX_MINTS = _MAX_MINTS;
    }

    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns(bool){
        return MerkleProof.verify(proof, root, leaf);
    }

    function setRoot(bytes32 _root) public onlyOwner {
        root = _root;
    }

}