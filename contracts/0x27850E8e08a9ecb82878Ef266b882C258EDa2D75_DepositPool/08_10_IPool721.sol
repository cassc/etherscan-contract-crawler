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

import { IPool } from "./IPool.sol";

/**************************************

    Pool interface that supports NFTs

 **************************************/

abstract contract IPool721 is IPool {

    // functions
    function withdraw(address, uint256[] calldata) public virtual;

}