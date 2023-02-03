// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

/**
    Allows for conversions between bytes32 and string

    Not necessarily super efficient, but only used in constructors or view functions

    Used in our upgradeable ERC20 implementation so that strings can be stored as immutable bytes32
 */
library StringHelper
{
    error StringTooLong();

    /**
        Converts the string to bytes32
        Throws if 33 bytes or longer
        The string may not be well-formed and there may be dirty bytes after the null terminator, if there even IS a null terminator
    */
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

    /**
        Converts bytes32 back to string
        The string length is minimized; only characters before the first null byte are returned
     */
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