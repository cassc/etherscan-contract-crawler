//
//
//
/////////////////////////////////////////////////////////////////
//                                                             //
//       ██████  ███████ ███    ██ ███    ██ ██ ███████        //
//       ██   ██ ██      ████   ██ ████   ██ ██ ██             //
//       ██   ██ █████   ██ ██  ██ ██ ██  ██ ██ ███████        //
//       ██   ██ ██      ██  ██ ██ ██  ██ ██ ██      ██        //
//       ██████  ███████ ██   ████ ██   ████ ██ ███████        //
//                                                             //
// ███████  ██████ ██   ██ ███    ███ ███████ ██      ███████  //
// ██      ██      ██   ██ ████  ████ ██      ██         ███   //
// ███████ ██      ███████ ██ ████ ██ █████   ██        ███    //
//      ██ ██      ██   ██ ██  ██  ██ ██      ██       ███     //
// ███████  ██████ ██   ██ ██      ██ ███████ ███████ ███████  //
//                                                             //
/////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract EditionsByDennisSchmelzMinter is Ownable {
    address public editionsByDennisSchmelz = 0x3820e79dEb5E60F6f488fA2A62C8e190CC69BB47;

    uint256 public mintTokenId = 3;

    uint256 public mintTokenPriceHolders = 10000000 gwei;
    uint256 public mintTokenPrice = 19000000 gwei;

    bytes32 public root = 0x232450d8a4fb5d9e42138c429c6be5b0a6154662cb284556acb6c8b6f26c9545;

    mapping(address => uint256) public claimedNFTs;

    constructor() {}

    function mint(uint256 amount, uint256 maxAmount, bytes32[] calldata proof) public payable{
        require(maxAmount >= 1, "Amount must be >= 1");
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender, maxAmount))), "Invalid merkle proof");
        require(claimedNFTs[msg.sender] + amount <= maxAmount, "Wallet already claimed");
        require(msg.value >= mintTokenPriceHolders * amount, "Not enough eth");

        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(editionsByDennisSchmelz);
        token.mint(msg.sender, mintTokenId, amount, "");
        
        claimedNFTs[msg.sender] += amount;
    }

    function mint(uint256 amount) public payable {
        require(amount >= 1, "Amount must be >= 1");
        require(msg.value >= mintTokenPrice * amount, "Not enough eth");
        
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(editionsByDennisSchmelz);
        token.mint(msg.sender, mintTokenId, amount, "");
    }


    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setEditionsByDennisSchmelzAddress(address newAddress) public onlyOwner {
        editionsByDennisSchmelz = newAddress;
    }

    function setMintTokenId(uint256 tokenId) public onlyOwner {
        mintTokenId = tokenId;
    }

    function setMintTokenPrice(uint256 tokenPrice) public onlyOwner {
        mintTokenPrice = tokenPrice;
    }

    function setMintTokenPriceHolders(uint256 tokenPrice) public onlyOwner {
        mintTokenPriceHolders = tokenPrice;
    }

    function setRoot(bytes32 newroot) public onlyOwner {root = newroot;}
}