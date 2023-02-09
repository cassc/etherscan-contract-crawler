// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PAWDAO is ERC721A, Ownable{

    constructor(uint256 _maxBatchSize) ERC721A("2PAWDAO", "2PAWDAO", _maxBatchSize) {}
    function mint(address to, uint256 quantity) public onlyOwner {
        _safeMint(to, quantity);
    }
    function getOwnerIds(uint256 _idsCount, address _owner) public view returns (uint256[] memory ids){
        ids = new uint256[](_idsCount);
        uint256 addIndex = 0;
        for (uint256 i = 0; i < totalSupply(); i++) {
            if (addIndex == _idsCount) {
                return ids;
            }
            if (_owner == ownerOf(i)) {
                ids[addIndex] = i;
                addIndex ++;
            }
            if(addIndex == _idsCount){
                break;
            }
        }
        return ids;
    }
}