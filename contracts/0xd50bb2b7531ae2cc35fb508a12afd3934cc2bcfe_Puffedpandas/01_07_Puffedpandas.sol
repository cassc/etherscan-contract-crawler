// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Puffedpandas is ERC721A, Ownable {

    // Settings
    string private baseURI;
    uint256 public maxSupply = 8500;
    uint256 public mintPrice = 0.0095 ether;
    uint256 private maxMintPerTxn = 2;

    // Whitelist settings
    bytes32 public merkleRoot;
    uint256 private maxMintPerWhitelist = 2;
    mapping(address => uint256) private _mintedAmount;

    // Sale config
    enum MintStatus {
        CLOSED,
        WHITELIST,
        PUBLIC
    }
    MintStatus public mintStatus = MintStatus.CLOSED;

    constructor(
        string memory _initialBaseURI
    ) ERC721A("Puffedpandas", "PP") {
        baseURI = _initialBaseURI;
    }

    // Metadata
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Whitelist metadata
    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    // Sale metadata
    function setMintStatus(uint256 _status) external onlyOwner {
        mintStatus = MintStatus(_status);
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setMintPrice(uint256 _newMintPrice) external onlyOwner {
        mintPrice = _newMintPrice;
    }

    function withdraw() external payable onlyOwner {
        Address.sendValue(
            payable(0x6CdDA985feffaB716E15C97CC960bc7b6ff5AB0f),
            (address(this).balance * 9) / 100
        );

        Address.sendValue(
            payable(0x160bA3ECec3805303Ed289091Eec07FE3a4002a3),
            (address(this).balance)
        );
    }

    // Mint
    function mint(uint256 _amount, bytes32[] calldata proof)
        external
        payable
    {
        require(mintStatus != MintStatus.CLOSED, "Sale is inactive!");
        require(tx.origin == msg.sender, "Only humans are allowed to mint!");
        require(_amount <= maxMintPerTxn, "Max mint per transaction exceeded!");
        require(_amount > 0, "Can't mint zero!");
        require(msg.value >= mintPrice * _amount, "The ether value sent is not correct!");

        uint256 totalSupply = totalSupply();
             
        require(totalSupply + _amount <= maxSupply, "Can't mint that many!");   

        if (mintStatus == MintStatus.WHITELIST) {
            _mintWhitelist(_amount, proof);
        } else if (mintStatus == MintStatus.PUBLIC) {
            _mintPublic(_amount);
        }
    }

    function _mintWhitelist(uint256 _amount, bytes32[] calldata proof) private {
        require(mintStatus == MintStatus.WHITELIST, "Whitelist Sale is inactive!");
        require(_mintedAmount[msg.sender] + _amount <= maxMintPerWhitelist, "Can't mint that many over whitelist!");
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on whitelist!");

        _internalMint(msg.sender, _amount);
    }

    function _mintPublic(uint256 _amount) private {
        require(mintStatus == MintStatus.PUBLIC, "Public Sale is inactive!");
 
        _internalMint(msg.sender, _amount);
    }

    function _internalMint(address to, uint256 _amount) private {
        _mintedAmount[to] += _amount;
        _safeMint(to, _amount);
    }
}