// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

contract SignatureBuilder {
  // default values for Signature Request
  bytes public constant DEFAULT_SIGNATURE_REQUEST_MESSAGE = "MESSAGE_SELECTED_BY_USER";
  bool public constant DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER = false;
  bytes public constant DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA = "";

  function build(bytes memory message) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes memory message,
    bool isSelectableByUser
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes memory message,
    bytes memory extraData
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes memory message,
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function build(bool isSelectableByUser) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: DEFAULT_SIGNATURE_REQUEST_MESSAGE,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: DEFAULT_SIGNATURE_REQUEST_MESSAGE,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function buildEmpty() external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: DEFAULT_SIGNATURE_REQUEST_MESSAGE,
        isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }
}