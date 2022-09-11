// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

interface IStargatePool {

    // the token for the pool
    function token() external view returns (address);

    // the token for the pool
    function router() external view returns (address);

    // shared id between chains to represent same pool
    function poolId() external view returns (uint256);

    // the shared decimals (lowest common decimals between chains)
    function sharedDecimals() external view returns (uint256);

    // the decimals for the token
    function localDecimals() external view returns (uint256);
}