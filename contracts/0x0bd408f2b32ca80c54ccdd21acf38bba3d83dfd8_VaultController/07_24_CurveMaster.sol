// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../_external/Ownable.sol";
import "./ICurveMaster.sol";
import "./ICurveSlave.sol";
import "../lending/IVaultController.sol";

/// @title Curve Master
/// @notice Curve master keeps a record of CurveSlave contracts and links it with an address
/// @dev all numbers should be scaled to 1e18. for instance, number 5e17 represents 50%
contract CurveMaster is ICurveMaster, Ownable {
  // mapping of token to address
  mapping(address => address) public _curves;

  address public _vaultControllerAddress;
  IVaultController private _VaultController;

  /// @notice gets the return value of curve labled token_address at x_value
  /// @param token_address the key to lookup the curve with in the mapping
  /// @param x_value the x value to pass to the slave
  /// @return y value of the curve
  function getValueAt(address token_address, int256 x_value) external view override returns (int256) {
    require(_curves[token_address] != address(0x0), "token not enabled");
    ICurveSlave curve = ICurveSlave(_curves[token_address]);
    int256 value = curve.valueAt(x_value);
    require(value != 0, "result must be nonzero");
    return value;
  }

  /// @notice set the VaultController addr in order to pay interest on curve setting
  /// @param vault_master_address address of vault master
  function setVaultController(address vault_master_address) external override onlyOwner {
    _vaultControllerAddress = vault_master_address;
    _VaultController = IVaultController(vault_master_address);
  }

  function vaultControllerAddress() external view override returns (address) {
    return _vaultControllerAddress;
  }

  ///@notice setting a new curve should pay interest
  function setCurve(address token_address, address curve_address) external override onlyOwner {
    if (address(_VaultController) != address(0)) {
      _VaultController.calculateInterest();
    }
    _curves[token_address] = curve_address;
  }

  /// @notice special function that does not calculate interest, used for deployment et al
  function forceSetCurve(address token_address, address curve_address) external override onlyOwner {
    _curves[token_address] = curve_address;
  }
}