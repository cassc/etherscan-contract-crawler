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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TheMintMemesMinterPepe is Ownable {
    address public theMintMemesAddress = 0x3820e79dEb5E60F6f488fA2A62C8e190CC69BB47;

    uint256 public mintTokenId = 5;

    bytes32 public root = 0x232450d8a4fb5d9e42138c429c6be5b0a6154662cb284556acb6c8b6f26c9545;

    mapping(address => uint256) public claimedNFTs;

    constructor() {}

    function mint(uint256 amount, bytes32[] calldata proof) public {
        require(amount >= 1, "TheMintMemesMinterPepe: Amount must be >= 1");
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender, amount))), "Invalid merkle proof");
        require(claimedNFTs[msg.sender] < amount, "Wallet already claimed");
        
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(theMintMemesAddress);
        token.mint(msg.sender, mintTokenId, amount, "");
        
        claimedNFTs[msg.sender] = amount;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setTheMintMemesAddress(address newAddress) public onlyOwner {
        theMintMemesAddress = newAddress;
    }

    function setMintTokenId(uint256 tokenId) public onlyOwner {
        mintTokenId = tokenId;
    }

    function setRoot(bytes32 newroot) public onlyOwner {root = newroot;}

}