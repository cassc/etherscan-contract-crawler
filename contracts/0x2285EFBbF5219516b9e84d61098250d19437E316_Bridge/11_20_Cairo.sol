// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

library Cairo {
    uint256 public constant FIELD_PRIME =
        0x800000000000011000000000000000000000000000000000000000000000001;
    uint256 constant DEPOSIT_HANDLER =
        1285101517810983806491589552491143496277809242732141897358598292095611420389; // The selector of the "handle_deposit" l1_handler on L2.
    uint256 constant INDEX_UPDATE_HANDLER =
        309177621854413231845513563663819170511421561802461396722380275428414897390; // The selector of the "handle_index_update" l1_handler on L2.
    uint256 constant BRIDGE_REWARD_MESSAGE = 1;
    uint256 constant WITHDRAW_MESSAGE = 2;

    function toSplitUint(uint256 value)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 low = value & ((1 << 128) - 1);
        uint256 high = value >> 128;
        return (low, high);
    }

    function isValidL2Address(uint256 l2Address) internal pure returns (bool) {
        return (l2Address != 0) && (l2Address < FIELD_PRIME);
    }
}