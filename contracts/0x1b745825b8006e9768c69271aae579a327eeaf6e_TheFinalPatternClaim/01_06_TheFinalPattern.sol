// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";


contract TheFinalPatternClaim is Ownable, ReentrancyGuard  {

    mapping (address => uint256) claimedAmount;
    bool claimIsOpen;
    uint256 maxClaims = 1216;
    uint256 price = 0.025 ether;
    uint256 claimedTotal;

    bytes32 public root = 0x18e48ce065b309ce7f8cb41788a8f6e7cef573141b6a0f559fc5ed212eafbab5;

    function editRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function editMaxClaims(uint256 _maxClaims) external onlyOwner {
        maxClaims = _maxClaims;
    }

    function editPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function editClaimState(bool _open) external onlyOwner {
        claimIsOpen = _open;
    }

    function getClaimedPiecesForAddress(address _claimer) public view returns (uint256) {
        return claimedAmount[_claimer];
    }

    function getTotalClaimed() public view returns (uint256) {
        return claimedTotal;
    }

    function claimPieces(string memory _btcAddress, uint256 _qtyReserved, uint256 _qtyClaimed, bytes32[] calldata _p) external payable nonReentrant {
        require(claimedTotal + _qtyClaimed <= maxClaims, "Max claim supply reached.");
        if (msg.sender != owner()) {
            require(claimIsOpen, "Claim must be open.");
            require(msg.value == _qtyClaimed * price);
        }
        bool validProof = MerkleProof.verify(_p, root, keccak256(abi.encodePacked(msg.sender, _qtyReserved)));
        require(validProof, "Must pass the correct proof");
        require(claimedAmount[msg.sender] + _qtyClaimed <= _qtyReserved, "Too many claims for wallet.");
        claimedAmount[msg.sender] += _qtyClaimed;
        claimedTotal += _qtyClaimed;
    }
 
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }                                                 


}