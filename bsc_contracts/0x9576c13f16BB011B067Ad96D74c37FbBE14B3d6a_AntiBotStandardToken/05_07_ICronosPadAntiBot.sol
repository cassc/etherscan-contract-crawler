// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ICronosPadAntiBot {
    function setTokenOwner(address owner) external;

    function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
    ) external;
}