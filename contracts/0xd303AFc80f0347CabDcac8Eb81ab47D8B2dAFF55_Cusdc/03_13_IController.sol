// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IController {
    function totalAssets(bool fetch) external view returns (uint256);

    function deposit(uint256 _amount) external returns (uint256);

    function withdraw(uint256 _amount, address _receiver) external returns (uint256, uint256);

    function getRewardInfo()
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        );

    function vault() external view returns (address);

    function treasury() external view returns (address);

    function harvestFee() external view returns (uint256);

    function lastHarvest() external view returns (uint256);
}