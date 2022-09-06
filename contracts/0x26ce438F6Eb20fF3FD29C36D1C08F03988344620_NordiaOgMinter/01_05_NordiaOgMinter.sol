// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Interface to interact our NFF contract
interface INFF{
    function mint(address _address, uint256 _mintAmount) external;
}

contract NordiaOgMinter is Ownable, ReentrancyGuard{
    address public NFFAddress = 0xc672C2f18a1537048E892492a9CC323f7B1A2b30;
    INFF NFF = INFF(NFFAddress);

    uint256 public maxSupply = 1000;
    uint256 public totalSupply = 0;
    uint256 public maxMintAmount = 2;
    uint256 public cost = 0.075 ether;

    bool public paused = true;
    bytes32 public ogRoot;

    mapping (address => uint256) public ogMintedAmount;

    // Modifiers
    modifier isPaused(){
        require(paused == false, "Contract is paused");
        _;
    }
    //

    constructor() {}

    function ogMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable isPaused nonReentrant {
        // Supply Control
        require(_mintAmount + totalSupply <= maxSupply, "Max NFT limit exceeded for oglisted users");

        // Oglist Control
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, ogRoot, leaf), "User is not oglisted");

        // Cost and Mint Amount Controls
        require(msg.value >= cost * _mintAmount, "Insufficent funds");
        require(ogMintedAmount[msg.sender] + _mintAmount <= maxMintAmount, "Max NFT limit exceeded for this user");

        // Increment Total Supply and Minted Amount Before Mint Process
        totalSupply += _mintAmount;
        ogMintedAmount[msg.sender] += _mintAmount;

        // Finally!
        NFF.mint(msg.sender, _mintAmount);
    }

    // == Only Owner ==
    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setOgRoot(bytes32 _ogRoot) public onlyOwner {
        ogRoot = _ogRoot;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}