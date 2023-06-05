// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/ISyntheticToken.sol";

abstract contract SyntheticTokenStorageV1 is ISyntheticToken {
    /**
     * @notice The name of the token
     */
    string public override name;

    /**
     * @notice The symbol of the token
     */
    string public override symbol;

    /**
     * @dev The amount of tokens owned by `account`
     */
    mapping(address => uint256) public override balanceOf;

    /**
     * @dev The remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}
     */
    mapping(address => mapping(address => uint256)) public override allowance;

    /**
     * @dev Amount of tokens in existence
     */
    uint256 public override totalSupply;

    /**
     * @notice The supply cap
     */
    uint256 public override maxTotalSupply;

    /**
     * @dev The Pool Registry
     */
    IPoolRegistry public override poolRegistry;

    /**
     * @notice If true, disables msAsset minting globally
     */
    bool public override isActive;

    /**
     * @notice The decimals of the token
     */
    uint8 public override decimals;
}