// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IRandomProvider {
    function isRequestOverdue(
        uint256 requestId
    ) external view returns (bool);

    function requestRandom(
        uint256 listingId
    ) external returns (uint256);
}