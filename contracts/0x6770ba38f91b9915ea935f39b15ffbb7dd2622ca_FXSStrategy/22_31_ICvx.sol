// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface ICvx {
    function reductionPerCliff() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalCliffs() external view returns (uint256);

    function INIT_MINT_AMOUNT() external view returns (uint256);

    function EMISSIONS_MAX_SUPPLY() external view returns (uint256);

    function maxSupply() external view returns (uint256);
}