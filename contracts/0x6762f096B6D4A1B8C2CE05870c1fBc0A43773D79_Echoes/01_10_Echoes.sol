// SPDX-License-Identifier: MIT

/// @title Echoes
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                                                  ◹◺
◹◺    ';.                  .;.                  .,.                 ◹◺
◹◺                ,dOOkc.              .lkOkl.              'okl.   ◹◺
◹◺              ,dkl..;xkc.         .okko'.'dkl.          'oko.     ◹◺
◹◺            ,dkl.     ;xkc.     .oko:'     'dko.      'oko.       ◹◺
◹◺          ,dkl.         ;xkc. .oko'          'oko.  'oko.         ◹◺
◹◺        ,dkc.             ;xkkko'              'dkclko.           ◹◺
◹◺       .,;.                 ,c'                  .,,.             ◹◺
◹◺                                                                  ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import {TLCreator} from "tl-creator-contracts/TLCreator.sol";

contract Echoes is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "Echoes",
        "ECHOS",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}