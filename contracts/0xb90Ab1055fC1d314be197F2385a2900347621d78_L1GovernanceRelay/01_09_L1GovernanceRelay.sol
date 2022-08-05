// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.6.11;

import "../arbitrum/IInbox.sol";

import "./L1CrossDomainEnabled.sol";
import "../l2/L2GovernanceRelay.sol";

// Relay a message from L1 to L2GovernanceRelay
// Sending L1->L2 message on arbitrum requires ETH balance. That's why this contract can receive ether.
// Excessive ether can be reclaimed by governance by calling reclaim function.

contract L1GovernanceRelay is L1CrossDomainEnabled {
  // --- Auth ---
  mapping(address => uint256) public wards;

  function rely(address usr) external auth {
    wards[usr] = 1;
    emit Rely(usr);
  }

  function deny(address usr) external auth {
    wards[usr] = 0;
    emit Deny(usr);
  }

  modifier auth() {
    require(wards[msg.sender] == 1, "L1GovernanceRelay/not-authorized");
    _;
  }

  address public immutable l2GovernanceRelay;

  event Rely(address indexed usr);
  event Deny(address indexed usr);

  constructor(address _inbox, address _l2GovernanceRelay) public L1CrossDomainEnabled(_inbox) {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);

    l2GovernanceRelay = _l2GovernanceRelay;
  }

  // Allow contract to receive ether
  receive() external payable {}

  // Allow governance to reclaim stored ether
  function reclaim(address receiver, uint256 amount) external auth {
    (bool sent, ) = receiver.call{value: amount}("");
    require(sent, "L1GovernanceRelay/failed-to-send-ether");
  }

  // Forward a call to be repeated on L2
  function relay(
    address target,
    bytes calldata targetData,
    uint256 l1CallValue,
    uint256 maxGas,
    uint256 gasPriceBid,
    uint256 maxSubmissionCost
  ) external payable auth {
    bytes memory data = abi.encodeWithSelector(
      L2GovernanceRelay.relay.selector,
      target,
      targetData
    );

    sendTxToL2NoAliasing(
      l2GovernanceRelay,
      l2GovernanceRelay, // send any excess ether to the L2 counterpart
      l1CallValue,
      maxSubmissionCost,
      maxGas,
      gasPriceBid,
      data
    );
  }
}