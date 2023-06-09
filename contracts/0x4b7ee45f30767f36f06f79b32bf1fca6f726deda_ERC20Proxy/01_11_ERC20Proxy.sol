// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

import "./EIP2612Interface.sol";
import "./ERC20Interface.sol";
import "./ERC20ImplUpgradeable.sol";

/** @title  Public interface to ERC20 compliant token.
  *
  * @notice  This contract is a permanent entry point to an ERC20 compliant
  * system of contracts.
  *
  * @dev  This contract contains no business logic and instead
  * delegates to an instance of ERC20Impl. This contract also has no storage
  * that constitutes the operational state of the token. This contract is
  * upgradeable in the sense that the `custodian` can update the
  * `erc20Impl` address, thus redirecting the delegation of business logic.
  * The `custodian` is also authorized to pass custodianship.
  *
  * @author  Gemini Trust Company, LLC
  */
contract ERC20Proxy is ERC20Interface, ERC20ImplUpgradeable, EIP2612Interface {

    // MEMBERS
    /// @notice  Returns the name of the token.
    string public name; // TODO: use `constant` for mainnet

    /// @notice  Returns the symbol of the token.
    string public symbol; // TODO: use `constant` for mainnet

    /// @notice  Returns the number of decimals the token uses.
    uint8 immutable public decimals; // TODO: use `constant` (18) for mainnet

    // CONSTRUCTOR
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _custodian
    )
        ERC20ImplUpgradeable(_custodian)
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    // PUBLIC FUNCTIONS
    // (ERC20Interface)
    /** @notice  Returns the total token supply.
      *
      * @return  the total token supply.
      */
    function totalSupply() external override view returns (uint256) {
        return erc20Impl.totalSupply();
    }

    /** @notice  Returns the account balance of another account with address
      * `_owner`.
      *
      * @return  balance  the balance of account with address `_owner`.
      */
    function balanceOf(address _owner) external override view returns (uint256 balance) {
        return erc20Impl.balanceOf(_owner);
    }

    /** @dev Internal use only.
      */
    function emitTransfer(address _from, address _to, uint256 _value) external onlyImpl {
        emit Transfer(_from, _to, _value);
    }

    /** @notice  Transfers `_value` amount of tokens to address `_to`.
      *
      * @dev Will fire the `Transfer` event. Will revert if the `_from`
      * account balance does not have enough tokens to spend.
      *
      * @return  success  true if transfer completes.
      */
    function transfer(address _to, uint256 _value) external override returns (bool success) {
        return erc20Impl.transferWithSender(msg.sender, _to, _value);
    }

    /** @notice  Transfers `_value` amount of tokens from address `_from`
      * to address `_to`.
      *
      * @dev  Will fire the `Transfer` event. Will revert unless the `_from`
      * account has deliberately authorized the sender of the message
      * via some mechanism.
      *
      * @return  success  true if transfer completes.
      */
    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool success) {
        return erc20Impl.transferFromWithSender(msg.sender, _from, _to, _value);
    }

    /** @dev Internal use only.
      */
    function emitApproval(address _owner, address _spender, uint256 _value) external onlyImpl {
        emit Approval(_owner, _spender, _value);
    }

    /** @notice  Allows `_spender` to withdraw from your account multiple times,
      * up to the `_value` amount. If this function is called again it
      * overwrites the current allowance with _value.
      *
      * @dev  Will fire the `Approval` event.
      *
      * @return  success  true if approval completes.
      */
    function approve(address _spender, uint256 _value) external override returns (bool success) {
        return erc20Impl.approveWithSender(msg.sender, _spender, _value);
    }

    /** @notice Increases the amount `_spender` is allowed to withdraw from
      * your account.
      * This function is implemented to avoid the race condition in standard
      * ERC20 contracts surrounding the `approve` method.
      *
      * @dev  Will fire the `Approval` event. This function should be used instead of
      * `approve`.
      *
      * @return  success  true if approval completes.
      */
    function increaseApproval(address _spender, uint256 _addedValue) external returns (bool success) {
        return erc20Impl.increaseApprovalWithSender(msg.sender, _spender, _addedValue);
    }

    /** @notice  Decreases the amount `_spender` is allowed to withdraw from
      * your account. This function is implemented to avoid the race
      * condition in standard ERC20 contracts surrounding the `approve` method.
      *
      * @dev  Will fire the `Approval` event. This function should be used
      * instead of `approve`.
      *
      * @return  success  true if approval completes.
      */
    function decreaseApproval(address _spender, uint256 _subtractedValue) external returns (bool success) {
        return erc20Impl.decreaseApprovalWithSender(msg.sender, _spender, _subtractedValue);
    }

    /** @notice  Returns how much `_spender` is currently allowed to spend from
      * `_owner`'s balance.
      *
      * @return  remaining  the remaining allowance.
      */
    function allowance(address _owner, address _spender) external override view returns (uint256 remaining) {
        return erc20Impl.allowance(_owner, _spender);
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
      erc20Impl.permit(owner, spender, value, deadline, v, r, s);
    }
    function nonces(address owner) external override view returns (uint256) {
      return erc20Impl.nonces(owner);
    }
    function DOMAIN_SEPARATOR() external override view returns (bytes32) {
      return erc20Impl.DOMAIN_SEPARATOR();
    }

    function executeCallWithData(address contractAddress, bytes calldata callData) external {
        address implAddr = address(erc20Impl);
        require(msg.sender == implAddr, "unauthorized");
        require(contractAddress != implAddr, "disallowed");

        (bool success, bytes memory returnData) = contractAddress.call(callData);
        if (success) {
            emit CallWithDataSuccess(contractAddress, callData, returnData);
        } else {
            emit CallWithDataFailure(contractAddress, callData, returnData);
        }
    }

    event CallWithDataSuccess(address contractAddress, bytes callData, bytes returnData);
    event CallWithDataFailure(address contractAddress, bytes callData, bytes returnData);
}