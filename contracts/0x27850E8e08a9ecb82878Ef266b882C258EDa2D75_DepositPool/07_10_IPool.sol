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

/**************************************

    Pool interface

 **************************************/

abstract contract IPool {

    // events
    event Withdraw(address receiver, uint256 amount);

    // errors
    error InvalidSender(address sender, address expected);

    // functions
    function withdraw(address, uint256) public virtual;
    function poolInfo() external virtual view returns (uint256);

}