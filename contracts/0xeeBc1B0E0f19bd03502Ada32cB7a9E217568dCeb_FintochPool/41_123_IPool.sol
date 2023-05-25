// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an Fintoch Pool.
 **/
interface IPool {

    // An event sent when a redemption is triggered to the given address.
    event Redeemed(
        address from,
        address to,
        address erc20contract,
        uint256 transfer
    );

    // An event sent when a mint is triggered to the given address.
    event Mint(
        address from,
        address to,
        uint256 value
    );

    /**
    * @notice Use matching pool tokens to exchange for the source token
   * @param destination: the token receiver address.
   * @param value: the token value, in token minimum unit.
   */
    function redemption(
        address destination,
        uint256 value
    ) external;

    /**
     * @notice Mint matching pool tokens to destination, at the same time need to deduct the caller's source token
   * @param destination The address for receive the token
   * @param value The amount of token to mint
   */
    function mint(
        address destination,
        uint256 value
    ) external payable;

    function cancelReinvest(
        string calldata orderId
    ) external;

    function withdrawalIncome(
        uint64[] calldata recordIds
    ) external;

}