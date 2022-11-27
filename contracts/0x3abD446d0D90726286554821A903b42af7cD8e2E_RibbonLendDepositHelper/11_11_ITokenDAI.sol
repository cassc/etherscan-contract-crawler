// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ITokenDAI {
    function transfer(address dst, uint256 wad) external returns (bool);

    function approve(address usr, uint wad) external returns (bool);

    function balanceOf(address usr) external view returns (uint);

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}