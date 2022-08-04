// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ToshimetaPasses is ERC1155Supply, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 public constant GenesisPass = 1;
    uint256 public constant ToshimetaPass = 2;
    bytes32 public genesisMerkleRoot;
    bytes32 public toshimetaMerkleRoot;

    bool public paused = false;
    bool public publicSaleActive = false;
    bool public privateSaleActive = false;
    string private baseURI;

    uint256 public genesisPassCost = 0.08 ether;
    uint256 public genesisSupply = 1111;
    uint256 public genesisMintAmount = 1;
    uint256 public genesisMintPerAddr = 1;

    uint256 public toshimetaPassCost = 0.05 ether;
    uint256 public toshimetaSupply = 2500;
    uint256 public toshimetaMintAmount = 1;
    uint256 public toshimetaMintPerAddr = 1;

    string public name = "Toshimeta Pass";
    string public contractURIstr = "";

    mapping(address => uint256) public genesisAddressMintedBalance;
    mapping(address => uint256) public toshimetaAddressMintedBalance;
    mapping (address => uint8) public genesisPresaleAddresses;
    mapping (address => uint8) public toshimetaPresaleAddresses;

    constructor() ERC1155("https://gateway.pinata.cloud/ipfs/QmNTqVmCTco9GeZxTwohnPxUJ2NdhaNWvkMZssbSHdxuqr/{id}.json") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mintGenesisPass(bytes32[] calldata _merkleproof, uint256 _mintAmount) public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(totalSupply(GenesisPass) + _mintAmount <= genesisSupply, "reached max supply");
        require(_mintAmount <= genesisMintAmount, "max mint amount per session exceeded");
        require(msg.value >= genesisPassCost * _mintAmount, "insufficient funds");
        if (!publicSaleActive) {
            require(privateSaleActive, "the private sale is not active");
            uint256 ownerMintedCount = genesisAddressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= genesisMintPerAddr, "max NFT per address exceeded");
            require(verifyGenesisWhitelist(_merkleproof,msg.sender), "user is not on genesis pass whitelist");
            _mint(msg.sender, GenesisPass, _mintAmount, "");
        } else {
            require(publicSaleActive, "the public sale is not active");
            _mint(msg.sender, GenesisPass, _mintAmount, "");   
        }
        genesisAddressMintedBalance[msg.sender] = genesisAddressMintedBalance[msg.sender] + _mintAmount;
    }

    function mintToshimetaPass(bytes32[] calldata _merkleproof, uint256 _mintAmount) public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(totalSupply(ToshimetaPass) + _mintAmount <= toshimetaSupply, "reached max supply");
        require(_mintAmount <= toshimetaMintAmount, "max mint amount per session exceeded");
        require(msg.value >= toshimetaPassCost * _mintAmount, "insufficient funds");
        if (!publicSaleActive) {
            require(privateSaleActive, "the private sale is not active");
            uint256 ownerMintedCount = toshimetaAddressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= toshimetaMintPerAddr, "max NFT per address exceeded");
            require(verifyToshimetaWhitelist(_merkleproof,msg.sender), "user is not on toshimeta pass whitelist");
            _mint(msg.sender, ToshimetaPass, _mintAmount, "");
        } else {
            require(publicSaleActive, "the public sale is not active");
            _mint(msg.sender, ToshimetaPass, _mintAmount, "");
        }
        toshimetaAddressMintedBalance[msg.sender] = toshimetaAddressMintedBalance[msg.sender] + _mintAmount;
    }

    function ownerMintToshimetaPass(uint256 _mintAmount) external onlyOwner{
        require(!paused, "the contract is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(totalSupply(ToshimetaPass) + _mintAmount <= toshimetaSupply, "reached max supply");
        _mint(msg.sender, ToshimetaPass, _mintAmount, "");
    }

    function ownerMintGenesisPass(uint256 _mintAmount) external onlyOwner{
        require(!paused, "the contract is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(totalSupply(GenesisPass) + _mintAmount <= genesisSupply, "reached max supply");
        _mint(msg.sender, GenesisPass, _mintAmount, "");
    }

    function verifyGenesisWhitelist(bytes32[] calldata _merkleproof, address _address) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleproof,genesisMerkleRoot,leaf);
    }

    function verifyToshimetaWhitelist(bytes32[] calldata _merkleproof, address _address) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleproof,toshimetaMerkleRoot,leaf);
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPublicSaleState(bool _state) public onlyOwner {
        publicSaleActive = _state;
    }

    function setPrivateSaleState(bool _state) public onlyOwner {
        privateSaleActive = _state;
    }

    function setGenesisMerkleRootHash(bytes32 _rootHash) public onlyOwner {
        genesisMerkleRoot = _rootHash;
    }

    function setToshimetaMerkleRootHash(bytes32 _rootHash) public onlyOwner {
        toshimetaMerkleRoot = _rootHash;
    }

    function setURI(string memory newuri) external onlyOwner{
        _setURI(newuri);
    }

    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    function getName() public view returns (string memory) {
       return name;
    }


    address addr1 = 0xdC7dBFd6ab4BF3215b01806ae9edDC7447016793;
    address addr2 = 0xB9aC442e606809459d7E80C75c5eaBE5eaC3b88b;
    address addr3 = 0x0cAd323FB84Eb9D7BA2e42Cb4Afaf09157D72A16;
    address addr4 = 0x6352E129FdD4acCd2B1DE6B7bb13142800Ad6CE1;
    address addr5 = 0xB9b2dF03F48d86F9d02c00FB56DaDb42962d784D;
    
    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "contract balance is 0");
        payable(addr1).transfer((balance * 190) / 1000);
        payable(addr2).transfer((balance * 190) / 1000);
        payable(addr3).transfer((balance * 190) / 1000);
        payable(addr4).transfer((balance * 190) / 1000);
        payable(addr5).transfer((balance * 190) / 1000);
        payable(msg.sender).transfer((balance * 50) / 1000);
    }
}