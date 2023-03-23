// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IFeesManager {
    function getFee(address _pool, uint256 _rawPayoutAmount)
        external
        view
        returns (uint256);

    function setPoolFees(
        address _pool,
        uint48 _feeRate,
        uint256 _type
    ) external;

    function getCurrentRate(address _pool) external view returns (uint48);
}