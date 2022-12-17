// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./MetaShooterNFT.sol";


contract MetaShooterNFTMinter is Ownable {
    address[] public minters;
    MetaShooterNFT public nftAddress;

    constructor(MetaShooterNFT _nftAddress) {
        nftAddress = _nftAddress;
    }

    function mintNFT(address recipient, uint32 itemId) public returns (uint256){
        require(isMinter(msg.sender), "MetaShooterNFTMinter: not recognised minter");

        return MetaShooterNFT(nftAddress).mintBoxNFT(recipient, itemId);
    }

    function addMinter(address minterAddress) public onlyOwner {
        minters.push(minterAddress);
    }

    function removeMinter(uint index) public onlyOwner {
        minters[index] = minters[minters.length - 1];
        minters.pop();
    }

    function isMinter(address _address) public view returns (bool) {
        for (uint i = 0; i < minters.length; i++) {
            if (minters[i] == _address) {
                return true;
            }
        }

        return false;
    }
}