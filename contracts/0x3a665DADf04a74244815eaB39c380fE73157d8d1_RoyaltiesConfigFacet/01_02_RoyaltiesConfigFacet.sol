// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * RoyaltiesConfigLib authored by Sibling Labs
 * Version 0.1.0
 * 
 * This library is designed to work in conjunction with
 * RoyaltiesConfigFacet - it facilitates diamond storage and shared
 * functionality associated with RoyaltiesConfigFacet.
/**************************************************************/

library RoyaltiesConfigLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("royaltiesconfiglibrary.storage");

    struct state {
        uint256 royaltyBps;
        address payable royaltyRecipient;
    }

    /**
     * @dev Return stored state struct.
     */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    /**
     * @dev Returns royalty payee and amount for tokens in this
     *      collection. Adheres to EIP-2981.
     */
    function royaltyInfo(uint256, uint256 value) internal view returns (address, uint256) {
        state storage s = getState();
        return (s.royaltyRecipient, value * s.royaltyBps / 10000);
    }
}

/**************************************************************\
 * RoyaltiesConfigFacet authored by Sibling Labs
 * Version 0.1.0
/**************************************************************/

import { GlobalState } from "../libraries/GlobalState.sol";

contract RoyaltiesConfigFacet {
    /**
     * @dev Returns royalty payee and amount for tokens in this
     *      collection. Adheres to EIP-2981.
     */
    function royaltyInfo(uint256, uint256 value) external virtual view returns (address, uint256) {
        return RoyaltiesConfigLib.royaltyInfo(0, value);
    }

    /**
     * @dev Set royalty recipient and basis points.
     */
    function setRoyalties(address payable recipient, uint256 bps) external {
        GlobalState.requireCallerIsAdmin();

        RoyaltiesConfigLib.state storage s = RoyaltiesConfigLib.getState();
        s.royaltyRecipient = recipient;
        s.royaltyBps = bps;
    }
}