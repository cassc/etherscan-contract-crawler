// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;

import "./Actors.sol";

contract Zombies is Actors {
    constructor(address router_, uint256 start_)
        Actors("UndeadsZombies", "UDZT", router_, start_)
    {}

    /**
    @notice Method that returns sub folder for placeholders metadata
    */
    function _getPlaceholderSubFolder()
        internal
        pure
        override
        returns (string memory)
    {
        return "zo";
    }
}