// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IRobot {
    error ZeroAddress();
    error SameAddress();
    error NotRobotTxt();
    error NotTransferable();

    event RobotTxtUpdated(address indexed robotTxt);

    function mint(address to) external;
    function burn(address from) external;
    function setRobotTxt(address newRobotTxt) external;
}