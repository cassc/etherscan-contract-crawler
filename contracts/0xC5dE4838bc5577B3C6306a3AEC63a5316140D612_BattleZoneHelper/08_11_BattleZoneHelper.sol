// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IBattleZone} from "../interfaces/IBattleZone.sol";
import {IBeepBoopBotzV2} from "../BeepBoopBotzV2/IBeepBoopBotzV2.sol";

contract BattleZoneHelper {
    IBattleZone private immutable _battleZone;
    IBeepBoopBotzV2 private immutable _beepBoopBotV2Nft;
    address private immutable _beepBoopBotNft;

    constructor(
        address battleZone_,
        address beepBoopBotNft_,
        address beepBoopBotV2Nft_
    ) {
        _battleZone = IBattleZone(battleZone_);
        _beepBoopBotNft = beepBoopBotNft_;
        _beepBoopBotV2Nft = IBeepBoopBotzV2(beepBoopBotV2Nft_);
    }

    /**
     * @notice Get the number of charged bots
     */
    function getNumChargedBots() public view returns (uint256) {
        unchecked {
            uint256 charged;
            for (uint256 i = 1; i <= 10000; i++) {
                if (_battleZone.powerCoreYield(i) != 0) {
                    charged++;
                }
            }
            return charged;
        }
    }

    /**
     * @notice Get uncharged bots
     */
    function getUnchargedBotIds() public view returns (uint256[] memory) {
        unchecked {
            uint256[] memory bots = new uint256[](10000);
            uint256 idx;
            for (uint256 i; i < 10000; ++i) {
                if (_battleZone.powerCoreYield(i) == 0) {
                    bots[idx++] = i;
                }
            }
            assembly {
                mstore(bots, idx)
            }
            return bots;
        }
    }

    /**
     * @notice Get the power core yield of many bots
     */
    function powerCoreYieldOf(
        uint256[] memory botIds
    ) public view returns (uint256[] memory) {
        unchecked {
            uint256[] memory rarities = new uint256[](botIds.length);
            for (uint256 t; t < botIds.length; ++t) {
                rarities[t] = _battleZone.powerCoreYield(botIds[t]);
            }
            return rarities;
        }
    }

    /**
     * @notice Return all migrated bots that are staked
     */
    function migratedStakedBots(
        uint256[] memory botIds
    ) public view returns (bool[] memory) {
        unchecked {
            bool[] memory m = new bool[](botIds.length);
            for (uint256 t; t < botIds.length; ++t) {
                uint256 tokenId = botIds[t];
                m[t] =
                    _battleZone.ownerOf(address(_beepBoopBotNft), tokenId) ==
                    address(0) &&
                    _battleZone.ownerOf(address(_beepBoopBotV2Nft), tokenId) !=
                    address(0);
            }
            return m;
        }
    }
}