// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface ITSLVIPRegistery {
    function getInviters(address user)
        external
        view
        returns (address[] memory);

    function getInvited(address user)
        external
        view
        returns (address[] memory);
}