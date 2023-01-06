// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface ISousChef {
    error BillCreated();
    error InvalidRestaurant();
    error InvalidKitchen();
    error Forbidden();

    event UpdateRestaurant(address indexed restaurant);
    event UpdateKitchen(address indexed kitchen);
    event CreateBill(uint256 indexed pid, address indexed bill);
    event Checkpoint();

    function fSushi() external view returns (address);

    function flashStrategyFactory() external view returns (address);

    function startWeek() external view returns (uint256);

    function restaurant() external view returns (address);

    function kitchen() external view returns (address);

    function getBill(uint256 pid) external view returns (address);

    function weeklyRewards(uint256 week) external view returns (uint256);

    function lastCheckpoint() external view returns (uint256);

    function predictBillAddress(uint256 pid) external view returns (address bill);

    function updateRestaurant(address _restaurant) external;

    function updateKitchen(address _kitchen) external;

    function createBill(uint256 pid) external returns (address strategy);

    function checkpoint() external;

    function mintFSushi(
        uint256 pid,
        address to,
        uint256 amount
    ) external;
}