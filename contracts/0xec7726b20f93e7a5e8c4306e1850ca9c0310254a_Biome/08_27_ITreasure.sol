// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

abstract contract ITreasure {
    function burnForAddress(uint256 typeId, address burnTokenAddress, uint256 amount)
        external
        virtual;

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        returns (uint256);
}