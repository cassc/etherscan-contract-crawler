// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IGaslessListingManager {
    function isApprovedForAll(address owner_, address operator_) external view returns (bool);

    function setApprovalForAll(address operator_, bool approved_) external;
}