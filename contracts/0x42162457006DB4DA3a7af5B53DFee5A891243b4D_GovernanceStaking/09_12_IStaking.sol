// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;

    function rebase() external;

    function epoch()
        external
        view
        returns (
            uint256 length,
            uint256 number,
            uint256 endBlock,
            uint256 distribute
        );
}