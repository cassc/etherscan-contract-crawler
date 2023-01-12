// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IPresaleSettings {
    function getBaseFee () external view returns (uint256);
    function getTokenFee () external view returns (uint256);
    function getEthAddress () external view returns (address payable);
    function getTokenAddress () external view returns (address payable);
    function getEthCreationFee () external view returns (uint256);
}