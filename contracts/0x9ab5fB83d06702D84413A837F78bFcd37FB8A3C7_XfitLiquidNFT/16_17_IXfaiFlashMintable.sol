// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IXfaiFlashMintable {
    function mint(address _account, uint256 _amount) external returns (bool);
    function flashMint(uint256 amount) external returns (bool);

    event FlashMint(address indexed from, uint256 amount);
}