// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUptownPanda is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function isInitialized() external view returns (bool);

    function initialize(
        address _minter,
        address _weth,
        address _upFarm,
        address _upEthFarm,
        address _wethFarm,
        address _wbtcFarm
    ) external;

    function getMinter() external view returns (address);

    function unlock() external;

    function getListingPriceMultiplier() external view returns (uint256);

    function uniswapPair() external view returns (address);
}