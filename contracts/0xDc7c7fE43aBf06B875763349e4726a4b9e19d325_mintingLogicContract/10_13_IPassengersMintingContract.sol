//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
interface IPassengersMintingContract {
    function mint(address _to, uint256 _amount) external;
}