// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";   
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";   
contract NFT is  ERC721A,Ownable   {
     
    string private _baseTokenURI = "https://api.spaceart-nft.io/api/v0/nft/find_metadata_ethereum/";
    constructor () ERC721A ("SPACE ART", "SPA") {
     
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    } 
    function createToken() public  { 
        _mint(msg.sender, 1);
       
    }
    function getTokenId() public view returns (uint256){
        return _nextTokenId();
    }
     
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
         
        return tokensId;
    }
    function tokenOfOwnerByIndex(address ownerAddress, uint256 index) public view  returns (uint256) {
        require(index < balanceOf(ownerAddress), "ERC721A: owner index out of bounds");
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < numMintedSoFar; i++) {
            TokenOwnership memory ownership = _ownershipAt(i);
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == ownerAddress) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("ERC721A: unable to get token of owner by index");
    }
    function burn(uint256 tokenId) public {
        _burn(tokenId,true);
    }
 
}