pragma solidity ^0.6.0;

interface IStrategy {
    function want() external view returns (address);

    function deposit() external;

    /// NOTE: must exclude any tokens used in the yield
    /// Controller role - withdraw should return to Controller
    function withdraw(address) external;

    /// Controller | Vault role - withdraw should always return to Vault
    function withdraw(uint256) external;

    function balanceOf() external view returns (uint256);

    function setController(address) external;

    function setWant(address) external;

    function getRewards() external;

    function claim(address) external returns (bool);
}