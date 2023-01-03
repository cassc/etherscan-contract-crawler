// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IBHCDAO {
    function getParent(address user) external view returns (address parent);

    function getChildren(address user)
        external
        view
        returns (address[] memory children);
}
