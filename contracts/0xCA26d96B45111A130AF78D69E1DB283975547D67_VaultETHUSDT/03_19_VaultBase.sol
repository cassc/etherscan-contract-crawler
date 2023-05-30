// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UniERC20 } from "../Libraries/LibUniERC20.sol";

contract VaultControl is Ownable, Pausable {
  using SafeMath for uint256;
  using UniERC20 for IERC20;

  //Asset Struct
  struct VaultAssets {
    address collateralAsset;
    address borrowAsset;
    uint64 collateralID;
    uint64 borrowID;
  }

  //Vault Struct for Managed Assets
  VaultAssets public vAssets;

  //Pause Functions

  /**
   * @dev Emergency Call to stop all basic money flow functions.
   */
  function pause() public onlyOwner {
    _pause();
  }

  /**
   * @dev Emergency Call to stop all basic money flow functions.
   */
  function unpause() public onlyOwner {
    _pause();
  }
}

contract VaultBase is VaultControl {
  // Internal functions

  /**
   * @dev Executes deposit operation with delegatecall.
   * @param _amount: amount to be deposited
   * @param _provider: address of provider to be used
   */
  function _deposit(uint256 _amount, address _provider) internal {
    bytes memory data =
      abi.encodeWithSignature("deposit(address,uint256)", vAssets.collateralAsset, _amount);
    _execute(_provider, data);
  }

  /**
   * @dev Executes withdraw operation with delegatecall.
   * @param _amount: amount to be withdrawn
   * @param _provider: address of provider to be used
   */
  function _withdraw(uint256 _amount, address _provider) internal {
    bytes memory data =
      abi.encodeWithSignature("withdraw(address,uint256)", vAssets.collateralAsset, _amount);
    _execute(_provider, data);
  }

  /**
   * @dev Executes borrow operation with delegatecall.
   * @param _amount: amount to be borrowed
   * @param _provider: address of provider to be used
   */
  function _borrow(uint256 _amount, address _provider) internal {
    bytes memory data =
      abi.encodeWithSignature("borrow(address,uint256)", vAssets.borrowAsset, _amount);
    _execute(_provider, data);
  }

  /**
   * @dev Executes payback operation with delegatecall.
   * @param _amount: amount to be paid back
   * @param _provider: address of provider to be used
   */
  function _payback(uint256 _amount, address _provider) internal {
    bytes memory data =
      abi.encodeWithSignature("payback(address,uint256)", vAssets.borrowAsset, _amount);
    _execute(_provider, data);
  }

  /**
   * @dev Returns byte response of delegatcalls
   */
  function _execute(address _target, bytes memory _data)
    internal
    whenNotPaused
    returns (bytes memory response)
  {
    /* solhint-disable */
    assembly {
      let succeeded := delegatecall(sub(gas(), 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
      let size := returndatasize()

      response := mload(0x40)
      mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
      mstore(response, size)
      returndatacopy(add(response, 0x20), 0, size)

      switch iszero(succeeded)
        case 1 {
          // throw if delegatecall failed
          revert(add(response, 0x20), size)
        }
    }
    /* solhint-disable */
  }
}