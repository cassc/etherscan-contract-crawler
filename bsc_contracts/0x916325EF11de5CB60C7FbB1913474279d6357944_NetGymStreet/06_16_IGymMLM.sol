// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface IGymMLM {
    function idToAddress(uint256) external view returns (address);

    function addressToId(address) external view returns (uint256);

    function userToReferrer(address) external view returns (address);

    function addGymMLMNFT(address, uint256) external;

    function getReferrals(address, uint256) external view returns (address[] memory);
}