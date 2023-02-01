pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT


interface IDNFT {
    function mint(address to, uint256 quantity) external;

    function burn(uint256[] calldata ids) external;

    function isOwnerOf(address owner, uint256[] calldata ids) external view returns(bool);
}