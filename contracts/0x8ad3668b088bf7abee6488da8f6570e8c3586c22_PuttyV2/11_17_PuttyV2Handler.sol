// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./PuttyV2.sol";

interface IPuttyV2Handler {
    function onFillOrder(PuttyV2.Order memory order, address taker, uint256[] memory floorAssetTokenIds) external;

    function onExercise(PuttyV2.Order memory order, address exerciser, uint256[] memory floorAssetTokenIds) external;
}

contract PuttyV2Handler {
    function onFillOrder(PuttyV2.Order memory order, address taker, uint256[] memory floorAssetTokenIds)
        public
        virtual
    {}

    function onExercise(PuttyV2.Order memory order, address exerciser, uint256[] memory floorAssetTokenIds)
        public
        virtual
    {}
}