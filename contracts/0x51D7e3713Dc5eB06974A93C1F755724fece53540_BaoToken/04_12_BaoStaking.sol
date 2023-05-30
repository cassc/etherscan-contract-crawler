// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//                                       -\**:. `"^`
//                                     ;HNXav*,^;}?|:,.`
//                                    tbKX&]:,:7I}=\:-_._,`
//                                  :OKgTv)*7}ri=*;::,^``:;:^
//                               :&[email protected]])*\;:--~.`_;;-,^.`
//                            :cdXDOhT&Yuctl1=*;::,^..,;+*;:--,"~^.
//                         ;LX8dXSDOhasocv}1>+|;:---:;|||;:--,"_^^^..`
//                      :[email protected]]>+|;::::;;;:::--,_~^^^..'````
//                   `[email protected]@DhT0Yo3cjt}i]=+*\;;:::::::---,_^^^..'``    ``
//                 `)3&hSd8dbDhT&YoccvIt}l17=)*|;;:::::::--,"_^^^..'```     ``
//                ;[email protected]&nucvjItr}i17==+**\;;;:::::--,"~^^^..''``        `
//              ^^:lnOXg8XDhaYucvjttr}lir3Luv=**|;;;;;:::--,_~^^....'-XMMh='     `
//             ``~>[email protected]\;;;;::::-,"~^^....-MMMHDr=:`
//              ,[email protected]}}MMMMMMMMmt|1MMM=;;;;::::-,_^^....MMQ8OT-`';`
//          ` `-}&Smqm8SPTsucjr}}lMMMMMMMMMDl|]MMMM|;;;;:::--"^^..''MMmSOhV7)1:`
//        '"^,+vhdHNNEbOT&ocjtllitMMMMMMMMMMMMMMMMM1||\;;;::-"^..''`TMNKSDhaLt\-
//        =)=}nOmNQBHgDhaYuvIrli?jMMMMMMMMMMMMMMMMM1|||;;;::-~.'''``.dMBq8Oaor*|
//       cLY0OgNQQQWHdDh0Yuvt}i?11MMMMMMMMMMMMMMMMM**|;;;:::-_..''```.c#WHSaul7+        `
//      =OS8mNQMMMMQH8DhasucIrli111MMMMMMMMMMMMMMM+*|;;;::::-,^..''````.1VEHda7`        ``
//      @mHWQMMMMMMQNEbDkan3vtli1]>=?SMMMMMMMMMh)**|\;;::::--,~^..-'```````,,``````     ``
//      NQMMMMMMMMMMQNKbOh0Luv}i7==))))))))+*****||\;;;1MMMXkncuOKo.'''````````````````````
//      QMMMMMMMMMMMMQNmdDh&n3I}17==)))))))+****|\;;;;:::::*71=;,~^^...''''````````````````
//      QMMMMMMMMMMMMMQBHEbOTVocjtli?11]>>==)+**||;;;;::::::----,,_~^^^.........''''''````
//      jMMMMMMMMMMMMMMMQ#[email protected]}}l?1]>=)***|\;;;::::::-----,,,"__~^^^^^......''```
//       qMMMMMMMMMMMMMMMMWNmXDha&noouccjtr}li17==)+**|\;;;::::::::-----,,,"_~^^^....'``'
//        MMMMMMMMMMMMMMMMMQBHgbOhT0Vnoo3cvIt}li117>=)***|\;;;;::::::::----,,,_~^^^..'''
//         QMMMMMMMMMMMMMMMMQWNq8bOhTa&snoucvjt}ll?1]>=))**||\;;;;;:::::::----,"_^^^..'
//          -MMMMMMMMMMMMMMMMMQWNq8bDOhka0sLo3cvjIr}li?1]7>==)+***|\;;;;:::::----,,~^
//            ;NMMMMMMMMMMMMMMMMQQNqEgdSDOhka0Ynou3ccvjItr}lli117>=))***||;;;:::::-
//               ][email protected]&sYLooucccvjItr}}li?17==)+*||:'
//                 .1qMMMMMMMMMMMMMMMQQBNHqEKdSDOPkaa&snoou3cccvvjItr}li1]>;,`
//                      :IOMMMMMMMMMMMMQQBNHm8XSOPka0Vnou3cvjtr}llli?>:"`
//                            _|jnbQMMMMMMMMQBNqK8XSDPTasLucvI|~.`
//                                   oMMMMMMMMMMMMQqSTocri7)*|:.
//                                 IMMMMMMMMMMNdksc}1)\::-,~^..'`
//                                lTMMMQMMMQqD0oj}1=*;:-_^.'```````
//                              -cOQMN8KMMM#gO&uj}1=*;:-^.''`````````
//                             :hHQ#gDSQMMMMHSTs3v}])|:-~^.'````` '.``
//                            1KMQEOaLXMMMMMQEDTn3Ii7+;:-_^.''````'^.'`
//                           -WMMghYuYHMMMMMM#dO0Lcr?=|;:-_^..'```.^^.'
//                           [email protected]*\::-_^..'``^",~.'
//                          ?MMNPscvobMMMMMMMMN8Paov}1)*;:-,_^..``,---~.`
//                         .MMWS&utvV8MMMMMMMMWEDTs3jl>*\;:--"^.`.:\;:-_`
//                         lMMNOLjrcTgMMMMMMMMMNXOTYujl>*\:::-,^.`;ll=-`
//                         '[email protected])|;;;:"
//                            -;\-`  QMMMMMMMQ#HEEgdSOaLv}i]+:,^
//                                   ]MMMMMHdhs3t`  ^P8gbhu];-.
//                                    MMMMW8kci>)    hgKDV}|:^'
//                                    @MMMHho1*;:    hNHDYl\:^
//                                     dMMmav=;:      |t3v7:.
//                                       '~^'
//
//                                         author: phaze

