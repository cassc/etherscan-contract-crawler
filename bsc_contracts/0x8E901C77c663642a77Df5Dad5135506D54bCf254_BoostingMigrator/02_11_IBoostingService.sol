// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0 <0.9.0;

interface IBoostingService {

    function stakeFor(address owner, uint128 amount) external returns (uint128);

    function unstakeSharesWithAuthorization(
        address owner,
        uint128 shares,
        uint128 signedShares,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint128);

}