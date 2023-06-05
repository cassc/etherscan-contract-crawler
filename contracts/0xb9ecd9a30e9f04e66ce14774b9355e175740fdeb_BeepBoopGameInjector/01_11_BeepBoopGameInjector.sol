// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "@oz/access/Ownable.sol";
import {IBeepBoopInjectable} from "../BeepBoopInjectable/IBeepBoopInjectable.sol";

contract BeepBoopGameInjector is Ownable {
    /// Injectable NFT
    IBeepBoopInjectable injectableNft;

    /// @dev Injectable and the bot id
    struct Injected {
        uint128 botId;
        uint128 injectableId;
    }

    /// @notice Round => Tokens
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Injected)))
        private _injectedTokens;

    /// @notice Keep track of number of injected bots
    mapping(uint256 => mapping(uint256 => uint256))
        private _injectedTokensCount;

    /// @notice Season
    uint256 private _currentSeason;

    constructor(address injectableNft_) {
        changeInjectableContract(injectableNft_);
    }

    /**
     * @notice Purchase a battery (limited using in-game)
     */
    function inject(
        uint256 round,
        uint256 botId,
        uint256[] calldata injectableIds
    ) public {
        require(injectableIds.length > 0);
        uint256 season = _currentSeason;
        for (uint256 t; t < injectableIds.length; ++t) {
            uint256 injectableId = injectableIds[t];
            // consume nft
            require(
                injectableNft.ownerOf(injectableId) == msg.sender,
                "Non-Owner"
            );
            injectableNft.burn(injectableId);
            // add injectable for this
            Injected memory injected = Injected({
                botId: uint128(botId),
                injectableId: uint128(injectableId)
            });
            uint256 index = _injectedTokensCount[season][round];
            _injectedTokens[season][round][index] = injected;
            ++_injectedTokensCount[season][round];
        }
    }

    /**
     * @notice Return the token ids with ammo
     */
    function getTokensWithInjectable(
        uint256 injectorType,
        uint256 roundFrom,
        uint256 roundTo
    ) public view returns (uint256[] memory) {
        unchecked {
            require(roundFrom <= roundTo);
            require(injectorType <= 2);
            uint256 season = _currentSeason;
            uint256 tokenLength;
            for (uint256 r = roundFrom; r <= roundTo; r++) {
                tokenLength += _injectedTokensCount[season][r];
            }
            uint256 tokenIdx;
            uint256[] memory tokenIds = new uint256[](tokenLength);
            for (uint256 r = roundFrom; r <= roundTo; r++) {
                for (uint256 i = 0; i < _injectedTokensCount[season][r]; ++i) {
                    Injected memory injected = _injectedTokens[season][r][i];
                    if (
                        injectorType ==
                        injectableNft.getInjectorType(
                            uint256(injected.injectableId)
                        )
                    ) {
                        tokenIds[tokenIdx++] = uint256(injected.botId);
                    }
                }
            }
            assembly {
                mstore(tokenIds, tokenIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @notice Get all injected bots, for all types
     */
    function getTokensWithAnyInjectable(
        uint256 roundFrom,
        uint256 roundTo
    )
        public
        view
        returns (
            uint256[] memory health,
            uint256[] memory damage,
            uint256[] memory defense
        )
    {
        health = getTokensWithInjectable(0, roundFrom, roundTo);
        damage = getTokensWithInjectable(1, roundFrom, roundTo);
        defense = getTokensWithInjectable(2, roundFrom, roundTo);
    }

    /**
     * @notice Get injectable type from token ids
     */
    function getInjectableTypes(
        uint256[] memory injectableIds
    ) public view returns (uint256[] memory) {
        uint256[] memory types = new uint256[](injectableIds.length);
        for (uint256 i; i < injectableIds.length; ++i) {
            types[i] = injectableNft.getInjectorType(injectableIds[i]);
        }
        return types;
    }

    /**
     * @notice Change the boop contract
     */
    function changeInjectableContract(address contract_) public onlyOwner {
        injectableNft = IBeepBoopInjectable(contract_);
    }

    /**
     * @notice Modify season
     */
    function setSeason(uint256 season) public onlyOwner {
        _currentSeason = season;
    }
}