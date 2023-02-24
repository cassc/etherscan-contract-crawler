// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IPsionicFarmFactory {
    function PYLON_ROUTER() external view returns (address);
    function deployPool(
        IERC20Metadata _stakedToken,
        address[] memory rewardTokens,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser,
        uint256 _numberBlocksForUserLimit,
        address _admin)
    external returns (address psionicFarmAddress, address psionicVault);
    function updatePylonRouter(address _pylonRouter) external;
    function isPaused() external view returns (bool);
    function switchPause() external;
}