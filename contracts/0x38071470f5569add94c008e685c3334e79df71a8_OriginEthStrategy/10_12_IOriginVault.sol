// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOriginVault {
    function mint(address _asset, uint256 _amount, uint256 _minimumOusdAmount) external;
    function redeem(uint256 _amount, uint256 _minimumUnitAmount) external;
}