// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './Ownable.sol';
import "./IRedCat.sol";

contract RedCatRarity is Ownable {

    // constants
    IRedCat RedCatContract = IRedCat(0x4eac4292cA228708fFA69a3f320A81a01580aCF3);

    // attributes
    mapping (uint => uint) redCatRarity;

    // modifier
    modifier onlyHolder(uint tokenId) {
        require(msg.sender == RedCatContract.ownerOf(tokenId) , "not yours");
        _;
    }

    // event
    event Unboxing(uint indexed tokenId, uint indexed rarity);
    event FixRarity(uint indexed tokenId, uint indexed rarity);

    // unboxing
    function unboxing(uint _tokenId, uint _rarity) external onlyHolder(_tokenId) {
        ( , bool unboxed) = RedCatContract.getUnboxing(_tokenId);
        require(!unboxed, "already unboxed");
        require(_rarity < 5, "invalid rarity");

        RedCatContract.unboxing(_tokenId, _rarity);
        redCatRarity[_tokenId] = _rarity;
        emit Unboxing(_tokenId, _rarity);
    }

    // only owner
    function fixRarity(uint _tokenId, uint _rarity) external onlyOwner {
        redCatRarity[_tokenId] = _rarity;
        emit FixRarity(_tokenId, _rarity);
    }

    function migration(uint _start, uint _end) public onlyOwner {
        for(uint i = _start; i <= _end; i++) {
            (uint tokenId, uint rarity) = RedCatContract.getRarity(i);
            redCatRarity[tokenId] = rarity;
        }
    }

    // getter
    function getRarity(uint _tokenId) external view returns (uint rarity) {
        require(_tokenId < RedCatContract.totalSupply(), "over totalSupply");
        rarity = redCatRarity[_tokenId];
    }
}