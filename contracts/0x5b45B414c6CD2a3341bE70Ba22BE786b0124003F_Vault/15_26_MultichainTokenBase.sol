// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ERC20 } from 'solmate/src/tokens/ERC20.sol';
import { BurnerRole } from './roles/BurnerRole.sol';
import { MinterRole } from './roles/MinterRole.sol';
import { MultichainRouterRole } from './roles/MultichainRouterRole.sol';
import { Pausable } from './Pausable.sol';
import { ZeroAddressError } from './Errors.sol';
import './Constants.sol' as Constants;

/**
 * @title MultichainTokenBase
 * @notice Base contract that implements the Multichain token logic
 */
abstract contract MultichainTokenBase is Pausable, ERC20, MultichainRouterRole {
    /**
     * @dev Anyswap ERC20 standard
     */
    address public immutable underlying;

    bool private immutable useExplicitAccess;

    /**
     * @notice Emitted when token burning is not allowed to the caller
     */
    error BurnAccessError();

    /**
     * @notice Emitted when the token allowance is not sufficient for burning
     */
    error BurnAllowanceError();

    /**
     * @notice Emitted when token minting is not allowed to the caller
     */
    error MintAccessError();

    /**
     * @notice Initializes the MultichainTokenBase properties of descendant contracts
     * @param _name The ERC20 token name
     * @param _symbol The ERC20 token symbol
     * @param _decimals The ERC20 token decimals
     * @param _useExplicitAccess The mint and burn actions access flag
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        bool _useExplicitAccess
    ) ERC20(_name, _symbol, _decimals) {
        underlying = address(0);
        useExplicitAccess = _useExplicitAccess;
    }

    /**
     * @notice Updates the Multichain Router role status for the account
     * @param _account The account address
     * @param _value The Multichain Router role status flag
     */
    function setMultichainRouter(address _account, bool _value) external onlyManager {
        _setMultichainRouter(_account, _value);
    }

    /**
     * @notice Mints tokens and assigns them to the account, increasing the total supply
     * @dev The mint function returns a boolean value, as required by the Anyswap ERC20 standard
     * @param _to The token receiver account address
     * @param _amount The number of tokens to mint
     * @return Token minting success status
     */
    function mint(address _to, uint256 _amount) external whenNotPaused returns (bool) {
        bool condition = isMultichainRouter(msg.sender) ||
            (useExplicitAccess && _isExplicitMinter());

        if (!condition) {
            revert MintAccessError();
        }

        _mint(_to, _amount);

        return true;
    }

    /**
     * @notice Burns tokens from the account, reducing the total supply
     * @dev The burn function returns a boolean value, as required by the Anyswap ERC20 standard
     * @param _from The token holder account address
     * @param _amount The number of tokens to burn
     * @return Token burning success status
     */
    function burn(address _from, uint256 _amount) external whenNotPaused returns (bool) {
        bool condition = isMultichainRouter(msg.sender) ||
            (useExplicitAccess && _isExplicitBurner());

        if (!condition) {
            revert BurnAccessError();
        }

        if (_from == address(0)) {
            revert ZeroAddressError();
        }

        uint256 allowed = allowance[_from][msg.sender];

        if (allowed < _amount) {
            revert BurnAllowanceError();
        }

        if (allowed != Constants.INFINITY) {
            // Cannot overflow because the allowed value
            // is greater or equal to the amount
            unchecked {
                allowance[_from][msg.sender] = allowed - _amount;
            }
        }

        _burn(_from, _amount);

        return true;
    }

    /**
     * @dev Override to add explicit minter access
     */
    function _isExplicitMinter() internal view virtual returns (bool) {
        return false;
    }

    /**
     * @dev Override to add explicit burner access
     */
    function _isExplicitBurner() internal view virtual returns (bool) {
        return false;
    }
}