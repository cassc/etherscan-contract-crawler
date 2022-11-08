// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract FetchNFT {
    function getUserNFT(IERC721 nft, address owner, uint start, uint end) public view returns (uint, uint, uint256[] memory){
        uint count = nft.balanceOf(owner);
        uint[] memory ids = new uint[](count);
        uint index = 0;
        for (uint i = start; i < end; i++) {
            try  nft.ownerOf(i) returns (address addr) {
                if (addr == owner) {
                    ids[index] = i;
                    index ++;
                    if (index >= count) {
                        break;
                    }
                }
            }
            catch{

            }

        }
        return (count, index, ids);
    }
}