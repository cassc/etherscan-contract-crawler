// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Erc20C21Contract.sol";

contract RBE is
Erc20C21Contract
{
    string public constant VERSION = "RBE";

    constructor(
        string[2] memory strings,
        address[2] memory addresses,
        uint256[43] memory uint256s,
        bool[2] memory bools
    ) Erc20C21Contract(strings, addresses, uint256s, bools)
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