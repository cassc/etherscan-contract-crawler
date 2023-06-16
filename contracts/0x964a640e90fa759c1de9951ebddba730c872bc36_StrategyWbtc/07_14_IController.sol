pragma solidity 0.5.15;

interface IController {
    function vaults(address) external view returns (address);
    function withdraw(address, uint) external;
    function balanceOf(address) external view returns (uint);
    function underlyingBalanceOf(address) external view returns (uint);
    function earn(address, uint) external;
    function rewards() external view returns (address);
    function belRewards() external view returns (address);
    function paused() external view returns (bool);
}