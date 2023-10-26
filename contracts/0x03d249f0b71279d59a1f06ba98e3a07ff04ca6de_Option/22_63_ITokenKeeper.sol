// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title ITokenKeeper interface
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @dev Interface for managing TokenKeeper contracts
 */
interface ITokenKeeper {
    /**
     * @notice Transfers a certain amount of an ERC20 token to a recipient.
     * @dev Transfers an ERC20 token from the TokenKeeper contract to a recipient. Only the contract owner or a whitelisted contract can call this function, and only if transfers are not frozen.
     * @param _tokenAddress The address of the ERC20 token to be transferred.
     * @param _receiver The address to receive the tokens.
     * @param _amount The amount of tokens to be transferred.
     */
    function transferToken(
        address _tokenAddress,
        address _receiver,
        uint256 _amount
    ) external;

    /**
     * @notice Approves a spender to spend a certain amount of an ERC20 token.
     * @dev Approves a spender to spend an ERC20 token on behalf of the TokenKeeper contract. Only the contract owner or a whitelisted contract can call this function, and only if transfers are not frozen.
     * @param _token The address of the ERC20 token.
     * @param _spender The address to be approved as a spender.
     * @param _approveAmount The amount of tokens the spender is approved to spend.
     */
    function approveToken(
        address _token,
        address _spender,
        uint256 _approveAmount
    ) external;
}