// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {Handz} from "./Handz.sol";

error NotAllowed();
error CallFailed(bytes data);

/**
  @title HandzSecurityProxyUpgradeable
 */
contract HandzSecurityProxyUpgradeable is OwnableUpgradeable {
  /**
    @notice Address of HANDZ token.
   */
  address public handz;

  /**
    @notice Whitelist mapping.
    @dev selector => caller => isAllowed.
   */
  mapping(bytes4 => mapping(address => bool)) public allowed;

  constructor() {
    _disableInitializers();
  }

  /**
    @param _handz - address of HANDZ token.
   */
  function initialize(address _handz) external initializer {
    __Ownable_init();
    __HandzSecurityProxy_init(_handz);
  }

  /**
    @notice Executes when `msg.data` is not empty.
   */
  fallback() external payable virtual {
    _fallback();
  }

  /**
    @notice Executes when `msg.data` is empty.
   */
  receive() external payable virtual {
    if (msg.value > 0) {
      payable(owner()).transfer(msg.value);
    }
  }

  /**
    @notice Set whitelist.
    @param selector - selector of function in HANDZ token. Example: `0xa9059cbb`.
    @param operator - address of the operator. Example: `0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045`.
    @param allow - is call for operator allowed. Example `true`.
   */
  function setAllowed(
    bytes4 selector,
    address operator,
    bool allow
  ) external onlyOwner {
    allowed[selector][operator] = allow;
  }

  /**
    @param _handz - address of HANDZ token.
   */
  // solhint-disable-next-line func-name-mixedcase
  function __HandzSecurityProxy_init(address _handz) internal onlyInitializing {
    handz = _handz;
  }

  /**
    @dev Internal fallback function for overriding.
   */
  function _fallback() internal virtual {
    _call(handz);
  }

  /**
    @notice Forwarding call to `destination` address. Check if allowed with `allowed` mapping by `msg.sig` value.
    @param destination - address of the target contract.
   */
  function _call(address destination) internal virtual {
    address sender = msg.sender;
    if (!allowed[msg.sig][sender] && sender != owner()) {
      revert NotAllowed();
    }

    // solhint-disable-next-line no-inline-assembly
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := call(gas(), destination, 0, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}