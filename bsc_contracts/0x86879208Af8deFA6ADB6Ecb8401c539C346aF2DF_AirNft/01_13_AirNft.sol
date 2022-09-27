// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AirNft is ERC721URIStorage,Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    //总发布剩余量
    uint256 public supplyLimit = 0;
    constructor() ERC721("AirNft", "ANFT") {}
    //设置总量
    function limitTotalSupply(uint256 _supplyLimit) public onlyOwner {
            if (supplyLimit <= 0) {
                supplyLimit = _supplyLimit;
            }
        }
    //铸币
    function awardItem(address player, string memory tokenURI)
        public
        onlyOwner
        returns (uint256)
    {
        require(supplyLimit > 0, "not limit total supply");
        require(_tokenIds.current() < supplyLimit, "supply limit");
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);
        _approve(owner(), newItemId);

        _tokenIds.increment();
        return newItemId;
    }
}