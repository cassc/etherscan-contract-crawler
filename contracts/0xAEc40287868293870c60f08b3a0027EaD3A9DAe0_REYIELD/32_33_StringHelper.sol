// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

library StringHelper
{
    error StringTooLong();

    function toBytes32(string memory str)
        internal
        pure
        returns (bytes32 val)
    {
        val = 0;
        if (bytes(str).length > 0) 
        { 
            if (bytes(str).length >= 33) { revert StringTooLong(); }
            assembly 
            {
                val := mload(add(str, 32))
            }
        }
    }

    function toString(bytes32 val)
        internal
        pure
        returns (string memory)
    {
        unchecked
        {
            uint256 x = 0;
            while (x < 32)
            {
                if (val[x] == 0) { break; }
                ++x;
            }
            bytes memory mem = new bytes(x);
            while (x-- > 0)
            {
                mem[x] = val[x];            
            }
            return string(mem);
        }
    }
}