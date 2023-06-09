// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Airdrop is Ownable {
    address[] private _collections;
    mapping(uint256 => uint256[]) public infos;

    function updateAvailableNFT(uint256 _id, uint256[] memory _ids) public onlyOwner {
        infos[_id] = _ids;
    }

    function setCollections(address[] memory _collec) public onlyOwner {
        _collections = _collec;
    }

    function airdropNFT(address[] memory _wallets) public onlyOwner {
        address account;
        uint256 j;
        uint256 start;

        for(uint256 currentCollec = 0; currentCollec < _collections.length; currentCollec++){
            while(j < infos[currentCollec].length) {
                account = _wallets[start];
                IERC721(_collections[currentCollec]).safeTransferFrom(owner(), account, infos[currentCollec][j]);

                start++;
                j++; 
            }
            j = 0;
        }      
    }
}