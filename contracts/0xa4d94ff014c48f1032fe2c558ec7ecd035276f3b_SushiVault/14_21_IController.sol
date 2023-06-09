pragma solidity ^0.6.0;

interface IController {
    function withdraw(address, uint256) external;

    function earn(address, uint256) external;

    function rewards() external view returns (address);

    function vaults(address) external view returns (address);

    function strategies(address) external view returns (address);

    function approvedStrategies(address, address) external view returns (bool);

    function setVault(address, address) external;

    function setStrategy(address, address) external;

    function converters(address, address) external view returns (address);

    function claim(address, address) external;

    function getRewardStrategy(address _strategy) external;
}