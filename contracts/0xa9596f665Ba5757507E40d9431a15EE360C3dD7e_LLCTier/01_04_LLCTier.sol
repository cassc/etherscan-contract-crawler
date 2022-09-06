//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./interfaces/ILLCTier.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LLCTier is Ownable, ILLCTier {
    uint256 public constant override LEGENDARY_RARITY = 1;
    uint256 public constant override SUPER_RARE_RARITY = 2;
    uint256 public constant override RARE_RARITY = 3;

    uint256 public legendaryLLCs;
    uint256 public superRareLLCs;
    uint256 public rareLLCs;

    mapping(uint256 => uint256) public override LLCRarities;

    function _registerLLCRarity(uint256[] memory _tokenIds, uint256 _rarity)
        private
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            LLCRarities[_tokenIds[i]] = _rarity;
        }
    }

    function registerLegendaryLLCs(uint256[] memory _tokenIds)
        external
        onlyOwner
    {
        _registerLLCRarity(_tokenIds, LEGENDARY_RARITY);
        legendaryLLCs += _tokenIds.length;
    }

    function registerSuperRareLLCs(uint256[] memory _tokenIds)
        external
        onlyOwner
    {
        _registerLLCRarity(_tokenIds, SUPER_RARE_RARITY);
        superRareLLCs += _tokenIds.length;
    }

    function registerRareLLCs(uint256[] memory _tokenIds) external onlyOwner {
        _registerLLCRarity(_tokenIds, RARE_RARITY);
        rareLLCs += _tokenIds.length;
    }

    function resetRarity(uint256[] memory _tokenIds) external onlyOwner {
        for (uint256 i=0; i<_tokenIds.length; i++) {
            uint256 prevRarity = LLCRarities[_tokenIds[i]];
            if (prevRarity == LEGENDARY_RARITY) {
                legendaryLLCs --;
            } else if (prevRarity == SUPER_RARE_RARITY) {
                superRareLLCs --;
            } else if (prevRarity == RARE_RARITY) {
                rareLLCs --;
            }

            LLCRarities[_tokenIds[i]] = 0;
        }
    }
}