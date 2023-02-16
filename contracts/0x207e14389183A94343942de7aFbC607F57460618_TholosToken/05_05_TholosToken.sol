// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// OpenZeppelin imports
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**************************************

    Tholos token: THOL

 **************************************/

contract TholosToken is ERC20 {

    /**************************************
        
        ** Constructor **

        ------------------------------

        @param alloc Address of VestedAlloc contract
        @param amount Total supply of $THOL
    
    **************************************/

    constructor(
        address alloc,
        uint256 amount
    )
    ERC20("Tholos", "THOL") {

        // mint tokens to allocation contract
        _mint(alloc, amount);

    }

}