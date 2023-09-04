// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

import "hardhat/console.sol";

/// @title Wrapper around hardhat/console.sol
library Printer {
    bool public constant PRINT = true;

    function printInt256(string memory reason, int256 number) internal view {
        if (!PRINT) return;

        if (number < 0) {
            console.log(reason, ": (-", uint256(-number), ") [FROM CONTRACT] ");
        } else {
            console.log(reason, ":", uint256(number), " [FROM CONTRACT] ");
        }
    }

    function printInt128(string memory reason, int128 number) internal view {
        if (!PRINT) return;

        if (number < 0) {
            console.log(reason, ": (-", uint128(-number), ") [FROM CONTRACT] ");
        } else {
            console.log(reason, ":", uint128(number), " [FROM CONTRACT] ");
        }
    }

    function printInt24(string memory reason, int24 number) internal view {
        if (!PRINT) return;

        if (number < 0) {
            console.log(reason, ": (-", uint24(-number), ") [FROM CONTRACT] ");
        } else {
            console.log(reason, ":", uint24(number), " [FROM CONTRACT] ");
        }
    }

    function printUint24(string memory reason, uint24 number) internal view {
        if (!PRINT) return;
        console.log(reason, ":", number, " [FROM CONTRACT] ");
    }

    function printUint32(string memory reason, uint32 number) internal view {
        if (!PRINT) return;
        console.log(reason, ":", number, " [FROM CONTRACT] ");
    }

    function printUint256(string memory reason, uint256 number) internal view {
        if (!PRINT) return;
        console.log(reason, ":", number, " [FROM CONTRACT] ");
    }

    function printUint128(string memory reason, uint128 number) internal view {
        if (!PRINT) return;
        console.log(reason, ":", number, " [FROM CONTRACT] ");
    }

    function printUint160(string memory reason, uint160 number) internal view {
        if (!PRINT) return;
        console.log(reason, ":", number, " [FROM CONTRACT] ");
    }

    function printAddress(string memory reason, address _address)
        internal
        view
    {
        if (!PRINT) return;
        console.log(reason, ":", _address, " [FROM CONTRACT] ");
    }

    function printBool(string memory reason, bool number) internal view {
        if (!PRINT) return;
        console.log(reason, number, " [FROM CONTRACT] ");
    }

    function printEmptyLine() internal view {
        if (!PRINT) return;
        console.log("");
    }
}