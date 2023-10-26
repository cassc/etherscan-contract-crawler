//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IRiver.1.sol";
import "./interfaces/IWLSETH.1.sol";

import "./Initializable.sol";

import "./state/shared/RiverAddress.sol";
import "./state/shared/ApprovalsPerOwner.sol";
import "./state/wlseth/BalanceOf.sol";

/// @title Wrapped LsETH (v1)
/// @author Kiln
/// @notice This contract wraps the LsETH token into a rebase token, more suitable for some DeFi use-cases
///         like stable swaps.
contract WLSETHV1 is IWLSETHV1, Initializable, ReentrancyGuard {
    /// @notice Ensures that the value is not 0
    /// @param _value Value that must be > 0
    modifier isNotNull(uint256 _value) {
        if (_value == 0) {
            revert NullTransfer();
        }
        _;
    }

    /// @notice Ensures that the owner has enough funds
    /// @param _owner Owner of the balance to verify
    /// @param _value Minimum required value
    modifier hasFunds(address _owner, uint256 _value) {
        if (_balanceOf(_owner) < _value) {
            revert BalanceTooLow();
        }
        _;
    }

    /// @inheritdoc IWLSETHV1
    function initWLSETHV1(address _river) external init(0) {
        RiverAddress.set(_river);
        emit SetRiver(_river);
    }

    /// @inheritdoc IWLSETHV1
    function name() external pure returns (string memory) {
        return "Wrapped Liquid Staked ETH";
    }

    /// @inheritdoc IWLSETHV1
    function symbol() external pure returns (string memory) {
        return "wLsETH";
    }

    /// @inheritdoc IWLSETHV1
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /// @inheritdoc IWLSETHV1
    function totalSupply() external view returns (uint256) {
        return IRiverV1(payable(RiverAddress.get())).balanceOfUnderlying(address(this));
    }

    /// @inheritdoc IWLSETHV1
    function balanceOf(address _owner) external view returns (uint256) {
        return _balanceOf(_owner);
    }

    /// @inheritdoc IWLSETHV1
    function sharesOf(address _owner) external view returns (uint256) {
        return BalanceOf.get(_owner);
    }

    /// @inheritdoc IWLSETHV1
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return ApprovalsPerOwner.get(_owner, _spender);
    }

    /// @inheritdoc IWLSETHV1
    function transfer(address _to, uint256 _value)
        external
        isNotNull(_value)
        hasFunds(msg.sender, _value)
        returns (bool)
    {
        if (_to == address(0)) {
            revert UnauthorizedTransfer(msg.sender, address(0));
        }
        return _transfer(msg.sender, _to, _value);
    }

    /// @inheritdoc IWLSETHV1
    function transferFrom(address _from, address _to, uint256 _value)
        external
        isNotNull(_value)
        hasFunds(_from, _value)
        returns (bool)
    {
        if (_to == address(0)) {
            revert UnauthorizedTransfer(_from, address(0));
        }
        _spendAllowance(_from, _value);
        return _transfer(_from, _to, _value);
    }

    /// @inheritdoc IWLSETHV1
    function approve(address _spender, uint256 _value) external returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    /// @inheritdoc IWLSETHV1
    function increaseAllowance(address _spender, uint256 _additionalValue) external returns (bool) {
        _approve(msg.sender, _spender, ApprovalsPerOwner.get(msg.sender, _spender) + _additionalValue);
        return true;
    }

    /// @inheritdoc IWLSETHV1
    function decreaseAllowance(address _spender, uint256 _subtractableValue) external returns (bool) {
        _approve(msg.sender, _spender, ApprovalsPerOwner.get(msg.sender, _spender) - _subtractableValue);
        return true;
    }

    /// @inheritdoc IWLSETHV1
    function mint(address _recipient, uint256 _shares) external nonReentrant {
        BalanceOf.set(_recipient, BalanceOf.get(_recipient) + _shares);
        IRiverV1 river = IRiverV1(payable(RiverAddress.get()));
        if (!river.transferFrom(msg.sender, address(this), _shares)) {
            revert TokenTransferError();
        }
        emit Mint(_recipient, _shares);
        emit Transfer(address(0), _recipient, river.underlyingBalanceFromShares(_shares));
    }

    /// @inheritdoc IWLSETHV1
    function burn(address _recipient, uint256 _shares) external nonReentrant {
        uint256 shares = BalanceOf.get(msg.sender);
        if (_shares > shares) {
            revert BalanceTooLow();
        }
        BalanceOf.set(msg.sender, shares - _shares);
        IRiverV1 river = IRiverV1(payable(RiverAddress.get()));
        if (!river.transfer(_recipient, _shares)) {
            revert TokenTransferError();
        }
        emit Transfer(msg.sender, address(0), river.underlyingBalanceFromShares(_shares));
        emit Burn(_recipient, _shares);
    }

    /// @notice Internal utility to spend the allowance of an account from the message sender
    /// @param _from Address owning the allowance
    /// @param _value Amount of allowance to spend
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
    /// @param _owner The owner of the wrapped tokens
    /// @param _spender The allowed spender of the wrapped tokens
    /// @param _value The new allowance value
    function _approve(address _owner, address _spender, uint256 _value) internal {
        LibSanitize._notZeroAddress(_owner);
        LibSanitize._notZeroAddress(_spender);
        ApprovalsPerOwner.set(_owner, _spender, _value);
        emit Approval(_owner, _spender, _value);
    }

    /// @notice Internal utility to retrieve the amount of token per owner
    /// @param _owner Account to be checked
    /// @return The balance of the account
    function _balanceOf(address _owner) internal view returns (uint256) {
        return IRiverV1(payable(RiverAddress.get())).underlyingBalanceFromShares(BalanceOf.get(_owner));
    }

    /// @notice Internal utility to perform an unchecked transfer
    /// @param _from Address sending the tokens
    /// @param _to Address receiving the tokens
    /// @param _value Amount to be sent
    /// @return True if success
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        uint256 valueToShares = IRiverV1(payable(RiverAddress.get())).sharesFromUnderlyingBalance(_value);
        BalanceOf.set(_from, BalanceOf.get(_from) - valueToShares);
        BalanceOf.set(_to, BalanceOf.get(_to) + valueToShares);

        emit Transfer(_from, _to, _value);

        return true;
    }
}