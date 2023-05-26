// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "./IToken.sol";
import "./TokenStorage.sol";

contract InterestProtocolToken is TokenDelegatorStorage, TokenEvents, ITokenDelegator {
  constructor(
    address account_,
    address owner_,
    address implementation_,
    uint256 initialSupply_
  ) {
    require(implementation_ != address(0), "TokenDelegator: invalid address");
    owner = owner_;
    delegateTo(implementation_, abi.encodeWithSignature("initialize(address,uint256)", account_, initialSupply_));

    implementation = implementation_;

    emit NewImplementation(address(0), implementation);
  }

  /**
   * @notice Called by the admin to update the implementation of the delegator
   * @param implementation_ The address of the new implementation for delegation
   */
  function _setImplementation(address implementation_) external override onlyOwner {
    require(implementation_ != address(0), "_setImplementation: invalid addr");

    address oldImplementation = implementation;
    implementation = implementation_;

    emit NewImplementation(oldImplementation, implementation);
  }

  /**
   * @notice Called by the admin to update the owner of the delegator
   * @param owner_ The address of the new owner
   */
  function _setOwner(address owner_) external override onlyOwner {
    owner = owner_;
  }

  /**
   * @notice Internal method to delegate execution to another contract
   * @dev It returns to the external caller whatever the implementation returns or forwards reverts
   * @param callee The contract to delegatecall
   * @param data The raw data to delegatecall
   */
  function delegateTo(address callee, bytes memory data) internal {
    //solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returnData) = callee.delegatecall(data);
    //solhint-disable-next-line no-inline-assembly
    assembly {
      if eq(success, 0) {
        revert(add(returnData, 0x20), returndatasize())
      }
    }
  }

  /**
   * @dev Delegates execution to an implementation contract.
   * It returns to the external caller whatever the implementation returns
   * or forwards reverts.
   */
  // solhint-disable-next-line no-complex-fallback
  fallback() external payable override {
    // delegate all other functions to current implementation
    //solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = implementation.delegatecall(msg.data);
    //solhint-disable-next-line no-inline-assembly
    assembly {
      let free_mem_ptr := mload(0x40)
      returndatacopy(free_mem_ptr, 0, returndatasize())
      switch success
      case 0 {
        revert(free_mem_ptr, returndatasize())
      }
      default {
        return(free_mem_ptr, returndatasize())
      }
    }
  }

  receive() external payable override {}
}