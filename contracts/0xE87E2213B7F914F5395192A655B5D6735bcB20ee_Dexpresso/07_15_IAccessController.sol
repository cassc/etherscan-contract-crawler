//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IAccessController {
    function isDaoMember(address _addr) external view returns (bool);
}