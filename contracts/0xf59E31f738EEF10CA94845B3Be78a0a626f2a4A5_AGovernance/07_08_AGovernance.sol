// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2023 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

// solhint-disable-next-line
pragma solidity =0.8.17;

import "./interfaces/IAGovernance.sol";

/// @title Governance adapter - A helper contract for interacting with governance.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract AGovernance is IAGovernance {
    address private immutable _governance;

    constructor(address governance) {
        _governance = governance;
    }

    /// @inheritdoc IAGovernance
    function propose(IRigoblockGovernance.ProposedAction[] memory actions, string memory description)
        external
        override
    {
        IRigoblockGovernance(_getGovernance()).propose(actions, description);
    }

    /// @inheritdoc IAGovernance
    function castVote(uint256 proposalId, IRigoblockGovernance.VoteType voteType) external override {
        IRigoblockGovernance(_getGovernance()).castVote(proposalId, voteType);
    }

    /// @inheritdoc IAGovernance
    function execute(uint256 proposalId) external override {
        IRigoblockGovernance(_getGovernance()).execute(proposalId);
    }

    function _getGovernance() private view returns (address) {
        return _governance;
    }
}