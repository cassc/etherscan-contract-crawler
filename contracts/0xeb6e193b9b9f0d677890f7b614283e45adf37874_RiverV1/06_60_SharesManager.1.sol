//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../interfaces/components/ISharesManager.1.sol";

import "../libraries/LibSanitize.sol";

import "../state/river/Shares.sol";
import "../state/river/SharesPerOwner.sol";
import "../state/shared/ApprovalsPerOwner.sol";

/// @title Shares Manager (v1)
/// @author Kiln
/// @notice This contract handles the shares of the depositor and the ERC20 interface
abstract contract SharesManagerV1 is ISharesManagerV1 {
    /// @notice Internal hook triggered on the external transfer call
    /// @dev Must be overridden
    /// @param _from Address of the sender
    /// @param _to Address of the recipient
    function _onTransfer(address _from, address _to) internal view virtual;

    /// @notice Internal method to override to provide the total underlying asset balance
    /// @dev Must be overridden
    /// @return The total asset balance of the system
    function _assetBalance() internal view virtual returns (uint256);

    /// @notice Modifier used to ensure that the transfer is allowed by using the internal hook to perform internal checks
    /// @param _from Address of the sender
    /// @param _to Address of the recipient
    modifier transferAllowed(address _from, address _to) {
        _onTransfer(_from, _to);
        _;
    }

    /// @notice Modifier used to ensure the amount transferred is not 0
    /// @param _value Amount to check
    modifier isNotZero(uint256 _value) {
        if (_value == 0) {
            revert NullTransfer();
        }
        _;
    }

    /// @notice Modifier used to ensure that the sender has enough funds for the transfer
    /// @param _owner Address of the sender
    /// @param _value Value that is required to be sent
    modifier hasFunds(address _owner, uint256 _value) {
        if (_balanceOf(_owner) < _value) {
            revert BalanceTooLow();
        }
        _;
    }

    /// @inheritdoc ISharesManagerV1
    function name() external pure returns (string memory) {
        return "Liquid Staked ETH";
    }

    /// @inheritdoc ISharesManagerV1
    function symbol() external pure returns (string memory) {
        return "LsETH";
    }

    /// @inheritdoc ISharesManagerV1
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /// @inheritdoc ISharesManagerV1
    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }

    /// @inheritdoc ISharesManagerV1
    function totalUnderlyingSupply() external view returns (uint256) {
        return _assetBalance();
    }

    /// @inheritdoc ISharesManagerV1
    function balanceOf(address _owner) external view returns (uint256) {
        return _balanceOf(_owner);
    }

    /// @inheritdoc ISharesManagerV1
    function balanceOfUnderlying(address _owner) public view returns (uint256) {
        return _balanceFromShares(SharesPerOwner.get(_owner));
    }

    /// @inheritdoc ISharesManagerV1
    function underlyingBalanceFromShares(uint256 _shares) external view returns (uint256) {
        return _balanceFromShares(_shares);
    }

    /// @inheritdoc ISharesManagerV1
    function sharesFromUnderlyingBalance(uint256 _underlyingAssetAmount) external view returns (uint256) {
        return _sharesFromBalance(_underlyingAssetAmount);
    }

    /// @inheritdoc ISharesManagerV1
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return ApprovalsPerOwner.get(_owner, _spender);
    }

    /// @inheritdoc ISharesManagerV1
    function transfer(address _to, uint256 _value)
        external
        transferAllowed(msg.sender, _to)
        isNotZero(_value)
        hasFunds(msg.sender, _value)
        returns (bool)
    {
        if (_to == address(0)) {
            revert UnauthorizedTransfer(msg.sender, address(0));
        }
        return _transfer(msg.sender, _to, _value);
    }

    /// @inheritdoc ISharesManagerV1
    function transferFrom(address _from, address _to, uint256 _value)
        external
        transferAllowed(_from, _to)
        isNotZero(_value)
        hasFunds(_from, _value)
        returns (bool)
    {
        if (_to == address(0)) {
            revert UnauthorizedTransfer(_from, address(0));
        }
        _spendAllowance(_from, _value);
        return _transfer(_from, _to, _value);
    }

    /// @inheritdoc ISharesManagerV1
    function approve(address _spender, uint256 _value) external returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    /// @inheritdoc ISharesManagerV1
    function increaseAllowance(address _spender, uint256 _additionalValue) external returns (bool) {
        _approve(msg.sender, _spender, ApprovalsPerOwner.get(msg.sender, _spender) + _additionalValue);
        return true;
    }

    /// @inheritdoc ISharesManagerV1
    function decreaseAllowance(address _spender, uint256 _subtractableValue) external returns (bool) {
        _approve(msg.sender, _spender, ApprovalsPerOwner.get(msg.sender, _spender) - _subtractableValue);
        return true;
    }

    /// @notice Internal utility to spend the allowance of an account from the message sender
    /// @param _from Address owning the allowance
    /// @param _value Amount of allowance in shares to spend
    function _spendAllowance(address _from, uint256 _value) internal {
        uint256 currentAllowance = ApprovalsPerOwner.get(_from, msg.sender);
        if (currentAllowance < _value) {
            revert AllowanceTooLow(_from, msg.sender, currentAllowance, _value);
        }
        if (currentAllowance != type(uint256).max) {
            _approve(_from, msg.sender, currentAllowance - _value);
        }
    }

    /// @notice Internal utility to change the allowance of an owner to a spender
    /// @param _owner The owner of the shares
    /// @param _spender The allowed spender of the shares
    /// @param _value The new allowance value
    function _approve(address _owner, address _spender, uint256 _value) internal {
        LibSanitize._notZeroAddress(_owner);
        LibSanitize._notZeroAddress(_spender);
        ApprovalsPerOwner.set(_owner, _spender, _value);
        emit Approval(_owner, _spender, _value);
    }

    /// @notice Internal utility to retrieve the total supply of tokens
    /// @return The total supply
    function _totalSupply() internal view returns (uint256) {
        return Shares.get();
    }

    /// @notice Internal utility to perform an unchecked transfer
    /// @param _from Address sending the tokens
    /// @param _to Address receiving the tokens
    /// @param _value Amount of shares to be sent
    /// @return True if success
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        SharesPerOwner.set(_from, SharesPerOwner.get(_from) - _value);
        SharesPerOwner.set(_to, SharesPerOwner.get(_to) + _value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    /// @notice Internal utility to retrieve the underlying asset balance for the given shares
    /// @param _shares Amount of shares to convert
    /// @return The balance from the given shares
    function _balanceFromShares(uint256 _shares) internal view returns (uint256) {
        uint256 _totalSharesValue = Shares.get();

        if (_totalSharesValue == 0) {
            return 0;
        }

        return ((_shares * _assetBalance())) / _totalSharesValue;
    }

    /// @notice Internal utility to retrieve the shares count for a given underlying asset amount
    /// @param _balance Amount of underlying asset balance to convert
    /// @return The shares from the given balance
    function _sharesFromBalance(uint256 _balance) internal view returns (uint256) {
        uint256 _totalSharesValue = Shares.get();

        if (_totalSharesValue == 0) {
            return 0;
        }

        return (_balance * _totalSharesValue) / _assetBalance();
    }

    /// @notice Internal utility to mint shares for the specified user
    /// @dev This method assumes that funds received are now part of the _assetBalance()
    /// @param _owner Account that should receive the new shares
    /// @param _underlyingAssetValue Value of underlying asset received, to convert into shares
    /// @return sharesToMint The amnount of minted shares
    function _mintShares(address _owner, uint256 _underlyingAssetValue) internal returns (uint256 sharesToMint) {
        uint256 oldTotalAssetBalance = _assetBalance() - _underlyingAssetValue;

        if (oldTotalAssetBalance == 0) {
            sharesToMint = _underlyingAssetValue;
            _mintRawShares(_owner, _underlyingAssetValue);
        } else {
            sharesToMint = (_underlyingAssetValue * _totalSupply()) / oldTotalAssetBalance;
            _mintRawShares(_owner, sharesToMint);
        }
    }

    /// @notice Internal utility to retrieve the amount of shares per owner
    /// @param _owner Account to be checked
    /// @return The balance of the account in shares
    function _balanceOf(address _owner) internal view returns (uint256) {
        return SharesPerOwner.get(_owner);
    }

    /// @notice Internal utility to mint shares without any conversion, and emits a mint Transfer event
    /// @param _owner Account that should receive the new shares
    /// @param _value Amount of shares to mint
    function _mintRawShares(address _owner, uint256 _value) internal {
        _setTotalSupply(Shares.get() + _value);
        SharesPerOwner.set(_owner, SharesPerOwner.get(_owner) + _value);
        emit Transfer(address(0), _owner, _value);
    }

    /// @notice Internal utility to burn shares without any conversion, and emits a burn Transfer event
    /// @param _owner Account that should burn its shares
    /// @param _value Amount of shares to burn
    function _burnRawShares(address _owner, uint256 _value) internal {
        _setTotalSupply(Shares.get() - _value);
        SharesPerOwner.set(_owner, SharesPerOwner.get(_owner) - _value);
        emit Transfer(_owner, address(0), _value);
    }

    /// @notice Internal utility to set the total supply and emit an event
    /// @param newTotalSupply The new total supply value
    function _setTotalSupply(uint256 newTotalSupply) internal {
        Shares.set(newTotalSupply);
        emit SetTotalSupply(newTotalSupply);
    }
}