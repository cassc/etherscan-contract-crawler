// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ControllerInterface {
    function mint(address to, uint256 amount) external returns (bool);

    function burn(address from, uint256 value) external returns (bool);

    function factoryPause(bool pause) external returns (bool);

    function isFactoryAdmin(address addr) external view returns (bool);

    function isCustodian(address addr) external view returns (bool);

    function isMerchant(address addr) external view returns (bool);

    function getToken() external view returns (address);
}