// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import "../../../tier/ITierV2.sol";

/// @title OpITierV2Report
/// @notice Exposes `ITierV2.reportTimeForTier` as an opcode.
library OpITierV2ReportTimeForTier {
    function stackPops(uint256 operand_)
        internal
        pure
        returns (uint256 reportsLength_)
    {
        unchecked {
            reportsLength_ = operand_ + 3;
        }
    }

    // Stack the `reportTimeForTier` returned by an `ITierV2` contract.
    function reportTimeForTier(uint256 operand_, uint256 stackTopLocation_)
        internal
        view
        returns (uint256)
    {
        uint256 location_;
        uint256 tierContract_;
        uint256 account_;
        uint256 tier_;
        uint256[] memory context_;
        assembly {
            stackTopLocation_ := sub(stackTopLocation_, add(0x20, operand_))
            location_ := sub(stackTopLocation_, 0x40)
            tierContract_ := mload(location_)
            account_ := mload(add(location_, 0x20))
            tier_ := mload(stackTopLocation_)
            // we can reuse the tier_ as the length for context_ and achieve a
            // near zero-cost bytes array to send to `reportTimeForTier`.
            mstore(stackTopLocation_, operand_)
            context_ := stackTopLocation_
        }
        uint256 reportTime_ = ITierV2(address(uint160(tierContract_)))
            .reportTimeForTier(address(uint160(account_)), tier_, context_);
        assembly {
            mstore(location_, reportTime_)
            stackTopLocation_ := add(location_, 0x20)
        }
        return stackTopLocation_;
    }
}