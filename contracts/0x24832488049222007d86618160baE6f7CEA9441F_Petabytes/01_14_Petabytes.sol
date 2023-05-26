// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721C.sol";

contract Petabytes is ERC721C {
    constructor()
        ERC721C(
            "Petabytes",
            "PETA",
            2022,
            140000000000000000,
            0,
            2,
            1
        )
    // solhint-disable-next-line no-empty-blocks
    {
        // hmm... 0C8584AD4F1AEE986F040FA1E28769E8617D85D7773C2D81373B7782C2019B26
    }
}