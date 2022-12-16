// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IDepositToken.sol";

abstract contract DepositTokenStorageV1 is IDepositToken {
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
     * @notice The name of the token
     */
    string public override name;

    /**
     * @notice The symbol of the token
     */
    string public override symbol;

    /**
     * @dev Amount of tokens in existence
     */
    uint256 public override totalSupply;

    /**
     * @notice The supply cap (in USD)
     */
    uint256 public override maxTotalSupply;

    /**
     * @notice Collateral factor for the deposit token
     * @dev Use 18 decimals (e.g. 0.66e18 = 66%)
     */
    uint256 public override collateralFactor;

    /**
     * @notice Deposit underlying asset (e.g. MET)
     */
    IERC20 public override underlying;

    /**
     * @notice If a collateral isn't active, it disables minting new tokens
     */
    bool public override isActive;

    /**
     * @notice The decimals of the token
     */
    uint8 public override decimals;
}