// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Erc20C20EtherPoolContract.sol";

contract PEPEnima is
Erc20C20EtherPoolContract
{
    string public constant VERSION = "PEPEnima";

    constructor(
        string[2] memory strings,
        address[7] memory addresses,
        uint256[68] memory uint256s,
        bool[25] memory bools
    ) Erc20C20EtherPoolContract(strings, addresses, uint256s, bools)
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