// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MegacoinClaim is Ownable {
    address public megaKongsAddress;

    mapping(uint256 => string) public claimMap;

    constructor(address _megaKongsAddress) {
        megaKongsAddress = _megaKongsAddress;
    }

    function hasClaimed(uint256 _claimId) public view returns (bool) {
        return bytes(claimMap[_claimId]).length > 0;
    }

    function getClaim(uint256 _claimId) public view returns (string memory) {
        return claimMap[_claimId];
    }

    function ownsKong(uint256 id) internal view returns (bool) {
        return IERC721(megaKongsAddress).ownerOf(id) == msg.sender;
    }

    function addClaim(uint256 _claimId, string memory _claimAddress) internal {
        require(!hasClaimed(_claimId));
        require(ownsKong(_claimId));
        claimMap[_claimId] = _claimAddress;
    }

    function addClaims(uint256[] memory _claimIds, string memory _claimAddress)
        external
    {
        for (uint256 i = 0; i < _claimIds.length; i++) {
            addClaim(_claimIds[i], _claimAddress);
        }
    }
}