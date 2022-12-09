//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IAllocKafra {
    function MAX_ALLOCATION() external view returns (uint16);

    function limitAllocation() external view returns (uint16);

    function canAllocate(
        uint256 _amount,
        uint256 _balanceOfWant,
        uint256 _balanceOfMasterChef,
        address _user
    ) external view returns (bool);
}