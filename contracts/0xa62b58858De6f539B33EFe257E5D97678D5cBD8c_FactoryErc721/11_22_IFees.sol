// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

interface IFees {
    function getFee() external view returns(uint256);

    function getReceiver() external view returns(address);
}