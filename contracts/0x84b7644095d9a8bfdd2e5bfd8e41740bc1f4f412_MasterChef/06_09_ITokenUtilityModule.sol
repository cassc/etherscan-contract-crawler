// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// A benefits module for token/nft holders
// Externally calculate boosts and bonuses
interface ITokenUtilityModule {
    // Allow epoch length reduction
    function getEpochLength(
        address _sender,
        address _requestContract,
        uint256 amt,
        uint256 defaultVal
    ) external view returns (uint256);

    function getAdminFee(
        address _address,
        address _requestContract,
        uint256 amt,
        uint256 defaultVal
    ) external view returns (uint256);

    function getWithdrawalTotal(
        address _address,
        address _requestContract,
        uint256 amt,
        uint256 defaultVal
    ) external view returns (uint256);

    function getBoost(
        address _address,
        address _requestContract,
        uint256 amt,
        uint256 defaultVal
    ) external view returns (uint256);
}