// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/ISyntheticToken.sol";
import "../interfaces/IPoolRegistry.sol";

abstract contract SyntheticTokenStorageV1 is ISyntheticToken {
    /**
     * @notice The name of the token
     */
    string public name;

    /**
     * @notice The symbol of the token
     */
    string public symbol;

    /**
     * @dev The amount of tokens owned by `account`
     */
    mapping(address => uint256) public balanceOf;

    /**
     * @dev The remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}
     */
    mapping(address => mapping(address => uint256)) public allowance;

    /**
     * @dev Amount of tokens in existence
     */
    uint256 public totalSupply;

    /**
     * @notice The supply cap
     */
    uint256 public maxTotalSupply;

    /**
     * @dev The Pool Registry
     */
    IPoolRegistry public poolRegistry;

    /**
     * @notice If true, disables msAsset minting globally
     */
    bool public isActive;

    /**
     * @notice The decimals of the token
     */
    uint8 public decimals;
}