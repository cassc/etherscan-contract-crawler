// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./interfaces/IDispute.sol";
import "./interfaces/IEscrow.sol";

abstract contract Dispute is IDispute {
    // Dispute Status
    uint256 public currentDisputeId;
    uint8 constant INIT = 1;
    uint8 constant WAITING = 2;
    uint8 constant REVIEW = 3;
    uint8 constant WIN = 4;
    uint8 constant FAIL = 5;

    mapping(uint256 => Dispute) public disputes;

    function _dispute(address msgSender, uint256 _escrowId) internal {
        disputes[currentDisputeId + 1] = Dispute(
            _escrowId,
            0, // approvedCount
            0, // disapprovedCount
            INIT,// status
            0, // applied_agents_count
            block.timestamp,
            block.timestamp
        );
        currentDisputeId = currentDisputeId + 1;
        emit Disputed(msgSender, currentDisputeId, _escrowId);
    }

    function _setDispute(
        Dispute storage dispute,
        uint8 status,
        uint256 approvedCount,
        uint256 updatedAt
    ) internal {
        dispute.status = status;
        dispute.approvedCount += approvedCount;
        dispute.updatedAt = updatedAt;
    }
}