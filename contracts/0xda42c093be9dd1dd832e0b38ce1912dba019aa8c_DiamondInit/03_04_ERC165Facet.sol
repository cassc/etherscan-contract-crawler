// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * ERC165Lib authored by Sibling Labs
 * Version 0.1.0
 * 
 * This library is designed to work in conjunction with
 * ERC165Facet - it facilitates diamond storage and shared
 * functionality associated with ERC165Facet.
/**************************************************************/

library ERC165Lib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("erc165.storage");

    struct state {
        mapping(bytes4 => bool) supportedInterfaces;
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
}

/**************************************************************\
 * ERC165Facet authored by Sibling Labs
 * Version 0.1.0
/**************************************************************/

import { GlobalState } from "../libraries/GlobalState.sol";

contract ERC165Facet {
    /**
    * @dev Called by marketplaces to query support for smart
    *      contract interfaces. Required by ERC165.
    */
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return ERC165Lib.getState().supportedInterfaces[_interfaceId];
    }

    /**
    * @dev Toggle support for bytes4 interface selector.
    */
    function toggleInterfaceSupport(bytes4 selector) external {
        GlobalState.requireCallerIsAdmin();

        if (ERC165Lib.getState().supportedInterfaces[selector]) {
            delete ERC165Lib.getState().supportedInterfaces[selector];
        } else {
            ERC165Lib.getState().supportedInterfaces[selector] = true;
        }
    }
}