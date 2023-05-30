// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INewKinko{
    
    function joinOf(address erc721, address account) external view returns (uint256[] memory);
    function batchClaimRewards() external;
    function claimRewards(address erc721) external;
    function calcReward(address erc721, address account) external view returns(uint256);
    function calcRewardAll(address account) external view returns(uint256 reward);
    function join(address erc721, uint256[] calldata tokenIds) external;
    function leave(address erc721, uint256[] calldata tokenIds) external;
    function ownerOf(address erc721, address account, uint256 tokenId) external view returns(bool);
}