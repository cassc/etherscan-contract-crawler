// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract FlappyFrames is ERC721A, Ownable {

    uint256 public immutable maxSupply;
    uint256 public immutable maxMintPerAddress;

    bytes32 public merkleRoot;
    bool public isSaleLive;
    string public baseURI;

    mapping (address => uint256) public addressMintCount;

    constructor(
        uint256 _maxSupply,
        uint256 _maxMintPerAddress
    ) ERC721A("Flappy Frames", "FlappyFrames") {
        maxSupply = _maxSupply;
        maxMintPerAddress = _maxMintPerAddress;
    }

    function mint(bytes32[] calldata merkleProof) external payable {
        require(isSaleLive, "Sale not live");
        require(addressMintCount[msg.sender] + 1 <= maxMintPerAddress, "Max mint exceeded for this address");
        require(totalSupply() + 1 <= maxSupply, "Max supply reached");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid merkle proof");

        addressMintCount[msg.sender]++;
        _safeMint(msg.sender, 1);
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "Quantity exceeds max supply");
        _safeMint(msg.sender, quantity);
    }

    function toggleSaleStatus() external onlyOwner {
        isSaleLive = !isSaleLive;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}