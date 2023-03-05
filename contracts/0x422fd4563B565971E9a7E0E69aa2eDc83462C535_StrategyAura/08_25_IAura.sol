// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IAura {
    function EMISSIONS_MAX_SUPPLY() external view returns(uint);
    function INIT_MINT_AMOUNT() external view returns(uint);
    function totalCliffs() external view returns(uint);
    function reductionPerCliff() external view returns(uint);
    function totalSupply() external view returns(uint);
}