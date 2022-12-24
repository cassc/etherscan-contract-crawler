// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IApeCoinStaking {
    function pendingRewards(
        uint256 _poolId,
        address _address,
        uint256 _tokenId
    ) external view returns (uint256);

    function claimSelfApeCoin() external;

    function depositSelfApeCoin(uint256 _amount) external;

    function withdrawSelfApeCoin(uint256 _amount) external;

    function stakedTotal(address _address) external view returns (uint256);
}