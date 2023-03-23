/*
  Copyright 2019-2023 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "Governance.sol";

contract GenericGovernance is Governance {
    bytes32 immutable GOVERNANCE_INFO_TAG_HASH;

    constructor(string memory governanceContext) public {
        GOVERNANCE_INFO_TAG_HASH = keccak256(abi.encodePacked(governanceContext));
    }

    /*
      Returns the GovernanceInfoStruct associated with the governance tag.
    */
    function getGovernanceInfo() internal view override returns (GovernanceInfoStruct storage gub) {
        bytes32 location = GOVERNANCE_INFO_TAG_HASH;
        assembly {
            gub_slot := location
        }
    }

    function isGovernor(address user) external view returns (bool) {
        return _isGovernor(user);
    }

    function nominateNewGovernor(address newGovernor) external {
        _nominateNewGovernor(newGovernor);
    }

    function removeGovernor(address governorForRemoval) external {
        _removeGovernor(governorForRemoval);
    }

    function acceptGovernance() external {
        _acceptGovernance();
    }

    function cancelNomination() external {
        _cancelNomination();
    }
}