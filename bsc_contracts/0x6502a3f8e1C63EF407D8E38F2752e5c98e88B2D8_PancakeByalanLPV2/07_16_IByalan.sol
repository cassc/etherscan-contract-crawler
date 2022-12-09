//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IByalanIsland.sol";
import "./ISailor.sol";

interface IByalan is IByalanIsland, ISailor {
    function want() external view returns (address);

    function beforeDeposit() external;

    function deposit() external;

    function withdraw(uint256) external;

    function balanceOf() external view returns (uint256);

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function balanceOfMasterChef() external view returns (uint256);

    function pendingRewardTokens() external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts);

    function harvest() external;

    function retireStrategy() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);
}