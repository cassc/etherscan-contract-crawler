/*
 * Origin Protocol
 * https://originprotocol.com
 *
 * Released under the MIT license
 * SPDX-License-Identifier: MIT
 * https://github.com/OriginProtocol/nft-launchpad
 *
 * Copyright 2022 Origin Protocol, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.4;

import {IERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {PausableUpgradeable} from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import {SafeERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

import {Governable} from '../governance/Governable.sol';

interface IFeeVault {
    function controller() external view returns (address);

    function pause() external;

    function unpause() external;

    function sendETHRewards(address userAddress, uint256 amount)
        external
        returns (bool);

    function sendTokenRewards(
        address tokenAddress,
        address userAddress,
        uint256 amount
    ) external returns (bool);

    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount,
        address toAddress
    ) external returns (bool);

    function setController(address controllerAddress) external;
}

/**
 * @title Story FeeVault contract
 * @notice Contract to collect NFT sales profits and rewards to be distributed
 *      to OGN stakers.
 */
contract FeeVault is Initializable, Governable, PausableUpgradeable, IFeeVault {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public override controller;

    address private constant ASSET_ETH =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // @dev Rewards have been sent to the season
    event RewardsSent(
        address indexed asset,
        address indexed toAddress,
        uint256 amount
    );

    // @dev A new controller has been set
    event NewController(address controllerAddress);

    modifier onlyController() {
        require(_msgSender() == controller, 'FeeVault: Sender not controller');
        _;
    }

    /**
     * @param controllerAddress - Address for the account that will receive the
     *      rewards
     */
    function initialize(address controllerAddress) external initializer {
        __Pausable_init();
        // controller will probably be zero on initial deploy
        controller = controllerAddress;
    }

    ///
    /// Externals
    ///

    /**
     * @dev Send ETH rewards to a user. Can only be called by controller.
     * @param userAddress - address of the recipient of the ETH
     * @param amount - amount of ETH (in wei)
     */
    function sendETHRewards(address userAddress, uint256 amount)
        external
        override
        whenNotPaused
        onlyController
        returns (bool)
    {
        require(userAddress != address(0), 'FeeVault: ETH to black hole');
        require(amount > 0, 'FeeVault: Attempt to send 0 ETH');

        emit RewardsSent(ASSET_ETH, userAddress, amount);

        // transfer() does not send enough gas for a delegate call to an
        // empty receive() function.
        (bool success, ) = userAddress.call{value: amount, gas: 2800}('');

        // To align behavior with sendTokenRewards
        require(success, 'FeeVault: ETH transfer failed');

        return success;
    }

    /**
     * @dev Send token rewards to a user. Can only be called by controller.
     * @param tokenAddress - address of the token to send
     * @param userAddress - address of the recipient of the tokens
     * @param amount - amount of the token to send
     */
    function sendTokenRewards(
        address tokenAddress,
        address userAddress,
        uint256 amount
    ) external override whenNotPaused onlyController returns (bool) {
        require(userAddress != address(0), 'FeeVault: Token to black hole');
        require(amount > 0, 'FeeVault: Attempt to send 0');

        emit RewardsSent(tokenAddress, userAddress, amount);

        return _sendTokens(tokenAddress, userAddress, amount);
    }

    /**
     * @notice Recover ERC20 tokens sent to contract.  This can only be called
     *      by the governor.
     * @param tokenAddress - address of the token to recover
     * @param tokenAmount - amount of the token to recover
     * @param toAddress - address of the recipient of the tokens
     */
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount,
        address toAddress
    ) external override onlyGovernor whenNotPaused returns (bool) {
        return _sendTokens(tokenAddress, toAddress, tokenAmount);
    }

    /**
     * @notice Set series address
     */
    function setController(address controllerAddress)
        external
        override
        onlyGovernor
    {
        emit NewController(controllerAddress);
        controller = controllerAddress;
    }

    /**
     * @notice Pause all funds movement functionality
     */
    function pause() external override onlyGovernor {
        _pause();
    }

    /**
     * @notice Pause all funds movement functionality
     */
    function unpause() external override onlyGovernor {
        _unpause();
    }

    // @dev Allow this contract to receive ETH
    receive() external payable {}

    ///
    /// Internals
    ///

    function _sendTokens(
        address tokenAddress,
        address toAddress,
        uint256 amount
    ) internal returns (bool) {
        IERC20Upgradeable(tokenAddress).safeTransfer(toAddress, amount);
        return true;
    }
}