// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ERC20 } from 'solmate/src/tokens/ERC20.sol';
import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { ITokenDecimals } from './interfaces/ITokenDecimals.sol';
import { CallerGuard } from './CallerGuard.sol';
import { MultichainTokenBase } from './MultichainTokenBase.sol';
import './helpers/TransferHelper.sol' as TransferHelper;
import './Constants.sol' as Constants;

/**
 * @title VaultBase
 * @notice Base contract that implements the vault logic
 */
abstract contract VaultBase is MultichainTokenBase, ReentrancyGuard, CallerGuard {
    /**
     * @dev The vault asset address
     */
    address public immutable asset;

    /**
     * @dev The total vault token supply limit
     */
    uint256 public totalSupplyLimit;

    /**
     * @notice Emitted when the total supply limit is set
     * @param limit The total supply limit value
     */
    event SetTotalSupplyLimit(uint256 limit);

    /**
     * @notice Emitted when a deposit action is performed
     * @param caller The address of the depositor account
     * @param assetAmount The amount of the deposited asset
     */
    event Deposit(address indexed caller, uint256 assetAmount);

    /**
     * @notice Emitted when a withdrawal action is performed
     * @param caller The address of the withdrawal account
     * @param assetAmount The amount of the withdrawn asset
     */
    event Withdraw(address indexed caller, uint256 assetAmount);

    /**
     * @notice Emitted when the total supply limit is exceeded
     */
    error TotalSupplyLimitError();

    /**
     * @notice Emitted when a deposit is attempted with a zero amount
     */
    error ZeroAmountError();

    /**
     * @notice Initializes the VaultBase properties of descendant contracts
     * @param _asset The vault asset address
     * @param _name The ERC20 token name
     * @param _symbol The ERC20 token symbol
     * @param _depositAllowed The initial state of deposit availability
     */
    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        bool _depositAllowed
    ) MultichainTokenBase(_name, _symbol, ITokenDecimals(_asset).decimals(), false) {
        asset = _asset;

        _setTotalSupplyLimit(_depositAllowed ? Constants.INFINITY : 0);
    }

    /**
     * @notice Sets the total supply
     * @dev Decimals = vault token decimals = asset decimals
     * @param _limit The total supply limit value
     */
    function setTotalSupplyLimit(uint256 _limit) external onlyManager {
        _setTotalSupplyLimit(_limit);
    }

    /**
     * @notice Performs a deposit action. User deposits usdc/usdt for iusdc/iusdt used in Stablecoin Farm.
     * @param _assetAmount The amount of the deposited asset
     */
    function deposit(uint256 _assetAmount) external virtual whenNotPaused nonReentrant checkCaller {
        if (_assetAmount == 0) {
            revert ZeroAmountError();
        }

        if (totalSupply + _assetAmount > totalSupplyLimit) {
            revert TotalSupplyLimitError();
        }

        // Need to transfer before minting or ERC777s could reenter
        TransferHelper.safeTransferFrom(asset, msg.sender, address(this), _assetAmount);

        _mint(msg.sender, _assetAmount);

        emit Deposit(msg.sender, _assetAmount);
    }

    /**
     * @notice Performs a withdrawal action
     * @param _assetAmount The amount of the withdrawn asset
     */
    function withdraw(
        uint256 _assetAmount
    ) external virtual whenNotPaused nonReentrant checkCaller {
        _burn(msg.sender, _assetAmount);

        emit Withdraw(msg.sender, _assetAmount);

        TransferHelper.safeTransfer(asset, msg.sender, _assetAmount);
    }

    function _setTotalSupplyLimit(uint256 _limit) private {
        totalSupplyLimit = _limit;

        emit SetTotalSupplyLimit(_limit);
    }
}