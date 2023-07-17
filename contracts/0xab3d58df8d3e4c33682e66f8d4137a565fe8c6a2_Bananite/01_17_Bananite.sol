//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StakingERC20.sol";
import "./Rng.sol";
import "./ChainScoutMetadata.sol";

contract Bananite is StakingERC20 {
    using RngLibrary for Rng;

    mapping(address => uint256) public scoutCounts;

    constructor() ERC20("Bananite", "BANANITE") {}

    function extensionKey() public pure override returns (string memory) {
        return "token";
    }

    function calculateTokenRewardsOverTime(
        Rng memory rn,
        uint256 tokenId,
        uint256 secs
    ) public view override returns (uint256) {
        ChainScoutMetadata memory sm = chainScouts.getChainScoutMetadata(tokenId);
        BackAccessory c = sm.backaccessory;
        secs *= 1 ether;

        if (c == BackAccessory.SCOUT) {
            uint256 scoutNumerator = scoutCounts[tokenIdOwners[tokenId]] >= 5
                ? 8
                : 7;
            secs = secs * scoutNumerator / 2;
        } else if (c == BackAccessory.MERCENARY) {
            uint256 r = rn.generate(1, 10);
            if (r <= 2) {
                secs = (secs * 119) / 40;
            } else if (r >= 9) {
                secs = (secs * 21) / 5;
            } else {
                secs = (secs * 7) / 2;
            }
        } else if (c == BackAccessory.VANGUARD) {
            uint256 n = rn.generate(140, 210);
            secs = (secs * n) / 50;
        } else if (c == BackAccessory.RONIN) {
            uint256 r = rn.generate(1, 20);
            if (r == 1) {
                secs = secs * 3;
            } else {
                secs = secs * 6;
            }
        } else if (c == BackAccessory.MINER) {
            uint256 r = rn.generate(1, 10);
            if (r == 1) {
                secs = secs * 15;
            } else {
                secs = (secs * 15) / 2;
            }
        } else if (c == BackAccessory.PATHFINDER) {
            uint256 r = rn.generate(390, 975);
            secs = (secs * r) / 100;
        } else if (c == BackAccessory.ENCHANTER) {
            uint256 r = rn.generate(90, 140);
            secs = (secs * r) / 20;
        } else {
            uint256 r = rn.generate(1, 10);
            if (r == 1) {
                secs = secs * 2;
            } else {
                secs = secs * 10;
            }
        }

        return secs / 1 days;
    }

    function stake(uint256[] calldata tokenIds) public override {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
                tokenIds[i]
            );
            if (md.backaccessory == BackAccessory.SCOUT) {
                scoutCounts[chainScouts.ownerOf(tokenIds[i])]++;
            }
        }
        super.stake(tokenIds);
    }

    function unstake(uint256[] calldata tokenIds) public override {
        super.unstake(tokenIds);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(
                tokenIds[i]
            );
            if (md.backaccessory == BackAccessory.SCOUT) {
                scoutCounts[chainScouts.ownerOf(tokenIds[i])]--;
            }
        }
    }
}