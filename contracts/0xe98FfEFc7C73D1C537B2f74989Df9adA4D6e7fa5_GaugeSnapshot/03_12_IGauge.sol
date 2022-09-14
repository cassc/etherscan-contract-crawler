pragma solidity ^0.8.6;

interface IGauge {
    function totalSupply() external returns(uint256);

    function inflation_rate() external returns(uint256);

    function working_supply() external returns(uint256);

    function lp_token() external returns(address);
}