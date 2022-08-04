// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

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

contract DDC_royalties is PaymentSplitter {
    address[] internal payees_dep = [
        0xBB9422050576bf1792117c18941804034286f232,
        0x808C943B4222f54B7ef3f59456cacCdF25b288Ca,
        0x601cB5A043D05949F7D0D5B52dd913e4A9d36290,
        0x8cB63419009c84DC84C6240Cd4d5b3035B35df92,
        0xA94F799A34887582987eC8C050f080e252B70A21
    ];
    uint256[] internal shares_dep = [400, 150, 150, 150, 150];

    constructor() PaymentSplitter(payees_dep, shares_dep) {}
}