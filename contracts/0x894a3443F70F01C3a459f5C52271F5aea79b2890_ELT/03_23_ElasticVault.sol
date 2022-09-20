// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import './ElasticERC20.sol';
import './interfaces/IElasticVault.sol';
import './interfaces/IElasticVaultMigrator.sol';

/**
 * @dev OpenZeppelin v4.7.0 ERC4626 fork
 */
abstract contract ElasticVault is ElasticERC20, IElasticVault {
    using Math for uint256;

    IERC20Metadata private immutable _asset;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(IERC20Metadata asset_) {
        _asset = asset_;
    }

    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    function convertToNominal(uint256 value)
        public
        view
        virtual
        override
        returns (uint256 nominal)
    {
        return _convertToNominal(value, Math.Rounding.Down);
    }

    /** @dev See {IERC4262-convertToAssets}. */
    function convertToValue(uint256 nominal) public view virtual override returns (uint256 value) {
        return _convertFromNominal(nominal, Math.Rounding.Down);
    }

    /** @dev See {IERC4262-maxDeposit}. */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return _isVaultCollateralized() ? type(uint256).max : 0;
    }

    /** @dev See {IERC4262-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    function _maxWithdrawCached(address owner) public returns (uint256) {
        return _convertFromNominalCached(balanceOfNominal(owner), Math.Rounding.Down);
    }

    /** @dev See {IERC4262-previewDeposit}. */
    function previewDeposit(uint256 nominal) public view virtual override returns (uint256) {
        return _convertFromNominal(nominal, Math.Rounding.Down);
    }

    function _previewDepositCached(uint256 nominal) internal virtual returns (uint256) {
        return _convertFromNominalCached(nominal, Math.Rounding.Down);
    }

    /** @dev See {IERC4262-previewWithdraw}. */
    function previewWithdraw(uint256 value) public view virtual override returns (uint256) {
        (uint256 valueFee,) = _calcFee(_msgSender(), value, 0);
        return _convertToNominal(value - valueFee, Math.Rounding.Up);
    }

    function _previewWithdrawCached(uint256 value) internal virtual returns (uint256) {
        return _convertToNominalCached(value, Math.Rounding.Up);
    }

    /** @dev See {IERC4262-deposit}. */
    function deposit(uint256 nominal, address receiver)
        public
        virtual
        override
        returns (uint256)
    {
        require(nominal <= maxDeposit(receiver), 'ERC4626: deposit more than max');

        uint256 value = _previewDepositCached(nominal);
        _deposit(_msgSender(), receiver, value, nominal);

        return nominal;
    }

    /** @dev See {IERC4262-withdraw}. */
    function withdraw(
        uint256 value,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(value <= _maxWithdrawCached(owner), 'ERC4626: withdraw more than max');

        uint256 nominal = _previewWithdrawCached(value);
        _withdraw(_msgSender(), receiver, owner, value, nominal);

        return nominal;
    }

    function withdrawAll(
        address receiver,
        address owner
    ) public virtual returns (uint256) {
        uint256 nominal = balanceOfNominal(owner);
        uint256 value = _maxWithdrawCached(owner);
        _withdraw(_msgSender(), receiver, owner, value, nominal);

        return nominal;
    }

    function _beforeDeposit(
        address caller,
        address receiver,
        uint256 value,
        uint256 nominal
    ) internal virtual {}

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 value,
        uint256 nominal
    ) internal virtual {
        _beforeDeposit(caller, receiver, value, nominal);

        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // value are transfered and before the nominal are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(IERC20Metadata(asset()), caller, address(this), nominal);
        _mint(receiver, nominal, value);

        emit Deposit(caller, receiver, value, nominal);
    }

    function _beforeWithdraw(
        address caller,
        address receiver,
        address owner,
        uint256 value,
        uint256 nominal
    ) internal virtual {}

    function _calcFee(
        address,
        uint256,
        uint256
    ) internal view virtual returns(uint256 valueFee, uint256 nominalFee) {
        return (0,0);
    }

    function _withdrawFee(
        uint256 value,
        uint256 nominal
    ) internal virtual { }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 value,
        uint256 nominal
    ) internal virtual {
        _beforeWithdraw(caller, receiver, owner, value, nominal);

        if (caller != owner) {
            _spendAllowance(owner, caller, value);
        }

        (uint256 valueFee, uint256 nominalFee) = _calcFee(caller, value, nominal);
        nominal -= nominalFee;
        value -= valueFee;
        _withdrawFee(nominalFee, valueFee);

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // nominal are burned and after the value are transfered, which is a valid state.
        _burn(owner, nominal, value);
        SafeERC20.safeTransfer(IERC20Metadata(asset()), receiver, nominal);

        emit Withdraw(caller, receiver, owner, value, nominal, valueFee);
    }

    function _isVaultCollateralized() private view returns (bool) {
        return totalAssets() > 0 || totalSupplyNominal() == 0;
    }
}