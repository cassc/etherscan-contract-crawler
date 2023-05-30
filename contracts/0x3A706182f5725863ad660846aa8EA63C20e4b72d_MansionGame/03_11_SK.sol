// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Created By: Lorenzo
abstract contract SK {

    function burnKey(address userAddress, uint256 keyId, uint256 amount)
        external
        virtual;

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        returns (uint256);
}