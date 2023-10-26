// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract Paradigm is Ownable, ERC721A {
    enum SaleStatus {
        Inactive,
        Genesis,
        Public,
        Whitelist,
        Final,
        Completed
    }

    // PUBLIC SPOTS is MAX_WORLDS - WHITELIST_SPOTS (5000-1500)
    uint256 constant public PUBLIC_SPOTS = 3500;
    uint256 constant public MAX_WORLDS = 5000;
    // Realistically this will only reach 750 at most, since 50 genesis holders didn't claim free mint
    uint256 constant public MAX_GENESIS = 800;
    uint256 constant public MAX_MINT = 5;

    uint256 public whitelistPrice = 0.25 ether;
    uint256 public publicPrice = 0.35 ether;

    SaleStatus public saleStatus;

    bytes32 private _merkleRoot;

    mapping(address => uint256) public genesisMints;
    mapping(address => uint256) public whitelistMints;

    string private _baseTokenURI = "https://data.forgottenethereal.world/paradigm/metadata/";

    modifier noContracts() {
        require(msg.sender == tx.origin);
        _;
    }

    constructor() ERC721A("Forgotten Ethereal Worlds Paradigm", "PRDM") {}

    // Genesis Mint Mechanism

    function genesisMint(uint256 _proofMints, uint256 _freeMints, uint256 _mints, bytes32[] calldata _proof) external payable noContracts {
        require(saleStatus == SaleStatus.Genesis, "Paradigm: Genesis mint isn't active");
        require(totalSupply() + _mints <= MAX_GENESIS, "Paradigm: Exceeds Max Supply");
        uint256 _totalMints = genesisMints[msg.sender] + _mints;
        require(_totalMints <= _proofMints, "Paradigm: Already Minted");

        if(genesisMints[msg.sender] > 0) {
            require(msg.value >= _mints * whitelistPrice, "Paradigm: Insufficient funds");
        }
        else {
            require(_mints >= _freeMints, "Paradigm: Must mint all free mints");
            require(msg.value >= (_mints - _freeMints) * whitelistPrice, "Paradigm: Insufficient funds");
        }
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _proofMints, _freeMints));
        require(MerkleProof.verify(_proof, _merkleRoot, leaf), "Paradigm: Invalid Proof");

        genesisMints[msg.sender] = _totalMints;

        _mint(msg.sender, _mints);
    }

    // Public Mint Mechanism

    function publicMint(uint256 _mints) external payable noContracts {
        require(saleStatus == SaleStatus.Public, "Paradigm: Public mint isn't active");
        require(_mints <= MAX_MINT, "Paradigm: Exceeds Max per TXN");
        require(totalSupply() + _mints <= PUBLIC_SPOTS, "Paradigm: Exceeds Max Allocation");
        require(msg.value >= publicPrice * _mints, "Paradigm: Insufficient funds");

        _mint(msg.sender, _mints);
    }

    // Whitelist Mint Mechanism

    function whitelistMint(uint256 _proofMints, uint256 _mints, bytes32[] calldata _proof) external payable noContracts {
        require(saleStatus == SaleStatus.Whitelist, "Paradigm: Whitelist mint isn't active");
        require(totalSupply() <= MAX_WORLDS, "Paradigm: Exceeds Max Supply");
        require(whitelistMints[msg.sender] + _mints <= _proofMints, "Paradigm: Already Minted Whitelist");
        require(msg.value == _mints * whitelistPrice, "Paradigm: Insufficient funds");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _proofMints));
        require(MerkleProof.verify(_proof, _merkleRoot, leaf), "Paradigm: Invalid Proof");

        whitelistMints[msg.sender] += _mints;

        _mint(msg.sender, _mints);
    }

    // Final Mint Mechanism
    
    function finalMint(uint256 _mints) external payable noContracts {
        require(saleStatus == SaleStatus.Final, "Paradigm: Final mint isn't active");
        require(_mints <= MAX_MINT, "Paradigm: Exceeds Max per TXN");
        require(totalSupply() + _mints <= MAX_WORLDS, "Paradigm: Exceeds Max Allocation");
        require(msg.value >= publicPrice * _mints, "Paradigm: Insufficient funds");

        _mint(msg.sender, _mints);
    }

    // Owner functions
    
    function treasuryMint(uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= MAX_WORLDS, "Paradigm: Cannot mint more than total supply");
        _safeMint(0x17020cBf555670aB1c7f3e64a80dA61b0B4990c0, _amount);
    }

    function airdropAuction(address[] calldata winners) external onlyOwner {
        require(totalSupply() + winners.length <= MAX_WORLDS, "Paradigm: Cannot mint more than total supply");
        
        for (uint i = 0; i < winners.length;) {
            _mint(winners[i], 1);

            unchecked {
                i++;
            }
        }
    }

    function setSalePrice(uint256 _publicPrice, uint256 _whitelistPrice) external onlyOwner {
        publicPrice = _publicPrice;
        whitelistPrice = _whitelistPrice;
    }

    function setSaleData(SaleStatus _newStatus, bytes32 _newRoot) external onlyOwner {
        saleStatus = _newStatus;
        _merkleRoot = _newRoot;
    }

    function setStatus(SaleStatus _newStatus) external onlyOwner {
        saleStatus = _newStatus;
    }

    function setMerkle(bytes32 _newRoot) external onlyOwner {
        _merkleRoot = _newRoot;
    }

    function withdrawAll(address _wallet) external onlyOwner {
        uint256 balance = address(this).balance;
        
        payable(_wallet).transfer(balance);
    }

    // Base URI standard functions

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}