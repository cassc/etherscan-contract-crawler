// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NotablesERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SoulAether is NotablesERC721A {

    uint16 public constant maxSupply = 6699;
    uint8 constant reserve = 250;
    
    uint256 public constant worthyCost = 0.05 ether;
    uint256 public constant cost = 0.06 ether;
    uint256 public constant publicCost = 0.07 ether;

    uint256[4] waveTimes;
    bytes32[3] merkleRoots;

    mapping(address => uint8) addressClaimed;

    modifier mintable(uint256 _cost, uint8 _mintAmount) {
        require(msg.value >= _cost * _mintAmount, "Ether value sent is below the price");
        require(totalSupply() + _mintAmount <= maxSupply, "Sold out");
        _;
    }

    modifier privateMintable(bytes32[] calldata _proof, uint8 _mintMax, uint8 _wave, uint8 _mintAmount) {
        uint8 wave = getWave();
        require(wave == _wave, "This wave is not available");
        require(addressClaimed[msg.sender] + _mintAmount <= _mintMax, "Address has exceeded max mint amount");
        require(MerkleProof.verify(_proof, merkleRoots[wave], keccak256(abi.encodePacked(msg.sender))), "Invalid proof");
        _;
    }

    constructor() ERC721A("SoulAether", "SAE") {
        waveTimes = [1669647600, 1669649400, 1669692600, 1669703400];
    }

    function worthyMint(bytes32[] calldata _proof) external payable mintable(worthyCost, 1) privateMintable(_proof, 1, 0, 1) {
        addressClaimed[msg.sender] += 1;
        _mint(msg.sender, 1);
    }

    function soulMint(bytes32[] calldata _proof) external payable mintable(cost, 1) privateMintable(_proof, 1, 1, 1) {
        addressClaimed[msg.sender] += 1;
        _mint(msg.sender, 1);
    }

    function allowlistMint(bytes32[] calldata _proof, uint8 _mintAmount) external payable mintable(cost, _mintAmount) privateMintable(_proof, 3, 2, _mintAmount) {
        addressClaimed[msg.sender] += _mintAmount;
        _mint(msg.sender, _mintAmount);
    }

    function publicMint(uint8 _mintAmount) external payable mintable(publicCost, _mintAmount) {
        require(block.timestamp >= waveTimes[3], "Public mint is not available");
        require(tx.origin == msg.sender, "Contracts are unable to mint");

        _mint(msg.sender, _mintAmount);
    }

    function airdrop(address[] calldata _addresses) external onlyOwner {    
        require(totalSupply() + _addresses.length <= maxSupply, "Sold out");    
        for(uint8 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], 1);
        }
    }

    function reserveMint(uint8 _amount) external onlyOwner {
        require(totalSupply() + _amount <= reserve, "Reserve claim sold out");
        _mint(msg.sender, _amount);
    }

    function setWaveTimes(uint256[4] calldata _waveTimes) external onlyOwner {
        waveTimes = _waveTimes;
    }

    function setMerkleRoot(uint8 _index, bytes32 _merkleRoot) external onlyOwner {
        merkleRoots[_index] = _merkleRoot;
    }

    function getWaveTime(uint8 _index) external view returns (uint256) {
        return waveTimes[_index];
    }

    function getWave() public view returns (uint8) {
        if(block.timestamp > waveTimes[3]) {
            return 3;
        } else if(block.timestamp > waveTimes[2]) {
            return 2;
        } else if(block.timestamp > waveTimes[1]) {
            return 1;
        } else if(block.timestamp > waveTimes[0]) {
            return 0;
        }
        revert("Mint has not started yet");
    }

    function getAddressClaimed(address _address) external view returns (uint8) {
        return addressClaimed[_address];
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

}