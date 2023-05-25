// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISerum {
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    function burn(
        address account,
        uint256 amount
    ) external;

    function isApprovedForAll(address account, address operator)
        external
        returns (bool);
}