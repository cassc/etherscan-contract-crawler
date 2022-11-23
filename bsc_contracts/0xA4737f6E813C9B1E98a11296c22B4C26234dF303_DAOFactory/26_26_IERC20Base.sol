//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.9;

interface IERC20Base {

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimal_,
        uint256 totalSupply_
    ) external;

}