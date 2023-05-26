// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract Gasc {
    function burnSerumForAddress(uint256 typeId, address burnTokenAddress)
        external
        virtual;

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        returns (uint256);
}