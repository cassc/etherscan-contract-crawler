// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IAdapter } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";

interface ILidoV1AdapterEvents {
    event NewLimit(uint256 _limit);
}

interface ILidoV1AdapterExceptions {
    error LimitIsOverException();
}

interface ILidoV1Adapter is
    IAdapter,
    ILidoV1AdapterEvents,
    ILidoV1AdapterExceptions
{
    /// @dev Set a new deposit limit
    /// @param _limit New value for the limit
    function setLimit(uint256 _limit) external;

    /// @dev Sends an order to stake ETH in Lido and receive stETH (sending WETH through the gateway)
    /// @param amount The amount of ETH to deposit in Lido
    /// @notice Since Gearbox only uses WETH as collateral, the amount has to be passed explicitly
    ///         unlike Lido. The referral address is always set to Gearbox treasury
    function submit(uint256 amount) external returns (uint256 result);

    /// @dev Sends an order to stake ETH in Lido and receive stETH (sending all available WETH through the gateway)
    function submitAll() external returns (uint256 result);

    //
    // Getters
    //

    /// @dev Get a number of shares corresponding to the specified ETH amount
    /// @param _ethAmount Amount of ETH to get shares for
    function getSharesByPooledEth(uint256 _ethAmount)
        external
        view
        returns (uint256);

    /// @dev Get amount of ETH corresponding to the specified number of shares
    /// @param _sharesAmount Number of shares to get ETH amount for
    function getPooledEthByShares(uint256 _sharesAmount)
        external
        view
        returns (uint256);

    /// @dev Get the total amount of ETH in Lido
    function getTotalPooledEther() external view returns (uint256);

    /// @dev Get the total amount of internal shares in the stETH contract
    function getTotalShares() external view returns (uint256);

    /// @dev Get the fee taken from stETH revenue, in bp
    function getFee() external view returns (uint16);

    /// @dev Get the number of internal stETH shares belonging to a particular account
    /// @param _account Address to get the shares for
    function sharesOf(address _account) external view returns (uint256);

    /// @dev Returns WETH (Lido adapter input token)
    function weth() external view returns (address);

    /// @dev Returns stETH (Lido adapter output token)
    function stETH() external view returns (address);

    //
    // ERC20 getters
    //

    /// @dev Get the ERC20 token name
    function name() external view returns (string memory);

    /// @dev Get the ERC20 token symbol
    function symbol() external view returns (string memory);

    /// @dev Get the ERC20 token decimals
    function decimals() external view returns (uint8);

    /// @dev Get ERC20 token balance for an account
    /// @param _account The address to get the balance for
    function balanceOf(address _account) external view returns (uint256);

    /// @dev Get ERC20 token allowance from owner to spender
    /// @param _owner The address allowing spending
    /// @param _spender The address allowed spending
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    /// @dev Get ERC20 token total supply
    function totalSupply() external view returns (uint256);
}