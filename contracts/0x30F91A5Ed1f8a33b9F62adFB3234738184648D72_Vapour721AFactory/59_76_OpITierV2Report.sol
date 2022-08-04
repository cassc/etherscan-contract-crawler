// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import "../../../tier/ITierV2.sol";

/// @title OpITierV2Report
/// @notice Exposes `ITierV2.report` as an opcode.
library OpITierV2Report {
    function stackPops(uint256 operand_)
        internal
        pure
        returns (uint256 reportsLength_)
    {
        unchecked {
            reportsLength_ = operand_ + 2;
        }
    }

    // Stack the `report` returned by an `ITierV2` contract.
    function report(uint256 operand_, uint256 stackTopLocation_)
        internal
        view
        returns (uint256)
    {
        uint256 location_;
        uint256 tierContract_;
        uint256 account_;
        uint256[] memory context_;
        assembly {
            stackTopLocation_ := sub(stackTopLocation_, add(0x20, operand_))
            location_ := sub(stackTopLocation_, 0x20)
            tierContract_ := mload(location_)
            account_ := mload(stackTopLocation_)
            // we can reuse the account_ as the length for context_
            // and achieve a near zero-cost bytes array to send to `report`.
            mstore(stackTopLocation_, operand_)
            context_ := stackTopLocation_
        }
        uint256 report_ = ITierV2(address(uint160(tierContract_))).report(
            address(uint160(account_)),
            context_
        );
        assembly {
            mstore(location_, report_)
        }
        return stackTopLocation_;
    }
}