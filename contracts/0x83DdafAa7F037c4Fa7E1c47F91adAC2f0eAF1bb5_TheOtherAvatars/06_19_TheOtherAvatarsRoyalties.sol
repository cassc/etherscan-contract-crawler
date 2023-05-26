// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRaribleV2.sol";

abstract contract TheOtherAvatarsRoyalties is Ownable, IRaribleV2 {
    uint256 internal constant artistBits = 8;
    uint256 internal constant artistBitsNumber = 2**artistBits - 1;
    uint256 internal constant artistsPerInt = 256 / artistBits;

    mapping(uint256 => address) internal _artistAtIndex;
    mapping(uint256 => uint256) internal _tokenArtists;

    address internal _defaultAccount;

    constructor(address defaultAccount) {
        _defaultAccount = defaultAccount;
    }

    // 1000 is 10%
    function getRaribleV2Royalties(uint256 id) override external view returns (Part[] memory) {
        uint256 index = _getTokenInfo(id);
        address payable account = payable(_artistAtIndex[index]);

        if (account == address(0)) {
            account = payable(_defaultAccount);
            index = 0;
        }
        
        if (index == 0) {
            Part[] memory result = new Part[](1);
            result[0] = Part(account, 1000);
            return result;
        } else {
            Part[] memory result = new Part[](2);
            address payable defaultAccount = payable(_defaultAccount);
            result[0] = Part(defaultAccount, 350);
            result[1] = Part(account, 650);
            return result;
        }
    }

    function pushArtists(address[] memory artists, uint256[] memory indexes) public onlyOwner {
        require(artists.length == indexes.length);
        
        for (uint i; i < artists.length; i++) {
            uint256 index = indexes[i];
            address artist = artists[i];
            require(index > 0, "First index is reserved");
            _artistAtIndex[index] = artist;
        }
    }

    function pushRoyaltyTokenInfo(uint256[] memory tokenRows, uint256[] memory indexes) public onlyOwner {
        require(tokenRows.length == indexes.length);

        for (uint i; i < tokenRows.length; i++) {
            uint256 index = indexes[i];
            uint256 tokenRow = tokenRows[i];
            _tokenArtists[index] = tokenRow;
        }
    }

    function _getTokenInfo(uint256 tokenId) private view returns (uint256) {
        uint256 rowIndex = tokenId / artistsPerInt;
        uint256 colorBitIndex = (tokenId % artistsPerInt) * artistBits;
        uint256 colorRow = _tokenArtists[rowIndex];
        return (colorRow >> colorBitIndex) & artistBitsNumber;
    }
}