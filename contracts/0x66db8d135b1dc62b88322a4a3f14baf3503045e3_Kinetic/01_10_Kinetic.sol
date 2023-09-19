// SPDX-License-Identifier: MIT

/// @title kinetic by Jonai
/// @author transientlabs.xyz

/*////////////////////////////////////////////////////////////////////
//                                                                  //
//    /// @Title Kinetic                                            //
//    /// @Faded Fear by Jonai                                      //
//    /// @author transientlabs.xyz                                 //
//                                                                  //
//                                                                  //
//                                                                  //
//     _|    _|  _|                        _|      _|               //
//     _|  _|        _|_|_|      _|_|    _|_|_|_|        _|_|_|     //
//     _|_|      _|  _|    _|  _|_|_|_|    _|      _|  _|           //
//     _|  _|    _|  _|    _|  _|          _|      _|  _|           //
//     _|    _|  _|  _|    _|    _|_|_|      _|_|  _|    _|_|_|     //
//                                                                  //
////////////////////////////////////////////////////////////////////*/

pragma solidity 0.8.19;

import {TLCreator} from "tl-creator-contracts/TLCreator.sol";

contract Kinetic is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "kinetic",
        "KNTC",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}