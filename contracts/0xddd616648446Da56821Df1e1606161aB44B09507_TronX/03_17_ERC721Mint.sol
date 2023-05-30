// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


abstract contract ERC721Mint is ERC721, Ownable, ReentrancyGuard {

    uint32 public MAX_SUPPLY;
    uint32 public RESERVE;
    uint8 public START_AT = 1;

    uint32 public mintTracked;
    uint32 public burnedTracker;

    string public baseTokenURI;

    //******************************************************//
    //                      Modifier                        //
    //******************************************************//
    modifier notSoldOut(uint256 _count) {
        require(mintTracked + uint32(_count) <= MAX_SUPPLY, "Sold out!");
        _;
    }

    //******************************************************//
    //                      Setters                         //
    //******************************************************//
    function setMaxSupply(uint32 _maxSupply) internal {
        MAX_SUPPLY = _maxSupply;
    }
    function setReserve(uint32 _reserve) internal {
        RESERVE = _reserve;
    }
    function setStartAt(uint8 _start) internal {
        START_AT = _start;
    }
    function setBaseUri(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    //******************************************************//
    //                      Getters                         //
    //******************************************************//
    function walletOfOwner(address _owner) external view virtual returns (uint32[] memory) {
        uint256 count = balanceOf(_owner);
        uint256 key = 0;
        uint32[] memory tokensIds = new uint32[](count);

        for (uint32 tokenId = START_AT; tokenId < mintTracked + START_AT; tokenId++) {
            if (_owners[tokenId] != _owner) continue;
            if (key == count) break;

            tokensIds[key] = tokenId;
            key++;
        }
        return tokensIds;
    }
    function getBaseTokenURI() internal view returns(string memory){
        return baseTokenURI;
    }
    function totalSupply() public view returns (uint32) {
        return mintTracked - burnedTracker;
    }

    //******************************************************//
    //                      Mint                            //
    //******************************************************//
    function _mintToken(address wallet) internal returns(uint256){
        uint256 tokenId = uint256(mintTracked + START_AT);
        mintTracked += 1;
        _safeMint(wallet, tokenId);
        return tokenId;
    }
    function _mintTokens(address wallet, uint32 _count) internal{
        for (uint32 i = 0; i < _count; i++) {
            _mintToken(wallet);
        }
    }

    function reserve(uint32 _count) public virtual onlyOwner {
        require(mintTracked + _count <= RESERVE, "Exceeded RESERVE_NFT");
        require(mintTracked + _count <= MAX_SUPPLY, "Sold out!");
        for(uint32 i = 0; i < _count; i++){
            _mintToken(_msgSender());
        }
    }

    //******************************************************//
    //                      Burn                            //
    //******************************************************//
    function burn(uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not owner nor approved");
        burnedTracker += 1;
        _burn(_tokenId);
    }
}