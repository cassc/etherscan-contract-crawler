// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Admin} from "../../../utilities/Admin.sol";
import {CallerNotOwnerNorApproved, ERC721} from "../ERC721.sol";

error AmountExceedsAccountBalance(string method);
error FeatureIsDisabled();
error ZeroRewards();

abstract contract ERC721OwnershipBasedStaking is Admin, ERC721, ReentrancyGuard {

    event Charged(uint256 indexed tokenId, uint64 amount, address indexed sender);
    event Deposited(uint256 indexed tokenId, uint64 amount, address indexed sender);
    event LevelUpdated(uint256 indexed tokenId, uint64 current, uint64 previous);


    struct Account {
        uint64 balance;
        uint64 claimedAt;
        uint64 level;
    }

    struct Config {
        // If true NFT can be fused with another within the collection
        bool fusible;
        // Fee charged ( in staking rewards ) when creating a token swap for staking rewards
        uint64 listingFee;
        // Reset staking rewards on transfer if true, otherwise false
        bool resetOnTransfer;
        // Staking rewards earned per week
        uint64 rewardsPerWeek;
        // Fee charged to upgrade the level of NFT
        // - Grants access to better perks in the system
        uint64 upgradeFee;
    }

    struct Multipliers {
        // Level staking multiplier ( in Basis Points )
        uint64 level;
        // Max staking multiplier ( in Basis Points )
        uint64 max;
        // Original minter multiplier ( in Basis Points )
        uint64 minter;
        // Multiplier per month owned ( in Basis Points )
        uint64 month;
    }


    mapping(uint256 => Account) private _accounts;

    Config private _config;

    Multipliers private _multipliers;



    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) ReentrancyGuard() { }


    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override(ERC721) virtual {
        super._afterTokenTransfers(from, to, startTokenId, quantity);

        if (!_config.resetOnTransfer) {
            return;
        }

        for (uint256 i = 0; i < quantity; i++) {
            _accounts[startTokenId + i].balance = 0;
        }
    }

    function _charge(uint256 tokenId, uint64 amount, string memory method) private returns (uint256) {
        unchecked {
            Account storage account = _accounts[tokenId];

            if (account.balance < amount) {
                revert AmountExceedsAccountBalance({ method: method });
            }

            account.balance -= amount;

            return uint256(account.balance);
        }
    }

    function calculateStakingRewards(uint256 tokenId) public view returns (uint256) {
        Account memory account = _accounts[tokenId];
        Multipliers memory m = _multipliers;
        Token memory token = _token(tokenId);

        unchecked {
            uint64 claimedAt = account.claimedAt;
            uint64 timestamp = uint64(block.timestamp);

            if (claimedAt < token.updatedAt) {
                claimedAt = token.updatedAt;
            }

            if (timestamp < claimedAt) {
                return 0;
            }

            // Convert level to bonus in Basis Points ( Level 1 * 1000 = 10% bonus )
            uint64 multiplier = 10000 + (account.level * m.level);
            uint64 points = _config.rewardsPerWeek * ((timestamp - claimedAt) / uint64(1 weeks));

            // Apply original minter/owner multiplier
            if (token.state == ERC721.STATE_MINTED) {
                multiplier += m.minter;
            }

            multiplier += m.month * ((timestamp - token.updatedAt) / uint64(4 weeks));

            if (multiplier > m.max) {
                multiplier = m.max;
            }

            return uint256(points + (points * multiplier / 10000));
        }
    }

    function charge(uint256 tokenId, uint64 amount) external nonReentrant returns (uint256) {
        address sender = _msgSender();

        if (!_isAdmin(sender)) {
            revert CallerNotOwnerNorApproved({ method: 'charge' });
        }

        emit Charged(tokenId, amount, sender);

        return _charge(tokenId, amount, 'charge');
    }

    function claimStakingRewards(uint256 tokenId) external nonReentrant returns (uint256) {
        address sender = _msgSender();

        if (!_isApprovedOrOwner(tokenId, sender)) {
            revert CallerNotOwnerNorApproved({ method: 'claimStakingRewards' });
        }

        unchecked {
            uint256 rewards = calculateStakingRewards(tokenId);

            if (rewards == 0) {
                revert ZeroRewards();
            }

            Account storage account = _accounts[tokenId];

            account.balance += uint64(rewards);
            account.claimedAt = uint64(block.timestamp);

            return uint256(account.balance);
        }
    }

    function config() external view returns (bool, uint64, bool, uint64, uint64) {
        return (
            _config.fusible,
            _config.listingFee,
            _config.resetOnTransfer,
            _config.rewardsPerWeek,
            _config.upgradeFee
        );
    }

    function deposit(uint256 tokenId, uint64 amount) private returns (uint64) {
        address sender = _msgSender();

        if (!_isAdmin(sender)) {
            revert CallerNotOwnerNorApproved({ method: 'deposit' });
        }

        emit Deposited(tokenId, amount, sender);

        unchecked {
            Account storage account = _accounts[tokenId];

            account.balance += amount;

            return account.balance;
        }
    }

    function fuse(uint256 a, uint256 b) external nonReentrant virtual {
        if (!_config.fusible) {
            revert FeatureIsDisabled();
        }

        address sender = _msgSender();

        if (!_isAdmin(sender) && (ownerOf(a) != sender || ownerOf(b) != sender)) {
            revert CallerNotOwnerNorApproved({ method: 'fuse' });
        }

        Account storage A = _accounts[a];

        // Balances shouldn't be merged during fusing. Fused passes would become
        // too OP. They would have the ability to stake -> fuse -> continously
        // sweep the vault.
        // - Primary purpose of fusing should be to achieve max multiplier
        //   and access items available to rarer passes.
        // - In order to gain the above perks you will have to sacrifice the
        //   staking rewards in pass b.
        unchecked {
            uint64 previous = A.level;

            A.level += _accounts[b].level + 1;

            emit LevelUpdated(a, A.level, previous);
        }

        _burn(b, false);

        delete _accounts[b];
    }

    function multipliers() external view returns (uint64, uint64, uint64, uint64) {
        return (
            _multipliers.level,
            _multipliers.max,
            _multipliers.minter,
            _multipliers.month
        );
    }

    function rewardsOf(uint256 tokenId) external view returns (uint64) {
        return _accounts[tokenId].balance;
    }

    function rewardsOf(uint256[] memory tokenIds) external view returns (uint64[] memory) {
        uint64[] memory balances;
        uint256 n = tokenIds.length;

        for (uint256 i = 0; i < n; i++) {
            balances[i] = _accounts[tokenIds[i]].balance;
        }

        return balances;
    }

    function setConfig(Config memory data) onlyOwner public {
        _config = data;
    }

    function setMultipliers(Multipliers memory data) onlyOwner public {
        _multipliers = data;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function upgrade(uint256 tokenId) external nonReentrant virtual {
        uint64 fee = _config.upgradeFee;

        if (fee == 0) {
            revert FeatureIsDisabled();
        }

        address sender = _msgSender();

        if (ownerOf(tokenId) != sender) {
            revert CallerNotOwnerNorApproved({ method: 'upgrade' });
        }

        _charge(tokenId, fee, 'upgrade');

        unchecked {
            Account storage account = _accounts[tokenId];
            uint64 previous = account.level;

            account.level += 1;

            emit LevelUpdated(tokenId, account.level, previous);
        }
    }
}