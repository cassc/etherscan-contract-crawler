// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPendingFeeDistributor {
    function distribute(
        uint256 _tokenId,
        uint256 _reward,
        bytes32[] memory proof
    ) external returns (uint256);

    function validProof(
        uint256 _tokenId,
        uint256 _reward,
        bytes32[] memory proof
    ) external view returns (bool);

    event HistoricRewardPaid(address to, uint256 tokenId, uint256 _reward);
}