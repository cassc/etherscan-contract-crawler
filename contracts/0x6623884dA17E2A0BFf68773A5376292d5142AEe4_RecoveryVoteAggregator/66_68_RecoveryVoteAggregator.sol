// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TombRecoveryGovernor} from "./TombRecoveryGovernor.sol";

contract RecoveryVoteAggregator {
    function votes(address[] memory _governors, uint256[] memory _proposalIds, uint8[] memory _supports) public {
        for (uint256 i = 0; i < _governors.length; i++) {
            TombRecoveryGovernor(payable(_governors[i])).castVoteOnBehalfOf(_proposalIds[i], msg.sender, _supports[i]);
        }
    }

    function votesWithReason(
        address[] memory _governors,
        uint256[] memory _proposalIds,
        uint8[] memory _supports,
        string[] memory _reasons
    ) public {
        for (uint256 i = 0; i < _governors.length; i++) {
            TombRecoveryGovernor(payable(_governors[i])).castVoteOnBehalfOfWithReason(
                _proposalIds[i], msg.sender, _supports[i], _reasons[i]
            );
        }
    }

    function votesWithReasonAndParams(
        address[] memory _governors,
        uint256[] memory _proposalIds,
        uint8[] memory _supports,
        string[] memory _reasons,
        bytes[] memory _params
    ) public {
        for (uint256 i = 0; i < _governors.length; i++) {
            TombRecoveryGovernor(payable(_governors[i])).castVoteOnBehalfOfWithReasonAndParams(
                _proposalIds[i], msg.sender, _supports[i], _reasons[i], _params[i]
            );
        }
    }
}