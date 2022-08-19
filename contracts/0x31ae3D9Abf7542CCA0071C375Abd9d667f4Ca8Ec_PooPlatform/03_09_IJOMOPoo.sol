pragma solidity ^0.8.2;

interface IJomoDao {
    function batchMint(address _to ,uint256 _amount) external;
    function batchMintById(address _to ,uint256 _serial, uint256 _amount) external;
}