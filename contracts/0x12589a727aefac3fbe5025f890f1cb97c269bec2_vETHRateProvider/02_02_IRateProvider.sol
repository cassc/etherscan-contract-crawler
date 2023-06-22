pragma solidity ^0.8.0;

// TODO: pull this from the monorepo
interface IRateProvider {
    function getRate() external view returns (uint256);
}