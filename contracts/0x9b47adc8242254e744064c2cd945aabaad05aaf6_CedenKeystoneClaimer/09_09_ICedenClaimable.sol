// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICedenClaimable {
    function claim(address receiver, uint256[] calldata tokenIds) external;
}