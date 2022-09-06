// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IMuffinHubBase {
    /// @notice Get the contract governance address
    function governance() external view returns (address);

    /// @notice         Get token balance of a user's internal account
    /// @param token    Token address
    /// @param accHash  keccek256 hash of (owner, accRefId), where accRefId is an arbitrary reference id from account owner
    /// @return balance Token balance in the account
    function accounts(address token, bytes32 accHash) external view returns (uint256 balance);

    /// @notice         Get token's reentrancy lock and accrued protocol fees
    /// @param token    Token address
    /// @return locked  1 if token is locked, otherwise unlocked
    /// @return protocolFeeAmt Amount of token accrued as protocol fee
    function tokens(address token) external view returns (uint8 locked, uint248 protocolFeeAmt);

    /// @notice         Get the addresses of the underlying tokens of a pool
    /// @param poolId   Pool id, i.e. keccek256 hash of (token0, token1)
    /// @return token0  Address of the pool's token0
    /// @return token1  Address of the pool's token1
    function underlyings(bytes32 poolId) external view returns (address token0, address token1);

    /// @notice Maximum number of tiers each pool can technically have. This number might vary in different networks.
    function maxNumOfTiers() external pure returns (uint256);
}