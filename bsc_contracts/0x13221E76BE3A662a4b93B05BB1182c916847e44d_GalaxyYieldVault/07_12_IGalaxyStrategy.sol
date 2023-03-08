// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IERC20.sol";

interface IGalaxyStrategy {
    function vault() external view returns (address);
    function want() external view returns (IERC20);
    function beforeDeposit() external;
    function deposit() external;
    function withdraw(uint256) external;
    function balanceOf() external view returns (uint256);
    function balanceOfWant() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);
    function harvest() external;
    function retireStrategy() external;
    function panic() external;
    function pause() external;
    function unpause() external;
    function paused() external view returns (bool);
}