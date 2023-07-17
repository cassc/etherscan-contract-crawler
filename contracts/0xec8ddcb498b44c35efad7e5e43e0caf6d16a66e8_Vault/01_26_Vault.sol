// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ITokenBurn } from './interfaces/ITokenBurn.sol';
import { ITokenDecimals } from './interfaces/ITokenDecimals.sol';
import { AssetSpenderRole } from './roles/AssetSpenderRole.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { SystemVersionId } from './SystemVersionId.sol';
import { VaultBase } from './VaultBase.sol';
import { TokenBurnError } from './Errors.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './helpers/TransferHelper.sol' as TransferHelper;

/**
 * @title Vault
 * @notice The vault contract
 */
contract Vault is SystemVersionId, VaultBase, AssetSpenderRole, BalanceManagement {
    /**
     * @dev The variable token contract address, can be a zero address
     */
    address public variableToken;

    /**
     * @dev The state of variable token and balance actions
     */
    bool public variableRepaymentEnabled;

    /**
     * @notice Emitted when the state of variable token and balance actions is updated
     * @param variableRepaymentEnabled The state of variable token and balance actions
     */
    event SetVariableRepaymentEnabled(bool indexed variableRepaymentEnabled);

    /**
     * @notice Emitted when the variable token contract address is updated
     * @param variableToken The address of the variable token contract
     */
    event SetVariableToken(address indexed variableToken);

    /**
     * @notice Emitted when the variable tokens are redeemed for the vault asset
     * @param caller The address of the vault asset receiver account
     * @param amount The amount of redeemed variable tokens
     */
    event RedeemVariableToken(address indexed caller, uint256 amount);

    /**
     * @notice Emitted when the variable token decimals do not match the vault asset
     */
    error TokenDecimalsError();

    /**
     * @notice Emitted when a variable token or balance action is not allowed
     */
    error VariableRepaymentNotEnabledError();

    /**
     * @notice Emitted when setting the variable token is attempted while the token is already set
     */
    error VariableTokenAlreadySetError();

    /**
     * @notice Emitted when a variable token action is attempted while the token address is not set
     */
    error VariableTokenNotSetError();

    /**
     * @notice Deploys the VariableToken contract
     * @param _asset The vault asset address
     * @param _name The ERC20 token name
     * @param _symbol The ERC20 token symbol
     * @param _assetSpenders The addresses of initial asset spenders
     * @param _depositAllowed The initial state of deposit availability
     * @param _variableRepaymentEnabled The initial state of variable token and balance actions
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        address[] memory _assetSpenders,
        bool _depositAllowed,
        bool _variableRepaymentEnabled,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) VaultBase(_asset, _name, _symbol, _depositAllowed) {
        for (uint256 index; index < _assetSpenders.length; index++) {
            _setAssetSpender(_assetSpenders[index], true);
        }

        _setVariableRepaymentEnabled(_variableRepaymentEnabled);

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice Updates the Asset Spender role status for the account
     * @param _account The account address
     * @param _value The Asset Spender role status flag
     */
    function setAssetSpender(address _account, bool _value) external onlyManager {
        _setAssetSpender(_account, _value);
    }

    /**
     * @notice Sets the variable token contract address
     * @dev Setting the address value is possible only once
     * @param _variableToken The address of the variable token contract
     */
    function setVariableToken(address _variableToken) external onlyManager {
        if (variableToken != address(0)) {
            revert VariableTokenAlreadySetError();
        }

        AddressHelper.requireContract(_variableToken);

        if (ITokenDecimals(_variableToken).decimals() != decimals) {
            revert TokenDecimalsError();
        }

        variableToken = _variableToken;

        emit SetVariableToken(_variableToken);
    }

    /**
     * @notice Updates the state of variable token and balance actions
     * @param _variableRepaymentEnabled The state of variable token and balance actions
     */
    function setVariableRepaymentEnabled(bool _variableRepaymentEnabled) external onlyManager {
        _setVariableRepaymentEnabled(_variableRepaymentEnabled);
    }

    /**
     * @notice Requests the vault asset tokens
     * @param _amount The amount of the vault asset tokens
     * @param _to The address of the vault asset tokens receiver
     * @param _forVariableBalance True if the request is made for a variable balance repayment, otherwise false
     * @return assetAddress The address of the vault asset token
     */
    function requestAsset(
        uint256 _amount,
        address _to,
        bool _forVariableBalance
    ) external whenNotPaused onlyAssetSpender returns (address assetAddress) {
        if (_forVariableBalance && !variableRepaymentEnabled) {
            revert VariableRepaymentNotEnabledError();
        }

        TransferHelper.safeTransfer(asset, _to, _amount);

        return asset;
    }

    /**
     * @notice Redeems variable tokens for the vault asset
     * @param _amount The number of variable tokens to redeem
     */
    function redeemVariableToken(uint256 _amount) external whenNotPaused nonReentrant checkCaller {
        checkVariableTokenState();

        bool burnSuccess = ITokenBurn(variableToken).burn(msg.sender, _amount);

        if (!burnSuccess) {
            revert TokenBurnError();
        }

        emit RedeemVariableToken(msg.sender, _amount);

        TransferHelper.safeTransfer(asset, msg.sender, _amount);
    }

    /**
     * @notice Checks the status of the variable token and balance actions and the variable token address
     * @dev Throws an error if variable token actions are not allowed
     * @return The address of the variable token
     */
    function checkVariableTokenState() public view returns (address) {
        if (!variableRepaymentEnabled) {
            revert VariableRepaymentNotEnabledError();
        }

        if (variableToken == address(0)) {
            revert VariableTokenNotSetError();
        }

        return variableToken;
    }

    /**
     * @notice Getter of the reserved token flag
     * @dev Returns true if the provided token address is the address of the vault asset
     * @param _tokenAddress The address of the token
     * @return The reserved token flag
     */
    function isReservedToken(address _tokenAddress) public view override returns (bool) {
        return _tokenAddress == asset;
    }

    function _setVariableRepaymentEnabled(bool _variableRepaymentEnabled) private {
        variableRepaymentEnabled = _variableRepaymentEnabled;

        emit SetVariableRepaymentEnabled(_variableRepaymentEnabled);
    }
}