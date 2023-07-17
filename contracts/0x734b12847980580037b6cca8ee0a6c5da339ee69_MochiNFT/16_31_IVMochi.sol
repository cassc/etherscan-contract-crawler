// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IVMochi {
    function locked(address _user) external view returns(int128, uint256);
    function depositFor(address _user, uint256 _amount) external;
    function balanceOf(address _user) external view returns(uint256);
}