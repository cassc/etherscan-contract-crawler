// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {utils} from "./utils/utils.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC20UDS} from "UDS/tokens/ERC20UDS.sol";
import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {ERC20RewardUDS} from "UDS/tokens/ERC20RewardUDS.sol";

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

/// @title CRFTDStakingToken
/// @author phaze (https://github.com/0xPhaze)
/// @notice Minimal ERC721 staking contract supporting multiple collections
/// @notice Combines ERC20 Token to avoid external calls
contract CRFTDStakingToken is ERC20RewardUDS, UUPSUpgrade, OwnableUDS {
    event CollectionRegistered(address indexed collection, uint256 rewardRate);

    /* ------------- init ------------- */

    function init(string calldata name, string calldata symbol) external initializer {
        __Ownable_init();
        __ERC20_init(name, symbol, 18);
    }

    /* ------------- public ------------- */

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

    /* ------------- external ------------- */

    function stake(address collection, uint256[] calldata tokenIds) external {
        uint256 rate = s().rewardRate[collection];

        if (rate == 0) revert CollectionNotRegistered();

        _increaseRewardMultiplier(msg.sender, uint216(tokenIds.length * rate));

        for (uint256 i; i < tokenIds.length; ++i) {
            ERC721(collection).transferFrom(msg.sender, address(this), tokenIds[i]);

            s().ownerOf[collection][tokenIds[i]] = msg.sender;
        }
    }

    function unstake(address collection, uint256[] calldata tokenIds) external {
        uint256 rate = s().rewardRate[collection];

        if (rate == 0) revert CollectionNotRegistered();

        _decreaseRewardMultiplier(msg.sender, uint216(tokenIds.length * rate));

        for (uint256 i; i < tokenIds.length; ++i) {
            if (s().ownerOf[collection][tokenIds[i]] != msg.sender) revert IncorrectOwner();

            delete s().ownerOf[collection][tokenIds[i]];

            ERC721(collection).transferFrom(address(this), msg.sender, tokenIds[i]);
        }
    }

    function claimReward() external {
        _claimReward(msg.sender);
    }

    /* ------------- O(n) read-only ------------- */

    function stakedIdsOf(
        address collection,
        address user,
        uint256 collectionSize
    ) external view returns (uint256[] memory stakedIds) {
        return utils.getOwnedIds(s().ownerOf[collection], user, collectionSize);
    }

    /* ------------- owner ------------- */

    function registerCollection(address collection, uint200 rate) external onlyOwner {
        if (rate == 0) revert ZeroReward();
        if (s().rewardRate[collection] != 0) revert CollectionAlreadyRegistered();

        s().rewardRate[collection] = rate;

        emit CollectionRegistered(collection, rate);
    }

    function setRewardEndDate(uint256 endDate) external onlyOwner {
        s().rewardEndDate = endDate;
    }

    function airdrop(address[] calldata tos, uint256[] calldata amounts) external onlyOwner {
        for (uint256 i; i < tos.length; ++i) _mint(tos[i], amounts[i]);
    }

    /* ------------- UUPSUpgrade ------------- */

    function _authorizeUpgrade() internal override onlyOwner {}
}