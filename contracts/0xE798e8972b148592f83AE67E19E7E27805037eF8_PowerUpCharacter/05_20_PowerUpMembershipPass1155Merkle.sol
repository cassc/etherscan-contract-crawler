// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Random.sol";

contract PowerUpMembershipPass1155Merkle is ERC1155, Random, Ownable {   
    uint public constant BLACK = 0;
    uint public constant PLATINUM = 1;
    uint public constant GOLD = 2;
    uint public tokensClaimed = 0;

    string public name = "PowerUp Membership Passes";

    bytes32 public merkleRoot;
    bool public isPresale = true;
    bool public isSaleActive = true;

    mapping(uint256 => uint256) private claimedBitMap;

    constructor(        
        uint blackAmount,
        uint platinumAmount,          
        uint goldAmount,
        string memory metadataUri,
        bytes32 merkleRoot_
    ) ERC1155(metadataUri) 
      Random(321262) {                               
        _mint(address(this), BLACK, blackAmount, "");
        _mint(address(this), PLATINUM, platinumAmount, "");
        _mint(address(this), GOLD, goldAmount, "");        
        merkleRoot = merkleRoot_;
    }

    function claim() external {
        require(!isPresale, "Public sale not open.");
        _claim();
    }

    function claimPresale(uint index, bytes32[] calldata merkleProof) external {
        require(!isClaimed(index), "Index already claimed.");
        
        uint num = 1;
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, num));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Not in allow list.");        
        _claim();
        _setClaimed(index);
    }

    function _claim() internal {           
        require(isSaleActive, "Sale not active.");
        
        uint blackAmount = balanceOf(address(this), BLACK);
        uint platinumAmount = balanceOf(address(this), PLATINUM);
        uint goldAmount = balanceOf(address(this), GOLD);

        require(
            blackAmount > 0 || 
            platinumAmount > 0 || 
            goldAmount > 0, 
            "No more supply left."
        );        
        
        require(!hasPass(msg.sender), "Already owns pass.");        
        
        // Find a random index
        uint idx = randMod(blackAmount + platinumAmount + goldAmount);         
        
        // Pick pass from available supply
        uint claimedToken;
        if (idx < goldAmount) {
            claimedToken = GOLD;
        } else if (idx >= goldAmount && idx < goldAmount + platinumAmount) {
            claimedToken = PLATINUM;
        } else {
            claimedToken = BLACK;
        }

        // Transfer token
        _safeTransferFrom(address(this), msg.sender, claimedToken, 1, "");
        tokensClaimed++;
    }

    function hasPass(address addr) public view returns(bool) {
        return   
            balanceOf(addr, BLACK) > 0 || 
            balanceOf(addr, PLATINUM) > 0 ||
            balanceOf(addr, GOLD) > 0;
    }

    function passType(address addr) public view returns(uint) {
        if (balanceOf(addr, GOLD) > 0) {
            return GOLD;
        } else if (balanceOf(addr, PLATINUM) > 0) {
            return PLATINUM;
        } else if (balanceOf(addr, BLACK) > 0) {
            return BLACK;
        } else {
            return 10;
        }
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function setSaleActive(bool isSaleActive_) public onlyOwner {
        isSaleActive = isSaleActive_;
    }

    function setPresale(bool isPresale_) public onlyOwner {
        isPresale = isPresale_;
    }

    function setMedataDataUri(string memory metadataUri) public onlyOwner {
        _setURI(metadataUri);
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }
    
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }    
}