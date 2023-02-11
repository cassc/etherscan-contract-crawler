// SPDX-License-Identifier: Apache-2.0-or-later
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

pragma solidity 0.8.17;

import "./RigoblockGovernanceProxy.sol";
import "../IRigoblockGovernance.sol";
import "../interfaces/IRigoblockGovernanceFactory.sol";

// solhint-disable-next-line
contract RigoblockGovernanceFactory is IRigoblockGovernanceFactory {
    Parameters private _parameters;

    // @inheritdoc IRigoblockGovernanceFactory
    function createGovernance(
        address implementation,
        address governanceStrategy,
        uint256 proposalThreshold,
        uint256 quorumThreshold,
        IRigoblockGovernance.TimeType timeType,
        string calldata name
    ) external returns (address governance) {
        assert(_isContract(implementation));
        assert(_isContract(governanceStrategy));

        // we write to storage to allow proxy to read initialization parameters
        _parameters = Parameters({
            implementation: implementation,
            governanceStrategy: governanceStrategy,
            proposalThreshold: proposalThreshold,
            quorumThreshold: quorumThreshold,
            timeType: timeType,
            name: name
        });
        governance = address(new RigoblockGovernanceProxy{salt: keccak256(abi.encode(msg.sender, name))}());

        delete _parameters;
        emit GovernanceCreated(governance);
    }

    // @inheritdoc IRigoblockGovernanceFactory
    function parameters() external view override returns (Parameters memory) {
        return _parameters;
    }

    /// @dev Returns whether an address is a contract.
    /// @return Bool target address has code.
    function _isContract(address target) private view returns (bool) {
        return target.code.length > 0;
    }
}