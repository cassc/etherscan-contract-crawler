// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {utils} from "./utils/utils.sol";
import {ERC20UDS} from "UDS/tokens/ERC20UDS.sol";
import {ERC721UDS} from "UDS/tokens/ERC721UDS.sol";
import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {MINT_ERC20_SIG} from "fx-contracts/FxERC20RootUDS.sol";
import {ERC20RewardUDS} from "UDS/tokens/extensions/ERC20RewardUDS.sol";
import {FxERC721sRootTunnelUDS} from "fx-contracts/FxERC721sRootTunnelUDS.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_CRFTD_TOKEN = keccak256("diamond.storage.crftd.token");

function s() pure returns (CRFTDTokenDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_CRFTD_TOKEN;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct CRFTDTokenDS {
    uint256 rewardEndDate;
    mapping(address => uint256) rewardRate;
    mapping(address => mapping(uint256 => address)) ownerOf;
}

// ------------- errors

error ZeroReward();
error IncorrectOwner();
error InvalidFxChild();
error MigrationRequired();
error MigrationIncomplete();
error MigrationNotStarted();
error CollectionNotRegistered();
error CollectionAlreadyRegistered();

//       ___           ___           ___                    _____
//      /  /\         /  /\         /  /\       ___        /  /::\
//     /  /:/        /  /::\       /  /:/_     /__/\      /  /:/\:\
//    /  /:/        /  /:/\:\     /  /:/ /\    \  \:\    /  /:/  \:\
//   /  /:/  ___   /  /::\ \:\   /  /:/ /:/     \__\:\  /__/:/ \__\:|
//  /__/:/  /  /\ /__/:/\:\_\:\ /__/:/ /:/      /  /::\ \  \:\ /  /:/
//  \  \:\ /  /:/ \__\/~|::\/:/ \  \:\/:/      /  /:/\:\ \  \:\  /:/
//   \  \:\  /:/     |  |:|::/   \  \::/      /  /:/__\/  \  \:\/:/
//    \  \:\/:/      |  |:|\/     \  \:\     /__/:/        \  \::/
//     \  \::/       |__|:|        \  \:\    \__\/          \__\/
//      \__\/         \__\|         \__\/

/// @title CRFTDStakingToken (Cross-Chain)
/// @author phaze (https://github.com/0xPhaze)
/// @notice Minimal cross-chain ERC721 staking contract supporting multiple collections
/// @notice Token ids are registered with child ERC20 token
contract CRFTDStakingToken is FxERC721sRootTunnelUDS, ERC20RewardUDS, OwnableUDS, UUPSUpgrade {
    event CollectionRegistered(address indexed collection, uint256 rewardRate);

    /// @dev Setting `rewardEndDate` to this date enables migration.
    uint256 constant MIGRATION_START_DATE = (1 << 42) - 1;

    constructor(address checkpointManager, address fxRoot) FxERC721sRootTunnelUDS(checkpointManager, fxRoot) {
        __ERC20_init("CRFTD", "CRFTD", 18);
    }

    /* ------------- init ------------- */

    function init(string calldata name, string calldata symbol) external initializer {
        __Ownable_init();
        __ERC20_init(name, symbol, 18);
    }

    /* ------------- view ------------- */

    function rewardEndDate() public view override returns (uint256) {
        return s().rewardEndDate;
    }

    function rewardDailyRate() public pure override returns (uint256) {
        return 1e16; // 0.01
    }

    function rewardRate(address collection) public view returns (uint256) {
        return s().rewardRate[collection];
    }

    function ownerOf(address collection, uint256 id) public view returns (address) {
        return s().ownerOf[collection][id];
    }

    function getDailyReward(address user) public view returns (uint256) {
        return _getRewardMultiplier(user) * rewardDailyRate();
    }

    function migrationStarted() public view returns (bool) {
        if (rewardEndDate() != MIGRATION_START_DATE) return false;
        if (fxChildTunnel() == address(0)) return false;

        return true;
    }

    /* ------------- external ------------- */

    /// @notice Stake ids from approved collections.
    ///         If child is linked and migration enabled,
    ///         this will register the ids with child contract.
    /// @param collection erc721 collection address.
    /// @param tokenIds erc721 id array per collection.
    function stake(address collection, uint256[] calldata tokenIds) external {
        uint256 rate = s().rewardRate[collection];

        if (rate == 0) revert CollectionNotRegistered();

        for (uint256 i; i < tokenIds.length; ++i) {
            ERC721UDS(collection).transferFrom(msg.sender, address(this), tokenIds[i]);

            s().ownerOf[collection][tokenIds[i]] = msg.sender;
        }

        if (migrationStarted()) {
            if (_getRewardMultiplier(msg.sender) != 0) revert MigrationRequired();

            _registerERC721IdsWithChild(collection, msg.sender, tokenIds);
        } else {
            _increaseRewardMultiplier(msg.sender, uint216(tokenIds.length * rate));
        }
    }

    /// @notice Unstake ids. If child is linked and migration enabled,
    ///         this will de-register the ids with child contract.
    /// @param collection erc721 collection address.
    /// @param tokenIds erc721 id array per collection.
    function unstake(address collection, uint256[] calldata tokenIds) external {
        uint256 rate = s().rewardRate[collection];

        if (rate == 0) revert CollectionNotRegistered();

        if (migrationStarted()) {
            if (_getRewardMultiplier(msg.sender) != 0) revert MigrationRequired();

            _deregisterERC721IdsWithChild(collection, tokenIds);
        } else _decreaseRewardMultiplier(msg.sender, uint216(tokenIds.length * rate));

        for (uint256 i; i < tokenIds.length; ++i) {
            if (s().ownerOf[collection][tokenIds[i]] != msg.sender) revert IncorrectOwner();

            delete s().ownerOf[collection][tokenIds[i]];

            ERC721UDS(collection).transferFrom(address(this), msg.sender, tokenIds[i]);
        }
    }

    /// @notice Synchronizes any erc721 ids with child. Duplicates are caught by child.
    /// @param collections erc721 collection addresses.
    /// @param tokenIds erc721 id array per collection.
    /// @return rewardMultiplier calculated rewardMultiplier to be registered with child.
    ///         Used by `safeMigrate()`.
    function synchronizeIdsWithChild(address[] calldata collections, uint256[][] calldata tokenIds)
        public
        returns (uint256 rewardMultiplier)
    {
        if (!migrationStarted()) revert MigrationNotStarted();
        if (_getRewardMultiplier(msg.sender) != 0) revert MigrationRequired();

        for (uint256 i; i < collections.length; ++i) {
            uint256 rate = s().rewardRate[collections[i]];

            if (rate == 0) revert CollectionNotRegistered();

            uint256[] calldata ids = tokenIds[i];
            mapping(uint256 => address) storage owners = s().ownerOf[collections[i]];

            rewardMultiplier += ids.length * rate;

            for (uint256 j; j < ids.length; ++j) {
                if (owners[ids[j]] != msg.sender) revert IncorrectOwner();
            }

            // note: we're optimistic by fore-going unique tokenId/collection checks
            // duplicates are caught in child registry and could only hurt the user during migration
            if (ids.length != 0) _registerERC721IdsWithChild(collections[i], msg.sender, ids);
        }
    }

    /// @notice Migrates the current user balance and erc721 ids to layer 2.
    ///         user `rewardMultiplier` MUST be 0 before registering any ids with child,
    ///         as otherwise it would be possible to earn on both chains.
    /// @param collections erc721 collection addresses.
    /// @param tokenIds erc721 id array per collection.
    function safeMigrate(address[] calldata collections, uint256[][] calldata tokenIds) external {
        if (!migrationStarted()) revert MigrationNotStarted();

        _claimReward(msg.sender);

        uint256 currentRewardMultiplier = _getRewardMultiplier(msg.sender);

        // migrate erc20 token balance
        uint256 balance = balanceOf(msg.sender);

        _burn(msg.sender, balance);

        _sendMessageToChild(abi.encode(MINT_ERC20_SIG, abi.encode(msg.sender, balance)));

        _setRewardMultiplier(msg.sender, 0);

        // migrate erc721 ids
        uint256 migratedRewardMultiplier = synchronizeIdsWithChild(collections, tokenIds);

        // this check does not guarantee that the user has migrated all erc721s,
        // but is an additional safety measure for the user
        if (currentRewardMultiplier != migratedRewardMultiplier) revert MigrationIncomplete();
    }

    function claimReward() external {
        _claimReward(msg.sender);
    }

    /* ------------- erc20 ------------- */

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _claimReward(msg.sender);

        return ERC20UDS.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _claimReward(from);

        return ERC20UDS.transferFrom(from, to, amount);
    }

    /* ------------- O(n) read-only ------------- */

    function stakedIdsOf(
        address collection,
        address user,
        uint256 collectionSize
    ) external view returns (uint256[] memory) {
        return utils.getOwnedIds(s().ownerOf[collection], user, collectionSize);
    }

    /* ------------- owner ------------- */

    function startMigration(address fxChild) public onlyOwner {
        if (fxChild == address(0)) revert InvalidFxChild();

        setFxChildTunnel(fxChild);

        s().rewardEndDate = MIGRATION_START_DATE;
    }

    function setRewardEndDate(uint256 endDate) external onlyOwner {
        s().rewardEndDate = endDate;
    }

    function registerCollection(address collection, uint200 rate) external onlyOwner {
        if (rate == 0) revert ZeroReward();
        if (s().rewardRate[collection] != 0) revert CollectionAlreadyRegistered();

        s().rewardRate[collection] = rate;

        emit CollectionRegistered(collection, rate);
    }

    function airdrop(address[] calldata tos, uint256[] calldata amounts) external onlyOwner {
        for (uint256 i; i < tos.length; ++i) _mint(tos[i], amounts[i]);
    }

    /* ------------- override ------------- */

    function _authorizeUpgrade() internal override onlyOwner {}

    function _authorizeTunnelController() internal override onlyOwner {}
}