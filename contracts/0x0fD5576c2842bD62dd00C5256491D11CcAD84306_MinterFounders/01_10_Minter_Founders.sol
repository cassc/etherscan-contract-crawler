// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IKonduxFounders.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IKondux.sol";
import "./types/AccessControlled.sol";

import "hardhat/console.sol";

contract MinterFounders is AccessControlled {

    uint256 public priceFounders020;
    uint256 public priceFounders025;
    uint256 public priceFreeKNFT;
    uint256 public priceFreeFounders;

    bytes32 public rootFreeFounders;
    bytes32 public rootFounders020;
    bytes32 public rootFounders025;
    bytes32 public rootFreeKNFT;

    bool public pausedWhitelist;
    bool public pausedFounders020;
    bool public pausedFounders025;
    bool public pausedFreeFounders;
    bool public pausedFreeKNFT;

    IKondux public kondux;
    IKonduxFounders public konduxFounders;
    ITreasury public treasury;

    mapping (address => bool) public founders020Claimed;
    mapping (address => bool) public founders025Claimed;
    mapping (address => bool) public freeFoundersClaimed;
    mapping (address => bool) public freeKNFTClaimed;


    constructor(address _authority, address _konduxFounders, address _kondux, address _vault) 
        AccessControlled(IAuthority(_authority)) {        
            require(_konduxFounders != address(0), "Kondux address is not set");
            konduxFounders = IKonduxFounders(_konduxFounders);
            require(_kondux != address(0), "Kondux address is not set");
            kondux = IKondux(_kondux);
            require(_vault != address(0), "Vault address is not set");
            treasury = ITreasury(_vault);

            pausedFounders020 = false;
            pausedFounders025 = false;
            pausedFreeFounders = false;
            pausedFreeKNFT = false;
    }      

    function setPriceFounders020(uint256 _price) public onlyGovernor {
        priceFounders020 = _price;
    }

    function setPriceFounders025(uint256 _price) public onlyGovernor {
        priceFounders025 = _price;
    }

    function setPriceFreeFounders(uint256 _price) public onlyGovernor {
        priceFreeKNFT = _price;
    }

    function setPriceFreeKNFT(uint256 _price) public onlyGovernor {
        priceFreeKNFT = _price;
    }

    function setPausedFounders020(bool _paused) public onlyGovernor {
        pausedFounders020 = _paused;
    }

    function setPausedFounders025(bool _paused) public onlyGovernor {
        pausedFounders025 = _paused;
    }

    function setPausedFreeFounders(bool _paused) public onlyGovernor {
        pausedFreeFounders = _paused;
    }

    function setPausedFreeKNFT(bool _paused) public onlyGovernor {
        pausedFreeKNFT = _paused;
    }

    function whitelistMintFounders020(bytes32[] calldata _merkleProof) public payable isFounders020Active returns (uint256) {
        require(msg.value >= priceFounders020, "Not enought ether");
        require(!founders020Claimed[msg.sender], "Already claimed");
        treasury.depositEther{ value: msg.value }();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));        
        require(MerkleProof.verify(_merkleProof, rootFounders020, leaf), "Incorrect proof");
        founders020Claimed[msg.sender] = true;
        return _mintFounders();
    }

    function whitelistMintFounders025(bytes32[] calldata _merkleProof) public payable isFounders025Active returns (uint256) {
        require(msg.value >= priceFounders025, "Not enought ether");
        require(!founders025Claimed[msg.sender], "Already claimed");
        treasury.depositEther{ value: msg.value }();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, rootFounders025, leaf), "Incorrect proof");
        founders025Claimed[msg.sender] = true;
        return _mintFounders();
    }

    function whitelistMintFreeKNFT(bytes32[] calldata _merkleProof) public isFreeKNFTActive returns (uint256) {
        require(!freeKNFTClaimed[msg.sender], "Already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, rootFreeKNFT, leaf), "Incorrect proof");
        freeKNFTClaimed[msg.sender] = true;
        return _mintKNFT();
    }

    function whitelistMintFreeFounders(bytes32[] calldata _merkleProof) public isFreeFoundersActive returns (uint256) {
        require(!freeFoundersClaimed[msg.sender], "Already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, rootFreeFounders, leaf), "Incorrect proof");
        freeFoundersClaimed[msg.sender] = true;
        return _mintFounders();
    }

    function setRootFreeFounders(bytes32 _rootFreeFounders) public onlyGovernor {
        rootFreeFounders = _rootFreeFounders;
    }

    function setRootFounders020(bytes32 _rootFounders020) public onlyGovernor {
        console.logBytes32(_rootFounders020);
        rootFounders020 = _rootFounders020;
    }

    function setRootFounders025(bytes32 _rootFounders025) public onlyGovernor {
        rootFounders025 = _rootFounders025;
    }

    function setRootFreeKNFT(bytes32 _rootFreeKNFT) public onlyGovernor {
        rootFreeKNFT = _rootFreeKNFT;
    }

    function setTreasury(address _treasury) public onlyGovernor {
        treasury = ITreasury(_treasury);
    }

    function setKonduxFounders(address _konduxFounders) public onlyGovernor {
        konduxFounders = IKonduxFounders(_konduxFounders);
    }

    // TODO: REMOVE BEFORE DEPLOY TO MAINNET
    // function unclaimAddress(address _address) public {
    //     founders020Claimed[_address] = false;
    //     founders025Claimed[_address] = false;
    //     freeFoundersClaimed[_address] = false;
    //     freeKNFTClaimed[_address] = false;
    // }

    


    // ** INTERNAL FUNCTIONS **

    function _mintFounders() internal returns (uint256) {
        uint256 id = konduxFounders.safeMint(msg.sender);
        return id;
    }

    function _mintKNFT() internal returns (uint256) {
        uint256 id = kondux.safeMint(msg.sender, 0);
        return id;
    }

    // ** MODIFIERS **


    modifier isFounders020Active() {
        require(!pausedFounders020, "Founders 020 minting is paused");
        _;
    }

    modifier isFounders025Active() {
        require(!pausedFounders025, "Founders 025 minting is paused");
        _;
    }

    modifier isFreeFoundersActive() {
        require(!pausedFreeFounders, "Free Founders minting is paused");
        _;
    }

    modifier isFreeKNFTActive() {
        require(!pausedFreeKNFT, "Free KNFT minting is paused");
        _;
    }

}