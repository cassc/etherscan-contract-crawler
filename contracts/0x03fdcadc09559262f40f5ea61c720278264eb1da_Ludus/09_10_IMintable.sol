//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

interface IMintable {
    function mint(address recipient_, uint256 amount_) external;
}