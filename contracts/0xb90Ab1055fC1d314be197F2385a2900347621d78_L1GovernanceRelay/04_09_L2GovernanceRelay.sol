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

import "./L2CrossDomainEnabled.sol";

// Receive xchain message from L1 counterpart and execute given spell

contract L2GovernanceRelay is L2CrossDomainEnabled {
  address public immutable l1GovernanceRelay;

  constructor(address _l1GovernanceRelay) public {
    l1GovernanceRelay = _l1GovernanceRelay;
  }

  // Allow contract to receive ether
  receive() external payable {}

  function relay(address target, bytes calldata targetData)
    external
    onlyL1Counterpart(l1GovernanceRelay)
  {
    (bool ok, ) = target.delegatecall(targetData);
    // note: even if a retryable call fails, it can be retried
    require(ok, "L2GovernanceRelay/delegatecall-error");
  }
}