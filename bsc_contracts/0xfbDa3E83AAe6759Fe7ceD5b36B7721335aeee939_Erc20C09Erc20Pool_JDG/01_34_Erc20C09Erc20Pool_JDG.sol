// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Erc20C09Erc20PoolContract.sol";

contract Erc20C09Erc20Pool_JDG is
Erc20C09Erc20PoolContract
{
    string public constant VERSION = "JDG";

    constructor(
        string[2] memory strings,
        address[4] memory addresses,
        uint256[67] memory uint256s,
        bool[24] memory bools
    ) Erc20C09Erc20PoolContract(strings, addresses, uint256s, bools)
    {

    }

    function decimals()
    public
    pure
    override
    returns (uint8)
    {
        return 18;
    }
}