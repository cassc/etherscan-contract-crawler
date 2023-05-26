// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IAGStake {
    event StakedG2(address owner, uint256[] tokenIds, uint256 timestamp);
    event UnstakedG2(address owner, uint256[] tokenIds, uint256 timestamp);
    event StakedOG(
        address owner,
        uint256[] tokenIds,
        uint256[] counts,
        uint256 timestamp
    );
    event StakedForMint(
        address owner,
        uint256[] tokenIds,
        uint256[] counts,
        uint256 timestamp
    );
    event UnstakedOG(
        address owner,
        uint256[] tokenIds,
        uint256[] counts,
        uint256 timestamp
    );
    event Claimed(address owner, uint256 amount, uint256 timestamp);

    function ogAllocation(address _owner)
        external
        view
        returns (uint256 _allocation);

    function vaultG2(address, uint256) external view returns (uint256);

    function stakeG2(uint256[] calldata tokenIds) external;

    function updateOGAllocation(address _owner, uint256 _count) external;
}