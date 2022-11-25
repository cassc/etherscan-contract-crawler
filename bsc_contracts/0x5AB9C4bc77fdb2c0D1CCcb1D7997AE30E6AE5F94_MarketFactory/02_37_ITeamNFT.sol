pragma solidity ^0.8.0;

interface ITeamNFT {
    function poolMint(address receiver, uint256 teamId, uint256 amount) external;
    function poolBurn(address holder, uint256 teamId, uint256 amount) external;
    function setPoolManager(address manager) external;
}