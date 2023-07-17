// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IFarmV2 is IAccessControl {
    function setTokenAddress(address token_) external;

    function giveAway(address _address, uint256 stones) external;

    function farmed(address sender) external view returns (uint256);

    function farmedStart(address sender) external view returns (uint256);

    function payment(address buyer, uint256 amount) external returns (bool);

    function rewardedStones(address staker) external view returns (uint256);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function sell(
        uint256 stones,
        address from,
        address to
    ) external;
}