// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*************************************************************************
 *           ....                 ....
 *       .xH888888Hx.         .xH888888Hx.
 *     .H8888888888888:     .H8888888888888:
 *     888*"""?""*88888X    888*"""?""*88888X
 *    'f     d8x.   ^%88k  'f     d8x.   ^%88k
 *    '>    <88888X   '?8  '>    <88888X   '?8
 *     `:..:`888888>    8>  `:..:`888888>    8>
 *            `"*88     X          `"*88     X
 *       .xHHhx.."      !     .xHHhx.."      !
 *      X88888888hx. ..!     X88888888hx. ..!
 *     !   "*888888888"     !   "*888888888"
 *            ^"***"`              ^"***"`
 *************************************************************************/

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract DD_R is PaymentSplitter {
    constructor(address[] memory payees, uint256[] memory shares_)
        PaymentSplitter(payees, shares_)
    {}
}