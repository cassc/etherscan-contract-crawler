// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPancakeProfile {
    /**
     * @dev Check the user's status for a given address
     */
    function getUserStatus(address _userAddress) external view returns (bool);

}