// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IBooster {
    function depositAll(uint256 _pid, bool _stake) external returns (bool);
    function withdrawAllAndUnwrap(bool) external;
    function withdraw(uint256 _pid, uint256 amount) external;
}