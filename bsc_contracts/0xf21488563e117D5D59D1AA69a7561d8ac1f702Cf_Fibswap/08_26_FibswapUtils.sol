// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {IFibswap} from "../../interfaces/IFibswap.sol";
import {IWrapped} from "../../interfaces/IWrapped.sol";

import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable, AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library FibswapUtils {
  error FibswapUtils__handleIncomingAsset_notAmount();
  error FibswapUtils__handleIncomingAsset_ethWithErcTransfer();
  error FibswapUtils__transferAssetFromContract_notNative();

  /**
   * @notice Gets unique identifier from nonce + domain
   * @param _nonce - The nonce of the contract
   * @param _params - The call params of the transfer
   * @return The transfer id
   */
  function getTransferId(
    uint256 _nonce,
    address _sender,
    IFibswap.CallParams calldata _params,
    uint256 _amount
  ) internal pure returns (bytes32) {
    return keccak256(abi.encode(_nonce, _sender, _params, _amount));
  }

  /**
   * @notice Holds the logic to recover the signer from an encoded payload.
   * @dev Will hash and convert to an eth signed message.
   * @param _encoded The payload that was signed
   * @param _sig The signature you are recovering the signer from
   */
  function recoverSignature(bytes memory _encoded, bytes calldata _sig) internal pure returns (address) {
    // Recover
    return ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(keccak256(_encoded)), _sig);
  }

  /**
   * @notice Handles transferring funds from msg.sender to the Connext contract.
   * @dev If using the native asset, will automatically wrap
   * @param _assetId - The address to transfer
   * @param _assetAmount - The specified amount to transfer. May not be the
   * actual amount transferred (i.e. fee on transfer tokens)
   * @param _relayerFee - The fee amount in native asset included as part of the transaction that
   * should not be considered for the transfer amount.
   * @return The assetId of the transferred asset
   * @return The amount of the asset that was seen by the contract (may not be the specifiedAmount
   * if the token is a fee-on-transfer token)
   */
  function handleIncomingAsset(
    address _assetId,
    uint256 _assetAmount,
    uint256 _relayerFee,
    address _router,
    IWrapped _wrapper
  ) internal returns (address, uint256) {
    uint256 trueAmount = _assetAmount;

    if (_assetId == address(0)) {
      if (msg.value != _assetAmount + _relayerFee) revert FibswapUtils__handleIncomingAsset_notAmount();

      // When transferring native asset to the contract, always make sure that the
      // asset is properly wrapped
      _wrapper.deposit{value: _assetAmount}();
      _assetId = address(_wrapper);
    } else {
      if (msg.value != _relayerFee) revert FibswapUtils__handleIncomingAsset_ethWithErcTransfer();

      // Transfer asset to contract
      trueAmount = transferAssetToContract(_assetId, _assetAmount);
    }

    if (_relayerFee > 0) {
      AddressUpgradeable.sendValue(payable(_router), _relayerFee);
    }

    return (_assetId, trueAmount);
  }

  /**
   * @notice Handles transferring funds from msg.sender to the Connext contract.
   * @dev If using the native asset, will automatically wrap
   * @param _assetId - The address to transfer
   * @param _specifiedAmount - The specified amount to transfer. May not be the
   * actual amount transferred (i.e. fee on transfer tokens)
   * @return The amount of the asset that was seen by the contract (may not be the specifiedAmount
   * if the token is a fee-on-transfer token)
   */
  function transferAssetToContract(address _assetId, uint256 _specifiedAmount) internal returns (uint256) {
    // Validate correct amounts are transferred
    uint256 starting = IERC20Upgradeable(_assetId).balanceOf(address(this));
    SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(_assetId), msg.sender, address(this), _specifiedAmount);
    // Calculate the *actual* amount that was sent here
    uint256 trueAmount = IERC20Upgradeable(_assetId).balanceOf(address(this)) - starting;

    return trueAmount;
  }

  /**
   * @notice Handles transferring funds from msg.sender to the Connext contract.
   * @dev If using the native asset, will automatically unwrap
   * @param _assetId - The address to transfer
   * @param _to - The account that will receive the withdrawn funds
   * @param _amount - The amount to withdraw from contract
   * @param _wrapper - The address of the wrapper for the native asset on this domain
   * @return The address of asset received post-swap
   */
  function transferAssetFromContract(
    address _assetId,
    address _to,
    uint256 _amount,
    bool _convertToEth,
    IWrapped _wrapper
  ) internal returns (address) {
    // No native assets should ever be stored on this contract
    if (_assetId == address(0)) revert FibswapUtils__transferAssetFromContract_notNative();

    if (_assetId == address(_wrapper) && _convertToEth) {
      // If dealing with wrapped assets, make sure they are properly unwrapped
      // before sending from contract
      _wrapper.withdraw(_amount);
      AddressUpgradeable.sendValue(payable(_to), _amount);
      return address(0);
    } else {
      // Transfer ERC20 asset
      SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_assetId), _to, _amount);
      return _assetId;
    }
  }

  /**
   * @notice Swaps an adopted asset to the local (representation or canonical) nomad asset
   * @dev Will not swap if the asset passed in is the local asset
   * @param _asset - The address of the adopted asset to swap into the local asset
   * @param _amount - The amount of the adopted asset to swap
   * @return The amount of local asset received from swap
   */
  function swapToLocalAssetIfNeeded(
    address _local,
    address _asset,
    uint256 _amount,
    IFibswap.ExternalCall calldata _callParam
  ) internal returns (uint256) {
    if (_local == _asset) {
      return _amount;
    }

    // Approve pool
    SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(_asset), _callParam.to, _amount);

    // Swap the asset to the proper local asset
    IERC20Upgradeable Transit = IERC20Upgradeable(_local);

    uint256 balanceBefore = Transit.balanceOf(address(this));
    AddressUpgradeable.functionCall(_callParam.to, _callParam.data);

    uint256 balanceDif = Transit.balanceOf(address(this)) - balanceBefore;

    return balanceDif;
  }
}