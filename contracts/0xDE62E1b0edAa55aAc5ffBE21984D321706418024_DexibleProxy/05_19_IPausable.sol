//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IPausable {

    event Paused();
    event Resumed();

    function pause() external;
    function resume() external;
}