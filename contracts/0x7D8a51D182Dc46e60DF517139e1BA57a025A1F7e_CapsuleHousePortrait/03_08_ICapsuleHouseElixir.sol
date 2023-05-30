// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract ICapsuleHouseElixir {
    function burn(uint256 typeId, address burnTokenAddress)
        external
        virtual;
}