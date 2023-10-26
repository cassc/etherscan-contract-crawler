// contracts/HighTableVaultETH.sol
// SPDX-License-Identifier: BUSL
// Teahouse Finance

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./HighTableVault.sol";
import "./IHighTableVaultETH.sol";
import "./IWETH9.sol";

/// @title An investment vault for working with TeaVaultV2, accepting ETH as assets
/// @notice using WETH as the ERC20 token
/// @notice Addtional functions ending in ETH accepts and sends ETH
/// @notice There will be no ETH in vault, all accepted ETH are converted to WETH
/// @notice to make sure functions can be used interchangably without issues
/// @author Teahouse Finance
contract HighTableVaultETH is HighTableVault, IHighTableVaultETH, ReentrancyGuard {

    constructor(
        string memory _name,
        string memory _symbol,
        address _weth9,
        uint128 _priceNumerator,
        uint128 _priceDenominator,
        uint64 _startTimestamp,
        address _initialAdmin)
        HighTableVault(_name, _symbol, _weth9, _priceNumerator, _priceDenominator, _startTimestamp, _initialAdmin) {
        // check _weth9 is actually WETH
        if (keccak256(abi.encode(IWETH9(_weth9).symbol())) != keccak256(abi.encode("WETH"))) revert AssetNotWETH9();
    }

    receive() external payable {
        // only accepts ETH from self, weth9, and TeaVaultV2
        if (msg.sender != address(this) && 
            msg.sender != address(assetToken) &&
            msg.sender != address(fundConfig.teaVaultV2)) revert NotAcceptingETH();
    }

    /// @inheritdoc IHighTableVaultETH
    /// @dev Does not use nonReentrant because it can only be called from auditors
    function enterNextCycleETH(
        uint32 _cycleIndex,
        uint128 _fundValue,
        uint128 _depositLimit,
        uint128 _withdrawAmount,
        uint64 _cycleStartTimestamp,
        uint64 _fundingLockTimestamp,
        bool _closeFund) external override returns (uint256 platformFee, uint256 managerFee) {

        // withdraw from vault
        if (_withdrawAmount > 0) {
            fundConfig.teaVaultV2.withdrawETH(payable(this), _withdrawAmount);
            IWETH9(address(assetToken)).deposit{ value: _withdrawAmount }();
        }

        // permission checks are done in the internal function
        (platformFee, managerFee) = _internalEnterNextCycle(_cycleIndex, _fundValue, _depositLimit, _cycleStartTimestamp, _fundingLockTimestamp, _closeFund);

        // convert WETH to ETH
        uint256 converts = platformFee + managerFee;
        if (converts > 0) {
            IWETH9(address(assetToken)).withdraw(converts);

            if (platformFee > 0) {
                Address.sendValue(payable(feeConfig.platformVault), platformFee);
            }

            if (managerFee > 0) {
                Address.sendValue(payable(feeConfig.managerVault), managerFee);
            }
        }

        // check the remaining balance is enough for locked assets
        // and deposit extra balance back to the vault
        uint256 deposits = _internalCheckDeposits();
        if (deposits > 0) {
            IWETH9(address(assetToken)).withdraw(deposits);
            fundConfig.teaVaultV2.depositETH{ value: deposits }(deposits);
        }
    }

    /// @inheritdoc IHighTableVaultETH
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since there is no checking nor recording of amount of assets
    function depositToVaultETH(uint256 _value) external override {
        if (!hasRole(AUDITOR_ROLE, msg.sender)) revert OnlyAvailableToAuditors();

        uint256 balance = assetToken.balanceOf(address(this));
        if (balance - globalState.lockedAssets < _value) revert NotEnoughAssets();

        IWETH9(address(assetToken)).withdraw(_value);
        fundConfig.teaVaultV2.depositETH{ value: _value }(_value);

        emit DepositToVault(msg.sender, globalState.cycleIndex, address(fundConfig.teaVaultV2), _value);
    }

    /// @inheritdoc IHighTableVaultETH
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since there is no checking nor recording of amount of assets
    function withdrawFromVaultETH(uint256 _value) external override {
        if (!hasRole(AUDITOR_ROLE, msg.sender)) revert OnlyAvailableToAuditors();

        fundConfig.teaVaultV2.withdrawETH(payable(this), _value);
        IWETH9(address(assetToken)).deposit{ value: _value }();

        emit WithdrawFromVault(msg.sender, globalState.cycleIndex, address(fundConfig.teaVaultV2), _value);
    }       

    /// @inheritdoc IHighTableVaultETH
    function requestDepositETH(uint256 _assets, address _receiver) external override payable nonReentrant {
        if (msg.value != _assets) revert IncorrectETHAmount();
        IWETH9(address(assetToken)).deposit{ value: _assets }();
        _internalRequestDeposit(_assets, _receiver);
    }

    /// @inheritdoc IHighTableVaultETH
    function claimAndRequestDepositETH(uint256 _assets, address _receiver) external override payable nonReentrant returns (uint256 assets) {
        assets = _internalClaimOwedAssets(payable(address(this)));
        if (assets > 0) {
            IWETH9(address(assetToken)).withdraw(assets);
            Address.sendValue(payable(address(this)), assets);
        }

        if (msg.value + assets < _assets) revert IncorrectETHAmount();
        IWETH9(address(assetToken)).deposit{ value: _assets }();
        _internalRequestDeposit(_assets, _receiver);

        // refund
        uint256 remainingAssets = msg.value + assets - _assets;
        if (remainingAssets > 0) {
            Address.sendValue(payable(msg.sender), remainingAssets);
        }
    }

    /// @inheritdoc IHighTableVaultETH
    function cancelDepositETH(uint256 _assets, address payable _receiver) external override nonReentrant {
        _internalCancelDeposit(_assets, _receiver);
        IWETH9(address(assetToken)).withdraw(_assets);
        Address.sendValue(_receiver, _assets);
    }

    /// @inheritdoc IHighTableVaultETH
    function claimOwedAssetsETH(address payable _receiver) public override nonReentrant returns (uint256 assets) {
        assets = _internalClaimOwedAssets(_receiver);
        if (assets > 0) {
            IWETH9(address(assetToken)).withdraw(assets);
            Address.sendValue(_receiver, assets);
        }
    }

    /// @inheritdoc IHighTableVaultETH
    function claimOwedFundsETH(address payable _receiver) external override returns (uint256 assets, uint256 shares) {
        assets = claimOwedAssetsETH(_receiver);
        shares = claimOwedShares(_receiver);
    }    

    /// @inheritdoc IHighTableVaultETH
    function closePositionAndClaimETH(address payable _receiver) external override returns (uint256 assets) {
        claimOwedShares(msg.sender);
        uint256 shares = balanceOf(msg.sender);
        closePosition(shares, msg.sender);
        assets = claimOwedAssetsETH(_receiver);
    }
}