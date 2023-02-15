// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {TokenInfo, MergeInfo} from "./NewDefinaCardStructs.sol";

library CommonUtils {
    function _randModulus(address user, uint mod, uint i) internal view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                mod,
                i,
                user, msg.sender)
            )) % mod;
        return rand;
    }

    function getHeroByRand(uint[] storage heroIds, address user, uint i) internal view returns (uint) {
        uint mod = heroIds.length;
        uint rand = uint(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                mod,
                i,
                user, msg.sender)
            )) % mod;

        return heroIds[rand];
    }

    function getHeroBySeed(uint[] memory heroIds, address user, bytes32 seed, bytes32 transactionHash,uint index) internal view returns (uint) {
        uint mod = heroIds.length;
        uint rand = uint(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                mod,
                user,
                seed,
                transactionHash,
                index,
                msg.sender)
            )) % mod;
        return heroIds[rand];
    }

    function getMintResult(uint256[][] memory rarityScale, address user, bytes32 seed, bytes32 transactionHash) internal view returns (uint) {
        uint mod = 100;
        uint rand = uint(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                mod,
                user,
                seed,
                transactionHash,
                msg.sender)
            )) % mod;

        uint256 prevScale = 0;
        for (uint256 i = 0; i < rarityScale.length; i++) {
            if (rand < prevScale + rarityScale[i][1]) return rarityScale[i][0];
            prevScale += rarityScale[i][1];
        }
        return 0;
    }

    function getMergeResult(uint scale, address user, bytes32 seed, bytes32 transactionHash) internal view returns (bool) {
        uint mod = 100;
        uint rand = uint(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                mod,
                user,
                seed,
                transactionHash,
                msg.sender)
            )) % mod;
        if (rand < scale) {
            return true;
        }
        return false;
    }

    function _randSeedModulus(address user, bytes32 seed, bytes32 transactionHash, uint mod) internal view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                mod,
                user,
                seed,
                transactionHash,
                msg.sender)
            )) % mod;
        return rand;
    }

    function stringToUint(string memory s) internal pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint8(b[i]) - 48);
            }
        }
        return result;
    }

    function getClaimableCards(uint256[] calldata tokenIds, mapping(uint256 => bool) storage claimed) internal view returns (uint256[] memory) {
        uint256[] memory claimableCards = new uint256[](tokenIds.length);
        uint256 n=0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            if (claimed[tokenId] == false)
            {
                claimableCards[n]=tokenId;
                n++;
            }
        }
        return claimableCards;
    }

}