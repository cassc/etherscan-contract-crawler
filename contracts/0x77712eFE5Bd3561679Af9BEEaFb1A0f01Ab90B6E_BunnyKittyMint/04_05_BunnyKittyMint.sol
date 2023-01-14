// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IBunnyKittyToken } from "./IBunnyKittyToken.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BunnyKittyMint is Ownable {

    uint256 public constant maxSupply = 1111;
    uint256 constant price = 0.02 ether;
    uint8 constant mintAmount = 1;
    uint8 constant reserve = 80;
    address tokenContract;
    uint256 public allowlistStartTime;
    uint256 public startTime;
    address receiver;
    bytes32 merkleRoot;
    mapping(address => bool) allowlistAddressClaimed;
    mapping(address => bool) addressClaimed;

    constructor(address _tokenContract, uint256 _startTime, address _receiver) {
      tokenContract = _tokenContract;
      allowlistStartTime = _startTime;
      startTime = _startTime + 2 hours;
      receiver = _receiver;
    }

    modifier mintable(uint8 wave, mapping(address => bool) storage claimed, address _recipient) {
      require(msg.value >= price, "Ether value sent is below the price");
      require(tx.origin == msg.sender, "Contracts are unable to mint");
      require(IBunnyKittyToken(tokenContract).totalSupply() < maxSupply, "Sold out");
      require(_getWave() == wave, "Mint phase has not started yet");
      require(!claimed[_recipient], "Address has exceeded max mint amount for this phase");
      _;
    }

    function allowlistMint(address _recipient, bytes32[] calldata _proof) external payable mintable(1, allowlistAddressClaimed, _recipient) {
      require(MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(_recipient))), "Invalid proof");
      
      allowlistAddressClaimed[_recipient] = true;
      _mint(_recipient);
    }

    function publicMint(address _recipient) external payable mintable(2, addressClaimed, _recipient) {      
      addressClaimed[_recipient] = true;
      _mint(_recipient);
    }

    function reserveMint(uint8 _amount) external onlyOwner {
      require(IBunnyKittyToken(tokenContract).totalSupply() + _amount <= reserve, "Reserve claim sold out");
      IBunnyKittyToken(tokenContract).mint(_amount, msg.sender);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
      merkleRoot = _merkleRoot;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
      allowlistStartTime = _startTime;
      startTime = _startTime + 2 hours;
    }

    function getAllowlistAddressClaimed(address _recipient) external view returns(bool) {
      return allowlistAddressClaimed[_recipient];
    }

    function getAddressClaimed(address _recipient) external view returns(bool) {
      return addressClaimed[_recipient];
    }

    function getPrice() external pure returns(uint256) {
      return price;
    }

    function _getWave() private view returns(uint8) {
      if(block.timestamp >= startTime) {
        return 2;
      } else if(block.timestamp >= allowlistStartTime) {
        return 1;
      }
      return 0;
    }

    function _mint(address _recipient) private {
      (bool success, ) = payable(receiver).call{value: msg.value}("");
      require(success, "Failed to send Ether");

      IBunnyKittyToken(tokenContract).mint(mintAmount, _recipient);
    }

}