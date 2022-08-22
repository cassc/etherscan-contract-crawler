//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface ITrueFi {
    function join(uint256 amount) external;
    function liquidExit(uint256 amount) external;
    function liquidExitPenalty(uint256 amount) external view returns (uint256);
}