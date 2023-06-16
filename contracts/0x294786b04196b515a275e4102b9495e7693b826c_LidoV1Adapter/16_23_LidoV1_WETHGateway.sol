// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
pragma abicoder v1;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IstETH} from "../../integrations/lido/IstETH.sol";
import {IWETH} from "@gearbox-protocol/core-v2/contracts/interfaces/external/IWETH.sol";

// EXCEPTIONS
import {ZeroAddressException} from "@gearbox-protocol/core-v2/contracts/interfaces/IErrors.sol";

/// @title LidoV1 Gateway
/// @dev Implements logic allowing CA to interact with Lido contracts, which use native ETH
contract LidoV1Gateway {
    /// @dev The original Lido contract
    IstETH public immutable stETH;

    /// @dev The WETH contract
    IWETH public immutable weth;

    /// @dev Constructor
    /// @param _weth WETH token address
    /// @param _stETH Address of the Lido/stETH contract
    constructor(address _weth, address _stETH) {
        if (_weth == address(0) || _stETH == address(0)) {
            revert ZeroAddressException();
        }

        stETH = IstETH(_stETH);
        weth = IWETH(_weth);
    }

    /// @dev Implements logic allowing CA's to call `submit` in Lido, which uses native ETH
    /// - Transfers WETH from senders and unwraps into ETH
    /// - Submits ETH to Lido
    /// - Sends resulting stETH back to sender
    /// @param amount The amount of WETH to unwrap into ETH and submit
    /// @param _referral The address of the referrer
    function submit(uint256 amount, address _referral) external returns (uint256 value) {
        IERC20(address(weth)).transferFrom(msg.sender, address(this), amount);
        weth.withdraw(amount);

        value = stETH.submit{value: amount}(_referral);
        stETH.transfer(msg.sender, stETH.balanceOf(address(this)));
    }

    receive() external payable {}

    /// @dev Get a number of shares corresponding to the specified ETH amount
    /// @param _ethAmount Amount of ETH to get shares for
    function getSharesByPooledEth(uint256 _ethAmount) external view returns (uint256) {
        return stETH.getSharesByPooledEth(_ethAmount);
    }

    /// @dev Get amount of ETH corresponding to the specified number of shares
    /// @param _sharesAmount Number of shares to get ETH amount for
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256) {
        return stETH.getPooledEthByShares(_sharesAmount);
    }

    /// @dev Get the total amount of ETH in Lido
    function getTotalPooledEther() external view returns (uint256) {
        return stETH.getTotalPooledEther();
    }

    /// @dev Get the total amount of internal shares in the stETH contract
    function getTotalShares() external view returns (uint256) {
        return stETH.getTotalShares();
    }

    /// @dev Get the fee taken from stETH revenue, in bp
    function getFee() external view returns (uint16) {
        return stETH.getFee();
    }

    /// @dev Get the number of internal stETH shares belonging to a particular account
    /// @param _account Address to get the shares for
    function sharesOf(address _account) external view returns (uint256) {
        return stETH.sharesOf(_account);
    }

    /// @dev Get the ERC20 token name
    function name() external view returns (string memory) {
        return stETH.name();
    }

    /// @dev Get the ERC20 token symbol
    function symbol() external view returns (string memory) {
        return stETH.symbol();
    }

    /// @dev Get the ERC20 token decimals
    function decimals() external view returns (uint8) {
        return stETH.decimals();
    }

    /// @dev Get ERC20 token balance for an account
    /// @param _account The address to get the balance for
    function balanceOf(address _account) external view returns (uint256) {
        return stETH.balanceOf(_account);
    }

    /// @dev Get ERC20 token allowance from owner to spender
    /// @param _owner The address allowing spending
    /// @param _spender The address allowed spending
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return stETH.allowance(_owner, _spender);
    }

    /// @dev Get ERC20 token total supply
    function totalSupply() external view returns (uint256) {
        return stETH.totalSupply();
    }
}