pragma solidity ^0.8.0;

interface IPaymentUtils {
    function getAllHoldersAddresses() external view returns (address[] memory);

    function getTotalAmountOfHouseTokens() external view returns (uint256);

    function createPaymentSnapshot() external;

    function lastPaymentSnapshot() external view returns (uint256);
}