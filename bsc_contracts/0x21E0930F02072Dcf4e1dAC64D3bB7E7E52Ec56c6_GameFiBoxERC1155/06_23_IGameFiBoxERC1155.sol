// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "../../../type/ITokenTypes.sol";
import "../basic/IGameFiTokenERC1155.sol";

interface IGameFiBoxERC1155 is ITokenTypes, IGameFiTokenERC1155 {
    struct RewardSet {
        TokenStandart standart;
        address token;
        uint256 reiterations;
        uint256[] tokenIds;
        uint256[] amounts;
        uint256[] probabilities;
    }

    event SetHookContract(address indexed owner, address indexed hookedContract, uint256 timestamp);
    event SetupRewardSet(address indexed sender, uint256 indexed tokenId, RewardSet[] rewardSet, uint256 timestamp);
    event OpenBox(address indexed owner, uint256 indexed tokenId, uint256 amount, uint256 timestamp);
    event BoxReward(address indexed target, address indexed token, uint256 indexed tokenId, uint256 amount, uint256 timestamp);

    function setHookContract(address newHookContract) external;

    function setupRewardSet(uint256 tokenId, RewardSet[] memory rewardSet) external;

    function openBox(uint256 tokenId, uint256 amount) external;

    function getBoxRewards(uint256 tokenId) external view returns(RewardSet[] memory rewardSet);
}