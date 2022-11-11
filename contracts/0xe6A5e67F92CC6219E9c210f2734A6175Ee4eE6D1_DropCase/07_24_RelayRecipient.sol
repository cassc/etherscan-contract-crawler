// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@opengsn/gsn/contracts/BaseRelayRecipient.sol";

contract RelayRecipient is BaseRelayRecipient {
  function versionRecipient() external override view returns (string memory) {
    return "1.0.0-beta.1/charged-particles.relay.recipient";
  }
}