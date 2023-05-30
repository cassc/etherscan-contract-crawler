// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;
import "../utils/Types.sol";
interface IGenericPool {

    error TransferFailed();

    function getPoolSettings() external view returns (GeneralPoolSettings memory);
    function deposit(
        uint256 _depositAmount
    ) external;
    function version() external pure returns (uint256);
}