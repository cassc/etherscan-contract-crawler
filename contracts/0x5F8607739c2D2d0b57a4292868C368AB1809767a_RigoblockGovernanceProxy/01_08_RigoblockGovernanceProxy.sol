// SPDX-License-Identifier: Apache-2.0
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

import "../interfaces/IRigoblockGovernanceFactory.sol";

contract RigoblockGovernanceProxy {
    /// @notice Emitted when implementation written to proxy storage.
    /// @dev Emitted also at first variable initialization.
    /// @param newImplementation Address of the new implementation.
    event Upgraded(address indexed newImplementation);

    // implementation slot is used to store implementation address, a contract which implements the governance logic.
    // Reduced deployment cost by using internal variable.
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @notice Sets address of implementation contract.
    constructor() payable {
        // store implementation address in implementation slot value
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));

        // we retrieve the set implementation from the factory storage
        address implementation = IRigoblockGovernanceFactory(msg.sender).parameters().implementation;

        // we store the implementation address
        _getImplementation().implementation = implementation;
        emit Upgraded(implementation);

        // initialize governance
        // abi.encodeWithSelector(IRigoblockGovernance.initializeGovernance.selector)
        (, bytes memory returnData) = implementation.delegatecall(abi.encodeWithSelector(0xe9134903));

        // we must assert initialization didn't fail, otherwise it could fail silently and still deploy the governance.
        assert(returnData.length == 0);
    }

    /* solhint-disable no-complex-fallback */
    /// @notice Fallback function forwards all transactions and returns all received return data.
    fallback() external payable {
        address implementation = _getImplementation().implementation;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    /// @notice Allows this contract to receive ether.
    receive() external payable {}

    /* solhint-enable no-complex-fallback */

    /// @notice Implementation slot is accessed directly.
    /// @dev Saves gas compared to using storage slot library.
    /// @param implementation Address of the implementation.
    struct ImplementationSlot {
        address implementation;
    }

    /// @notice Method to read/write from/to implementation slot.
    /// @return s Storage slot of the governance implementation.
    function _getImplementation() private pure returns (ImplementationSlot storage s) {
        assembly {
            s.slot := _IMPLEMENTATION_SLOT
        }
    }
}