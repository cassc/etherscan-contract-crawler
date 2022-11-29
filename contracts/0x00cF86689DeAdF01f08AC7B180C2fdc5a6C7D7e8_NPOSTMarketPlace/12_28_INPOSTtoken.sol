// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface INPOSTtoken
{
    function burnIsAllowed(uint256 amount) external view returns(bool);

    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}