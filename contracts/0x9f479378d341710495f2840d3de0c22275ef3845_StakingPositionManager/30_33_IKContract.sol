// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IKContract {

    function MANAGE_ROLE() external pure returns (bytes32);
    function PAUSE_ROLE() external pure returns (bytes32);

    function pause() external;
    function unpause() external;
}