import {IERC721 as IBaoSociety} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import "../lib/solmate/src/tokens/ERC20.sol";

import "./Ownable.sol";

error IncorrectOwner();

abstract contract BaoStaking is Ownable, ERC20 {
    struct TokenData {
        address owner;
        uint40 lastClaimed;
        uint40 rarity;
    }

    struct StakeData {
        uint40 rarityBonus;
        uint40 numStaked;
        uint40 lastClaimed;
    }

    uint256 constant DAILY_BASE_REWARD = 100;
    uint256 constant DAILY_STAKED_REWARD = 150;

    uint256 public immutable REWARD_EMISSION_START = 1652662800;
    uint256 public immutable REWARD_EMISSION_END = 1652662800 + 5 * 365 days;

    mapping(uint256 => TokenData) public tokenData;
    mapping(address => StakeData) public stakeData;

    IBaoSociety public constant baoSociety = IBaoSociety(0xba033D82c64DD514B184e2d1405cD395dfE6e706);

    /* ------------- External ------------- */

    function stake(uint256[] calldata tokenIds) external payable {
        unchecked {
            claimRewardStaked();

            TokenData storage tData;
            StakeData storage sData = stakeData[msg.sender];

            uint256 tokenId;

            uint256 reward;
            uint256 rarityBonus = sData.rarityBonus;

            for (uint256 i; i < tokenIds.length; ++i) {
                tokenId = tokenIds[i];

                baoSociety.transferFrom(msg.sender, address(this), tokenId);

                tData = tokenData[tokenId];
                tData.owner = msg.sender;

                // accrue non-staked rewards
                reward += _calculateRewardSingle(tData, tokenId);
                rarityBonus += getRarityBonus(tData);
            }

            sData.numStaked += uint40(tokenIds.length);
            sData.rarityBonus = uint40(rarityBonus);

            _mint(msg.sender, reward);
        }
    }

    function unstake(uint256[] calldata tokenIds) external payable {
        unchecked {
            claimRewardStaked();

            TokenData storage tData;
            StakeData storage sData = stakeData[msg.sender];

            uint256 tokenId;
            uint256 rarityBonus = sData.rarityBonus;

            for (uint256 i; i < tokenIds.length; ++i) {
                tokenId = tokenIds[i];
                tData = tokenData[tokenId];

                if (tData.owner != msg.sender) revert IncorrectOwner();

                baoSociety.transferFrom(address(this), msg.sender, tokenId);

                rarityBonus -= getRarityBonus(tData); // underflow not possible if rarity stays constant
                tData.lastClaimed = uint40(block.timestamp);
            }

            sData.numStaked -= uint40(tokenIds.length);
            sData.rarityBonus = uint40(rarityBonus);
        }
    }

    function claimRewardStaked() public payable {
        uint256 reward = pendingRewardStaked(msg.sender);

        _mint(msg.sender, reward);

        stakeData[msg.sender].lastClaimed = uint40(block.timestamp);
    }

    function claimReward(uint256[] calldata tokenIds) external payable {
        unchecked {
            TokenData storage tData;

            uint256 reward;
            uint256 tokenId;

            for (uint256 i; i < tokenIds.length; ++i) {
                tokenId = tokenIds[i];
                tData = tokenData[tokenId];

                if (baoSociety.ownerOf(tokenId) != msg.sender) revert IncorrectOwner();

                reward += _calculateRewardSingle(tData, tokenId);
                tData.lastClaimed = uint40(block.timestamp);
            }

            _mint(msg.sender, reward);
        }
    }

    /* ------------- View ------------- */

    function pendingRewardStaked(address user) public view returns (uint256) {
        unchecked {
            uint256 timestamp = block.timestamp;
            if (timestamp > REWARD_EMISSION_END) timestamp = REWARD_EMISSION_END;

            uint256 staked = stakeData[user].numStaked;
            if (staked == 0) return 0;

            uint256 lastClaimed = stakeData[user].lastClaimed;

            if (lastClaimed > timestamp) return 0;
            if (lastClaimed == 0) lastClaimed = REWARD_EMISSION_START;

            return
                ((timestamp - lastClaimed) * (staked * DAILY_STAKED_REWARD + stakeData[user].rarityBonus) * 1e18) /
                1 days;
        }
    }

    function dailyRewardStaked(address user) external view returns (uint256) {
        unchecked {
            return ((uint256(stakeData[user].numStaked) * DAILY_STAKED_REWARD + stakeData[user].rarityBonus) * 1e18);
        }
    }

    function pendingReward(uint256[] calldata tokenIds) external view returns (uint256) {
        unchecked {
            TokenData storage tData;

            uint256 reward;
            uint256 tokenId;

            for (uint256 i; i < tokenIds.length; ++i) {
                tokenId = tokenIds[i];
                tData = tokenData[tokenId];

                reward += _calculateRewardSingle(tData, tokenId);
            }

            return reward;
        }
    }

    function dailyReward(uint256[] calldata tokenIds) external view returns (uint256) {
        unchecked {
            uint256 reward;

            for (uint256 i; i < tokenIds.length; ++i)
                reward += (DAILY_BASE_REWARD + getRarityBonus(tokenData[tokenIds[i]])) * 1e18;

            return reward;
        }
    }

    function getRarityBonus(uint256 tokenId) external view returns (uint256) {
        return getRarityBonus(tokenData[tokenId]);
    }

    function numStaked(address user) external view returns (uint256) {
        return stakeData[user].numStaked;
    }

    function numOwned(address user) external view returns (uint256) {
        return baoSociety.balanceOf(user) + stakeData[user].numStaked;
    }

    function totalNumStaked() external view returns (uint256) {
        return baoSociety.balanceOf(address(this));
    }

    /* ------------- Private ------------- */

    function getRarityBonus(TokenData storage tData) private view returns (uint256) {
        uint256 rarity = tData.rarity;
        return rarity == 0 ? 5 : rarity;
    }

    function _calculateRewardSingle(TokenData storage tData, uint256 tokenId) private view returns (uint256) {
        uint256 rewardBonus;
        uint256 lastClaimed = tData.lastClaimed;

        if (lastClaimed > REWARD_EMISSION_END) return 0;
        if (lastClaimed == 0) {
            lastClaimed = REWARD_EMISSION_START;
            if (tokenId % 5 == 0) rewardBonus = 1500 * 1e18;
        }

        uint256 timestamp = block.timestamp;
        if (timestamp > REWARD_EMISSION_END) timestamp = REWARD_EMISSION_END;

        return rewardBonus + ((timestamp - lastClaimed) * (DAILY_BASE_REWARD + getRarityBonus(tData)) * 1e18) / 1 days;
    }

    /* ------------- Owner ------------- */

    // @note should only be called once before any interaction happens
    // bad things (underflow) can happen if this is changed while someone is staking
    function setRarities(uint256[] calldata ids, uint256[] calldata rarities) external onlyOwner {
        unchecked {
            for (uint256 i; i < ids.length; ++i) tokenData[ids[i]].rarity = uint40(rarities[i]);
        }
    }

    /* ------------- O(n) Read-Only ------------- */

    function stakedTokenIdsOf(address user) external view returns (uint256[] memory) {
        uint256 staked = stakeData[user].numStaked;
        uint256[] memory stakedIds = new uint256[](staked);
        if (staked == 0) return stakedIds;

        uint256 count;
        for (uint256 i = 1; i < 3888 + 1; ++i) {
            if (tokenData[i].owner == user) {
                stakedIds[count++] = i;
                if (staked == count) return stakedIds;
            }
        }

        return stakedIds;
    }
}