//
//
//
///////////////////////////////////////////////////
//   __  __ _ _         _  _                     //
//  |  \/  (_) |_____  | || |__ _ __ _ ___ _ _   //
//  | |\/| | | / / -_) | __ / _` / _` / -_) '_|  //
//  |_|  |_|_|_\_\___| |_||_\__,_\__, \___|_|    //
//                               |___/           //
///////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MikeHagerBookClubMinter is Ownable {
    address public mikeHagerBookClubAddress = 0x3820e79dEb5E60F6f488fA2A62C8e190CC69BB47;

    bool public isMintEnabled = true;
    
    bytes32 public root = 0x232450d8a4fb5d9e42138c429c6be5b0a6154662cb284556acb6c8b6f26c9545;

    mapping(address => uint256) public claimedNFTs;

    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;

    constructor() {}

    function setIsMintEnabled(bool isEnabled) public onlyOwner {
        isMintEnabled = isEnabled;
    }

     function airdrop(
        address[] memory to,
        uint256[] memory id,        
        uint256[] memory amount
    ) onlyOwner public {
        require(to.length == id.length && to.length == amount.length, "Length mismatch");
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(mikeHagerBookClubAddress);
        for (uint256 i = 0; i < to.length; i++)
            token.mint(to[i], id[i], amount[i], "");
    }

    function mint(uint256 tier, bytes32[] calldata proof) public {
        require(isMintEnabled, "Mint not enabled");
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender, tier))), "Invalid merkle proof");
        require(claimedNFTs[msg.sender] < 1, "Wallet already claimed");
        
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(mikeHagerBookClubAddress);
        token.mint(msg.sender, _idTracker.current(), 1, "");
        _idTracker.increment();
        claimedNFTs[msg.sender] = 1;  
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setMikeHagerBookClubAddress(address newAddress) public onlyOwner {
        mikeHagerBookClubAddress = newAddress;
    }

    function setRoot(bytes32 newroot) public onlyOwner {root = newroot;}
}