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

pragma solidity >=0.8.0 <0.9.0;

import "./MixinImmutables.sol";

abstract contract MixinStorage is MixinImmutables {
    // we use the constructor to assert that we are not using occupied storage slots
    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        assert(_GOVERNANCE_PARAMS_SLOT == bytes32(uint256(keccak256("governance.proxy.governanceparams")) - 1));
        assert(_NAME_SLOT == bytes32(uint256(keccak256("governance.proxy.name")) - 1));
        assert(_RECEIPT_SLOT == bytes32(uint256(keccak256("governance.proxy.user.receipt")) - 1));
        assert(_PROPOSAL_SLOT == bytes32(uint256(keccak256("governance.proxy.proposal")) - 1));
        assert(_PROPOSAL_COUNT_SLOT == bytes32(uint256(keccak256("governance.proxy.proposalcount")) - 1));
        assert(_PROPOSED_ACTION_SLOT == bytes32(uint256(keccak256("governance.proxy.proposedaction")) - 1));
    }

    function _governanceParameters() internal pure returns (GovernanceParameters storage s) {
        assembly {
            s.slot := _GOVERNANCE_PARAMS_SLOT
        }
    }

    struct AddressSlot {
        address value;
    }

    function _implementation() internal pure returns (AddressSlot storage s) {
        assembly {
            s.slot := _IMPLEMENTATION_SLOT
        }
    }

    struct StringSlot {
        string value;
    }

    function _name() internal pure returns (StringSlot storage s) {
        assembly {
            s.slot := _NAME_SLOT
        }
    }

    struct ParamsWrapper {
        GovernanceParameters governanceParameters;
    }

    function _paramsWrapper() internal pure returns (ParamsWrapper storage s) {
        assembly {
            s.slot := _GOVERNANCE_PARAMS_SLOT
        }
    }

    struct UintSlot {
        uint256 value;
    }

    function _proposalCount() internal pure returns (UintSlot storage s) {
        assembly {
            s.slot := _PROPOSAL_COUNT_SLOT
        }
    }

    struct ProposalByIndex {
        mapping(uint256 => Proposal) proposalById;
    }

    function _proposal() internal pure returns (ProposalByIndex storage s) {
        assembly {
            s.slot := _PROPOSAL_SLOT
        }
    }

    struct ActionByIndex {
        mapping(uint256 => mapping(uint256 => ProposedAction)) proposedActionbyIndex;
    }

    function _proposedAction() internal pure returns (ActionByIndex storage s) {
        assembly {
            s.slot := _PROPOSED_ACTION_SLOT
        }
    }

    struct UserReceipt {
        mapping(uint256 => mapping(address => Receipt)) userReceiptByProposal;
    }

    function _receipt() internal pure returns (UserReceipt storage s) {
        assembly {
            s.slot := _RECEIPT_SLOT
        }
    }
}