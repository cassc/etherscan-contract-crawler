/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2021-2023 Backed Finance AG
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20WrapperUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./WhitelistControllerAggregator.sol";

error NonWhitelistedFromAddress (address from);
error NonWhitelistedToAddress (address to);

/**
 * @dev
 *
 * WrappedBackedToken contract, which is responsible for wrapping Backed tokens and adding functionality
 * of transferability limited to whitelisted wallets
 * 
 */
contract WrappedBackedToken is ERC20WrapperUpgradeable, ERC20PermitUpgradeable, PausableUpgradeable, OwnableUpgradeable  {
    /// @custom:oz-upgrades-unsafe-allow constructor

    WhitelistControllerAggregator public whitelistControllerAggregator;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes new instance of wrapped token
     * 
     * @param underlyingToken          The address of backed token to be wrapped
     */
    function initialize(address underlyingToken) initializer external {
        __ERC20_init(string.concat("Wrapped ", IERC20MetadataUpgradeable(underlyingToken).name()), string.concat("w", IERC20MetadataUpgradeable(underlyingToken).symbol()));
        __ERC20Wrapper_init(IERC20Upgradeable(underlyingToken));
        __ERC20Permit_init(string.concat("Wrapped ", IERC20MetadataUpgradeable(underlyingToken).name()));
        __Pausable_init();
        __Ownable_init();
    }

    /**
     * @dev See {ERC20WrapperUpgradeable-decimals}.
     */
    function decimals() public view virtual override(ERC20Upgradeable, ERC20WrapperUpgradeable) returns (uint8) {
        return ERC20WrapperUpgradeable.decimals();
    }

    /**
     * @dev Pauses all actions on the token. Callable only by the owner of the token.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all actions on the token. Callable only by the owner of the token.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Updates whitelist controller aggregator, that given contract uses.
     * Can be zero address, if we need to disable such checks.
     * Callable only by the owner of the token.
     * 
     * @param controllerAggregator     address of the new controller aggregator
     */
    function setWhitelistController(address controllerAggregator) external onlyOwner {
        whitelistControllerAggregator = WhitelistControllerAggregator(controllerAggregator);
    }

    /**
     * @dev
     *
     * BeforeTokenTransfer hook, which is responsible for enforcing rules related to
     * whitelisting, as well as pausing the contract.
     * 
     * It dissalows any movement to or from non whitelisted address, excluding zero address
     * in case of mint or redeem.     *
     * 
     * @param from     address of tokens sender
     * @param to       address of tokens recipient
     * @param amount   amount of tokens to be transferred
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        if(address(whitelistControllerAggregator) != address(0)) {
            if(from != address(0) && !whitelistControllerAggregator.isWhitelisted(from)) {
                revert NonWhitelistedFromAddress({
                    from: from
                });
            }
            if(to != address(0) && !whitelistControllerAggregator.isWhitelisted(to)) {
                revert NonWhitelistedToAddress({
                    to: to
                });
            }
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}