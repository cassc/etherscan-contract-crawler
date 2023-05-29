/**
 *Submitted for verification at Etherscan.io on 2023-03-29
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Migrate contract
 * @author 0xSumo
 */

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner");_; }
    function transferOwnership(address new_) external onlyOwner { address _old = owner; owner = new_; emit OwnershipTransferred(_old, new_); }
}

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function balanceOf(address owner) external view returns (uint256 balance);
    function transferFrom(address _from, address _to, uint256 tokenId_) external;
}

contract MigrateV2 is Ownable {

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public constant newSumoAddress = 0xd2b14f166Daeb1Ec73a4901745DBE2199Db6B40C;
    address public constant oldSumoAddress = 0x9CE4f6FDC1bf735329d1dDeD7EbD706C3c9452a1;

    IERC721 public ERC721;

    function depositeBatch(uint256[] memory tokenIds_) external onlyOwner {
        for(uint256 i; i < tokenIds_.length; i++) {
            require(IERC721(newSumoAddress).ownerOf(tokenIds_[i]) == msg.sender, "Not Owner");
            IERC721(newSumoAddress).transferFrom(msg.sender, address(this), tokenIds_[i]);
        }
    }

    function migrateBatch(uint256[] memory tokenIds_) external {
        for(uint256 i; i < tokenIds_.length; i++) {
            require(IERC721(oldSumoAddress).ownerOf(tokenIds_[i]) == msg.sender, "Not Owner");
            IERC721(oldSumoAddress).transferFrom(msg.sender, burnAddress, tokenIds_[i]);
            IERC721(newSumoAddress).transferFrom(address(this), msg.sender, tokenIds_[i]);
        }
    }

    function ownerWithdrawBatch(uint256[] memory tokenIds_) external onlyOwner {
        for(uint256 i; i < tokenIds_.length; i++) {
            IERC721(newSumoAddress).transferFrom(address(this), msg.sender, tokenIds_[i]);
        }
    }
}