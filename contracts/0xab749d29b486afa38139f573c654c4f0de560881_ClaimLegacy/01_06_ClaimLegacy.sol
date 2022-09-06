// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import './libraries/MerkleProof.sol';
import './libraries/ReentrancyGuard.sol';
import './libraries/Ownable.sol';
import './interfaces/IERC721.sol';

contract ClaimLegacy is Ownable, ReentrancyGuard {
   
    IWallet public firstGen;
    IWallet public secondGen;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public legacyWallet;

    //prices
    uint256 public price = 0 ether; 
    uint8 public maxPerAddress = 1;

    bool public paused = true;
    uint256 private pendingID = 273;

    bytes32 public merkleRoot;
    mapping(address => uint256) public claimed;

    constructor(address _legacyWallet, bytes32 _merkleroot)
        
    {
       
        
        firstGen = IWallet(0x990ce04E035bd6f033B7341FE03639cD40EE0c02);
        secondGen = IWallet(0x810FeDb4a6927D02A6427f7441F6110d7A1096d5);
        legacyWallet = _legacyWallet;
        setMerkleRoot(_merkleroot);
        
    }

    function claim(uint256 quantity, uint256 tokenId, bytes32[] calldata proof) public payable {
        require(!paused, "Claiming is paused");
        require(
            isValid(proof, keccak256(abi.encodePacked(msg.sender))), "This address is not whitelisted"
        );

        require(claimed[msg.sender] + quantity <= maxPerAddress, "Max claim per wallet limit already reached");
        require(msg.value >= price * quantity, "Need to send more ETH.");
        
        firstGen.transferFrom(msg.sender, deadWallet, tokenId);
        secondGen.transferFrom(legacyWallet, msg.sender, pendingID);
        pendingID++;
        claimed[msg.sender]++;
        }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
    
    function withdraw() public onlyOwner nonReentrant {
        // This will payout the owner the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setFirstGen(address _firstGen) external onlyOwner {
        firstGen = IWallet(_firstGen);
    }

    function setSecondGen(address _secondGen) external onlyOwner {
        secondGen = IWallet(_secondGen);
    }

    function setMaxPerAddress(uint8 _newMax) external onlyOwner {
        maxPerAddress = _newMax;
    }

    function setNextTokenID(uint256 _nextTokenID) external onlyOwner {
        pendingID = _nextTokenID;
    }

    function setMerkleRoot(bytes32 m) public onlyOwner {
        merkleRoot = m;
    }

    function setLegacyWallet(address _legacyWallet) external onlyOwner {
        legacyWallet = _legacyWallet;
    }


}