// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";

interface IFayreMembershipCard721 is IERC721EnumerableUpgradeable {
    function symbol() external view returns(string memory);

    function membershipCardsData(uint256 tokenId) external view returns(uint256 volume, uint256 nftPriceCap, uint256 freeMultiAssetSwapCount);

    function decreaseMembershipCardVolume(uint256 tokenId, uint256 amount) external;

    function decreaseMembershipCardFreeMultiAssetSwapCount(uint256 tokenId, uint256 amount) external;
}