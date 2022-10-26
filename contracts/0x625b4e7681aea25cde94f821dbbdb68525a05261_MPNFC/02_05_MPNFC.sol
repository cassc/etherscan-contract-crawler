// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Magnum Photos NFC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                :@@@@@@#       [email protected]@@@@@7       [email protected]@@@@^        .J#@@@@@@@@&B!   ^@@@@@@^     :@@@P  [email protected]@@7       .&@@&  [email protected]@@@@@G       [email protected]@@@@@^                   //
//                :@@@@@@@?     [email protected]@@@@@@?      ^@@@@@@&.      [email protected]@@&Y~::^7&@@@#  [email protected]@@@@@@^    :@@@G  [email protected]@@?       [email protected]@@@  [email protected]@@@@@@~     ^@@@@@@@^                   //
//                :@@@[email protected]@@.    #@@[email protected]@@?     .&@@[email protected]@@G     [email protected]@@G       .B###: [email protected]@@[email protected]@@^   :@@@G  [email protected]@@?       [email protected]@@&  [email protected]@@[email protected]@&     &@@?#@@@^                   //
//                :@@@G &@@G   [email protected]@& [email protected]@@?     [email protected]@@. [email protected]@@?   [email protected]@@@               [email protected]@@P [email protected]@@~  :@@@G  [email protected]@@?       [email protected]@@&  [email protected]@@[email protected]@@Y   [email protected]@B #@@@^                   //
//                :@@@B ^@@@~ [email protected]@@^ [email protected]@@?    [email protected]@@~   #@@@:  [email protected]@@#     5&&&###B. [email protected]@@P  [email protected]@@~ :@@@G  [email protected]@@?       [email protected]@@&  [email protected]@@Y [email protected]@@: ^@@@. &@@@^                   //
//                :@@@B  [email protected]@& [email protected]@Y  [email protected]@@?   [email protected]@@&[email protected]@@&  [email protected]@@&     Y###@@@@. [email protected]@@P   [email protected]@@^[email protected]@@G  [email protected]@@J       [email protected]@@&  [email protected]@@Y  [email protected]@B &@@7  &@@@^                   //
//                :@@@B   &@@&@@&   [email protected]@@?  [email protected]@@@@@@@@@@@@@G .&@@@G        @@@@. [email protected]@@P    [email protected]@@[email protected]@@G  [email protected]@@B       [email protected]@@B  [email protected]@@Y  [email protected]@@&@@B   &@@@^                   //
//                :@@@B   [email protected]@@@@^   [email protected]@@?  #@@@^[email protected]@@7 .#@@@@5!^::^[email protected]@@@. [email protected]@@P     [email protected]@@@@@G   [email protected]@@#?~^^[email protected]@@&.  [email protected]@@Y   [email protected]@@@@.   &@@@^                   //
//                :@@@G    [email protected]@@J    [email protected]@@7 [email protected]@@7        .&@@@.  ^P&@@@@@@@@@@@#. [email protected]@@5      [email protected]@@@@P    ~G&@@@@@@@&G~    [email protected]@@J    [email protected]@@!    #@@@^                   //
//                  ...      ...      ...  ....           ...       .::^^::..     ...        .....        ..:::..        ...      ...      ...                   //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MPNFC is ERC721Creator {
    constructor() ERC721Creator("Magnum Photos NFC", "MPNFC") {}
}