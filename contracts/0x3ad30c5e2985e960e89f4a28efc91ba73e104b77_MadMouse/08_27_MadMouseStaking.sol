//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Gouda.sol';
import './lib/ERC721M.sol';
import './lib/Ownable.sol';

error InvalidBoostToken();
error TransferFailed();
error BoostInEffect();
error NotSpecialGuestOwner();
error SpecialGuestIndexMustDiffer();

abstract contract MadMouseStaking is ERC721M, Ownable {
    using UserDataOps for uint256;

    event BoostActivation(address token);

    Gouda public gouda;

    uint256 constant dailyReward = 1e18;

    uint256 constant ROLE_BONUS_3 = 2000;
    uint256 constant ROLE_BONUS_5 = 3500;
    uint256 constant TOKEN_BONUS = 1000;
    uint256 constant TIME_BONUS = 1000;
    uint256 constant RARITY_BONUS = 1000;
    uint256 constant OG_BONUS = 2000;
    uint256 constant SPECIAL_GUEST_BONUS = 1000;

    uint256 immutable OG_BONUS_END;
    uint256 immutable LAST_GOUDA_EMISSION_DATE;

    uint256 constant TOKEN_BOOST_DURATION = 9 days;
    uint256 constant TOKEN_BOOST_COOLDOWN = 9 days;
    uint256 constant TIME_BONUS_STAKE_DURATION = 30 days;

    mapping(IERC20 => uint256) tokenBoostCosts;
    mapping(uint256 => IERC721) specialGuests;
    mapping(IERC721 => bytes4) specialGuestsNumStakedSelector;

    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(uint256 maxSupply_, uint256 maxPerWallet_)
        ERC721M('MadMouseCircus', 'MMC', 1, maxSupply_, maxPerWallet_)
    {
        OG_BONUS_END = block.timestamp + 60 days;
        LAST_GOUDA_EMISSION_DATE = block.timestamp + 5 * 365 days;
    }

    /* ------------- External ------------- */

    function burnForBoost(IERC20 token) external payable {
        uint256 userData = _claimReward();

        uint256 boostCost = tokenBoostCosts[token];
        if (boostCost == 0) revert InvalidBoostToken();

        bool success = token.transferFrom(msg.sender, burnAddress, boostCost);
        if (!success) revert TransferFailed();

        uint256 boostStart = userData.boostStart();
        if (boostStart + TOKEN_BOOST_DURATION + TOKEN_BOOST_COOLDOWN > block.timestamp) revert BoostInEffect();

        _userData[msg.sender] = userData.setBoostStart(block.timestamp);

        emit BoostActivation(address(token));
    }

    function claimSpecialGuest(uint256 collectionIndex) external payable {
        uint256 userData = _claimReward();
        uint256 specialGuestIndexOld = userData.specialGuestIndex();

        if (collectionIndex == specialGuestIndexOld) revert SpecialGuestIndexMustDiffer();
        if (collectionIndex != 0 && !hasSpecialGuest(msg.sender, collectionIndex)) revert NotSpecialGuestOwner();

        _userData[msg.sender] = userData.setSpecialGuestIndex(collectionIndex);
    }

    function clearSpecialGuestData() external payable {
        _userData[msg.sender] = _userData[msg.sender].setSpecialGuestIndex(0);
    }

    /* ------------- Internal ------------- */

    function tokenBonus(uint256 userData) private view returns (uint256) {
        unchecked {
            uint256 lastClaimed = userData.lastClaimed();
            uint256 boostEnd = userData.boostStart() + TOKEN_BOOST_DURATION;

            if (lastClaimed > boostEnd) return 0;
            if (block.timestamp <= boostEnd) return TOKEN_BONUS;

            // follows: lastClaimed <= boostEnd < block.timestamp

            // user is half-way through running out of boost, calculate exact fraction,
            // as if claim was initiated once at end of boost and once now
            // bonus * (time delta spent with boost bonus) / (complete duration)
            return (TOKEN_BONUS * (boostEnd - lastClaimed)) / (block.timestamp - lastClaimed);
        }
    }

    function roleBonus(uint256 userData) private pure returns (uint256) {
        uint256 numRoles = userData.uniqueRoleCount();
        return numRoles < 3 ? 0 : numRoles < 5 ? ROLE_BONUS_3 : ROLE_BONUS_5;
    }

    function rarityBonus(uint256 userData) private pure returns (uint256) {
        unchecked {
            uint256 numStaked = userData.numStaked();
            return numStaked == 0 ? 0 : (userData.rarityPoints() * RARITY_BONUS) / numStaked;
        }
    }

    function OGBonus(uint256 userData) private view returns (uint256) {
        unchecked {
            uint256 count = userData.OGCount();
            uint256 lastClaimed = userData.lastClaimed();

            if (count == 0 || lastClaimed > OG_BONUS_END) return 0;

            // follows: 0 < count <= numStaked
            uint256 bonus = (count * OG_BONUS) / userData.numStaked();
            if (block.timestamp <= OG_BONUS_END) return bonus;

            // follows: lastClaimed <= OG_BONUS_END < block.timestamp
            return (bonus * (OG_BONUS_END - lastClaimed)) / (block.timestamp - lastClaimed);
        }
    }

    function timeBonus(uint256 userData) private view returns (uint256) {
        unchecked {
            uint256 stakeStart = userData.stakeStart();
            uint256 stakeBonusStart = stakeStart + TIME_BONUS_STAKE_DURATION;

            if (block.timestamp < stakeBonusStart) return 0;

            uint256 lastClaimed = userData.lastClaimed();
            if (lastClaimed >= stakeBonusStart) return TIME_BONUS;

            // follows: lastClaimed < stakeBonusStart <= block.timestamp
            return (TIME_BONUS * (block.timestamp - stakeBonusStart)) / (block.timestamp - lastClaimed);
        }
    }

    function hasSpecialGuest(address user, uint256 index) public view returns (bool) {
        if (index == 0) return false;

        // first 18 addresses are hardcoded to save gas
        if (index < 19) {
            address[19] memory guests = [
                0x0000000000000000000000000000000000000000, // 0: reserved
                0x4BB33f6E69fd62cf3abbcC6F1F43b94A5D572C2B, // 1: Bears Deluxe
                0xbEA8123277142dE42571f1fAc045225a1D347977, // 2: DystoPunks
                0x12d2D1beD91c24f878F37E66bd829Ce7197e4d14, // 3: Galactic Apes
                0x0c2E57EFddbA8c768147D1fdF9176a0A6EBd5d83, // 4: Kaiju Kingz
                0x6E5a65B5f9Dd7b1b08Ff212E210DCd642DE0db8B, // 5: Octohedz
                0x17eD38f5F519C6ED563BE6486e629041Bed3dfbC, // 6: PXQuest Adventurer
                0xdd67892E722bE69909d7c285dB572852d5F8897C, // 7: Scholarz
                0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e, // 8: Doodles
                0x6F44Db5ed6b86d9cC6046D0C78B82caD9E600F6a, // 9: Digi Dragonz
                0x219B8aB790dECC32444a6600971c7C3718252539, // 10: Sneaky Vampire Syndicate
                0xC4a0b1E7AA137ADA8b2F911A501638088DFdD508, // 11: Uninterested Unicorns
                0x9712228cEeDA1E2dDdE52Cd5100B88986d1Cb49c, // 12: Wulfz
                0x56b391339615fd0e88E0D370f451fA91478Bb20F, // 13: Ethalien
                0x648E8428e0104Ec7D08667866a3568a72Fe3898F, // 14: Dysto Apez
                0xd2F668a8461D6761115dAF8Aeb3cDf5F40C532C6, // 15: Karafuru
                0xbad6186E92002E312078b5a1dAfd5ddf63d3f731, // 16: Anonymice
                0xcB4307F1c3B5556256748DDF5B86E81258990B3C, // 17: The Other Side
                0x5c211B8E4f93F00E2BD68e82F4E00FbB3302b35c //  18: Global Citizen Club
            ];

            if (IERC721(guests[index]).balanceOf(user) != 0) return true;

            if (index == 10) return ISVSGraveyard(guests[index]).getBuriedCount(user) != 0;
            else if (index == 12) return AWOO(guests[index]).getStakedAmount(user) != 0;
            else if (index == 16) return CheethV2(guests[index]).stakedMiceQuantity(user) != 0;
        } else {
            IERC721 collection = specialGuests[index];
            if (address(collection) != address(0)) {
                if (collection.balanceOf(user) != 0) return true;
                bytes4 selector = specialGuestsNumStakedSelector[collection];
                if (selector != bytes4(0)) {
                    (bool success, bytes memory data) = address(collection).staticcall(
                        abi.encodeWithSelector(selector, user)
                    );
                    return success && abi.decode(data, (uint256)) != 0;
                }
            }
        }
        return false;
    }

    function specialGuestBonus(address user, uint256 userData) private view returns (uint256) {
        uint256 index = userData.specialGuestIndex();
        if (!hasSpecialGuest(user, index)) return 0;
        return SPECIAL_GUEST_BONUS;
    }

    function _pendingReward(address user, uint256 userData) internal view override returns (uint256) {
        uint256 lastClaimed = userData.lastClaimed();
        if (lastClaimed == 0) return 0;

        uint256 timestamp = min(LAST_GOUDA_EMISSION_DATE, block.timestamp);

        unchecked {
            uint256 delta = timestamp < lastClaimed ? 0 : timestamp - lastClaimed;

            uint256 reward = (userData.baseReward() * delta * dailyReward) / (1 days);
            if (reward == 0) return 0;

            uint256 bonus = totalBonus(user, userData);

            // needs to be calculated per myriad for more accuracy
            return (reward * (10000 + bonus)) / 10000;
        }
    }

    function totalBonus(address user, uint256 userData) internal view returns (uint256) {
        unchecked {
            return
                roleBonus(userData) +
                specialGuestBonus(user, userData) +
                rarityBonus(userData) +
                OGBonus(userData) +
                timeBonus(userData) +
                tokenBonus(userData);
        }
    }

    function _payoutReward(address user, uint256 reward) internal override {
        // note: less than you would receive in 10 seconds
        if (reward > 0.0001 ether) gouda.mint(user, reward);
    }

    /* ------------- View ------------- */

    // for convenience
    struct StakeInfo {
        uint256 numStaked;
        uint256 roleCount;
        uint256 roleBonus;
        uint256 specialGuestBonus;
        uint256 tokenBoost;
        uint256 stakeStart;
        uint256 timeBonus;
        uint256 rarityPoints;
        uint256 rarityBonus;
        uint256 OGCount;
        uint256 OGBonus;
        uint256 totalBonus;
        uint256 multiplierBase;
        uint256 dailyRewardBase;
        uint256 dailyReward;
        uint256 pendingReward;
        int256 tokenBoostDelta;
        uint256[3] levelBalances;
    }

    // calculates momentary totalBonus for display instead of effective bonus
    function getUserStakeInfo(address user) external view returns (StakeInfo memory info) {
        unchecked {
            uint256 userData = _userData[user];

            info.numStaked = userData.numStaked();

            info.roleCount = userData.uniqueRoleCount();

            info.roleBonus = roleBonus(userData) / 100;
            info.specialGuestBonus = specialGuestBonus(user, userData) / 100;
            info.tokenBoost = (block.timestamp < userData.boostStart() + TOKEN_BOOST_DURATION) ? TOKEN_BONUS / 100 : 0;

            info.stakeStart = userData.stakeStart();
            info.timeBonus = (info.stakeStart > 0 &&
                block.timestamp > userData.stakeStart() + TIME_BONUS_STAKE_DURATION)
                ? TIME_BONUS / 100
                : 0;

            info.OGCount = userData.OGCount();
            info.OGBonus = (block.timestamp > OG_BONUS_END || userData.numStaked() == 0)
                ? 0
                : (userData.OGCount() * OG_BONUS) / userData.numStaked() / 100;

            info.rarityPoints = userData.rarityPoints();
            info.rarityBonus = rarityBonus(userData) / 100;

            info.totalBonus =
                info.roleBonus +
                info.specialGuestBonus +
                info.tokenBoost +
                info.timeBonus +
                info.rarityBonus +
                info.OGBonus;

            info.multiplierBase = userData.baseReward();
            info.dailyRewardBase = info.multiplierBase * dailyReward;

            info.dailyReward = (info.dailyRewardBase * (100 + info.totalBonus)) / 100;
            info.pendingReward = _pendingReward(user, userData);

            info.tokenBoostDelta = int256(TOKEN_BOOST_DURATION) - int256(block.timestamp - userData.boostStart());

            info.levelBalances = userData.levelBalances();
        }
    }

    /* ------------- Owner ------------- */

    function setGoudaToken(Gouda gouda_) external payable onlyOwner {
        gouda = gouda_;
    }

    function setSpecialGuests(IERC721[] calldata collections, uint256[] calldata indices) external payable onlyOwner {
        for (uint256 i; i < indices.length; ++i) {
            uint256 index = indices[i];
            require(index != 0);
            specialGuests[index] = collections[i];
        }
    }

    function setSpecialGuestStakingSelector(IERC721 collection, bytes4 selector) external payable onlyOwner {
        specialGuestsNumStakedSelector[collection] = selector;
    }

    function setBoostTokens(IERC20[] calldata _boostTokens, uint256[] calldata _boostCosts) external payable onlyOwner {
        for (uint256 i; i < _boostTokens.length; ++i) tokenBoostCosts[_boostTokens[i]] = _boostCosts[i];
    }
}

// Special guest's staking interfaces
interface ISVSGraveyard {
    function getBuriedCount(address burier) external view returns (uint256);
}

interface AWOO {
    function getStakedAmount(address staker) external view returns (uint256);
}

interface CheethV2 {
    function stakedMiceQuantity(address _address) external view returns (uint256);
}