// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

interface IComet {
    function withdrawFrom(address src, address to, address asset, uint256 amount) external;

    function supplyTo(address dst, address asset, uint256 amount) external;

    function userNonce(address user) external returns (uint256);

    function allowBySig(
        address owner,
        address manager,
        bool isAllowed,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

}