// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721, ERC721A} from "../ERC721.sol";

error CallerNotOwner(string method);
error FeatureIsDisabled();
error FeeExceedsAccountBalance(string method);

abstract contract ERC721Membership is ERC721 {

    event Charged(uint256 indexed tokenId, uint64 amount, address indexed sender);
    event Deposited(uint256 indexed tokenId, uint64 amount, address indexed sender);
    event Fused(uint256 indexed a, uint256 indexed b, uint64 previous, uint64 updated);
    event Upgraded(uint256 indexed tokenId, uint64 previous, uint64 updated, uint64 fee);


    struct Account {
        uint64 balance;
        uint64 fees;
        uint64 level;
        uint64 updatedAt;
    }

    struct Membership {
        // If true NFT can be fused with another within the collection
        bool fusible;
        // Rewards earned per week
        uint64 rewardsPerWeek;
        // Fee charged to upgrade the level of NFT
        // - Grant access to better perks in the system
        uint64 upgradeFee;
    }

    struct Multipliers {
        // Level multiplier ( in Basis Points )
        uint64 level;
        // Max multiplier ( in Basis Points )
        uint64 max;
        // Multiplier per month owned ( in Basis Points )
        uint64 month;
    }


    mapping(uint256 => Account) public _accounts;

    Membership public _membership;

    Multipliers public _multipliers;


    uint64 public immutable _deployedAt = uint64(block.timestamp);

    uint64 public immutable _maxReward;

    uint128 public _totalFees;


    constructor(uint64 maxReward) {
        _maxReward = maxReward;
    }


    // Returns the (current balance, bips multiplier) of the account with all relavant multipliers applied
    function _calculate(uint256 tokenId) internal view returns (uint64, uint64) {
        Account memory account = _accounts[tokenId];
        Multipliers memory multiplier = _multipliers;
        TokenOwnership memory token = _ownershipOf(tokenId);

        unchecked {
            uint64 bips = 10000;
            uint64 timestamp = uint64(block.timestamp);
            uint64 updatedAt = account.updatedAt;

            if (updatedAt == 0) {
                updatedAt = _deployedAt;
            }

            // Apply bonus based on level ( Level 1 * 1000 = 10% bonus )
            bips += account.level * multiplier.level;

            // Apply additional bonus based on ownership duration ( in months )
            bips += multiplier.month * ((timestamp - token.startTimestamp) / uint64(4 weeks));

            if (bips > multiplier.max) {
                bips = multiplier.max;
            }

            account.balance += (_membership.rewardsPerWeek * ((timestamp - updatedAt) / uint64(1 weeks))) * bips / 10000;

            if (_maxReward > 0) {
                uint64 maxReward = _maxReward;

                if (maxReward > account.fees) {
                    maxReward -= account.fees;
                }
                else {
                    maxReward = 0;
                }

                if (account.balance > maxReward) {
                    account.balance = maxReward;
                }
            }

            return (account.balance, bips);
        }
    }

    function fuse(uint256 a, uint256 b) external virtual {
        if (!_membership.fusible) {
            revert FeatureIsDisabled();
        }

        address sender = _msgSender();

        if (ownerOf(a) != sender || ownerOf(b) != sender) {
            revert CallerNotOwner({ method: 'fuse' });
        }

        Account storage A = _accounts[a];
        uint64 previous = A.level;

        // Balances shouldn't merge during fusion. Fused boxes would become too OP.
        // - Primary purpose of fusing should be to achieve max multiplier faster.
        // - You must sacrifice the rewards in token b for the multiplier.
        unchecked {
            A.level += _accounts[b].level + 1;
        }

        _burn(b, false);

        delete _accounts[b];
        emit Fused(a, b, previous, A.level);
    }

    function multiplierOf(uint256 tokenId) public view returns (uint64) {
        (,uint64 bips) = _calculate(tokenId);

        return bips;
    }

    function multipliersOf(uint256[] memory tokenIds) external view returns (uint64[] memory) {
        uint256 n = tokenIds.length;
        uint64[] memory bonus = new uint64[](n);

        for (uint256 i = 0; i < n; i++) {
            bonus[i] = multiplierOf(tokenIds[i]);
        }

        return bonus;
    }

    function rewardOf(uint256 tokenId) public view returns (uint64) {
        (uint64 balance,) = _calculate(tokenId);

        return balance;
    }

    function rewardsOf(uint256[] memory tokenIds) external view returns (uint64[] memory) {
        uint256 n = tokenIds.length;
        uint64[] memory rewards = new uint64[](n);

        for (uint256 i = 0; i < n; i++) {
            rewards[i] = rewardOf(tokenIds[i]);
        }

        return rewards;
    }

    function setMembership(Membership memory membership) onlyOwner public {
        _membership = membership;
    }

    function setMultipliers(Multipliers memory multipliers) onlyOwner public {
        _multipliers = multipliers;
    }

    function upgrade(uint256 tokenId) external virtual {
        uint64 fee = _membership.upgradeFee;

        if (fee == 0) {
            revert FeatureIsDisabled();
        }

        if (ownerOf(tokenId) != _msgSender()) {
            revert CallerNotOwner({ method: 'upgrade' });
        }

        Account storage account = _accounts[tokenId];
        uint64 previous = account.level;
        uint64 reward = rewardOf(tokenId);

        if (reward < fee) {
            revert FeeExceedsAccountBalance({ method: 'upgrade' });
        }

        account.balance = reward - fee;
        account.fees += fee;
        account.level += 1;
        account.updatedAt = uint64(block.timestamp);

        _totalFees += fee;

        emit Upgraded(tokenId, previous, account.level, fee);
    }
}