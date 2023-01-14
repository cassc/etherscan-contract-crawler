// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

interface IRegistry {
    function getERC2981ReceiverAddress() external view returns (address);

    function getGhostMinterContract() external view returns (address);

    function getReferalRewardsContract() external view returns (address);

    function getDistributionManagerContract() external view returns (address);

    function getLiquidityRecipient() external view returns (address);

    function getDonationRecipient() external view returns (address);

    function getProfitRecipient() external view returns (address);

    function getContract(bytes32 slug) external view returns (address);

    function getShops() external view returns (bytes32[] memory);

    function getNfts() external view returns (bytes32[] memory);
}