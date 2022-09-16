// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Devotion
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @#^ ..  Y&#G7..^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@!   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@&     [email protected]@@@&!    !#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:[email protected]@@@@.   .&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@.    [email protected]@@@@@P     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B!  [email protected]@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@.    [email protected]@@@@@@Y     [email protected]@@@@&J7#&5:[email protected]@&~::::^#@@@@P:[email protected]@@G!J&#7.!5&@@@@&?    J&#@@P:^^^^@@@@@@P!J&#7.!5&@@@@B^::::B&P7:..^[email protected]@    //
//    @@@.    [email protected]@@@@@@@.     &@@&^  &@@@Y   [email protected]&     @@@@@#[email protected]@?  [email protected]@@@7   ^&@@@G    [email protected]@@@@.    &@@@?  [email protected]@@@7   ^&@@@~    [email protected]@&.    @@    //
//    @@@.    [email protected]@@@@@@@?     [email protected]&   [email protected]@@@@    [email protected]&    ^@@@@[email protected]@^   [email protected]@@@@^    #@@G    [email protected]@@@@^    &@@:   [email protected]@@@@:    #@@J    [email protected]@@:    @@    //
//    @@@.    [email protected]@@@@@@@Y     &@7   ~&####[email protected]@B    [email protected]@[email protected]@P    [email protected]@@@@G    :@@G    [email protected]@@@@^    &@P    [email protected]@@@@P    ^@@J    [email protected]@@:    @@    //
//    @@@.    [email protected]@@@@@@@?    [email protected]@~   [email protected]@@@@@@@@@@@@G    5G&@@Y    [email protected]@@@@&    [email protected]@G    [email protected]@@@@^    &@Y    [email protected]@@@@&    [email protected]@J    [email protected]@@:    @@    //
//    @@@.    [email protected]@@@@@@@.   [email protected]@@P    ~&@@@@@@#@@@@@Y    &@@@&     @@@@@&    [email protected]@G    [email protected]@@@@^    @@&    [email protected]@@@@&    [email protected]@J    [email protected]@@:    @@    //
//    @@@.    [email protected]@@@@@&:  :[email protected]@@@@?     :7J?~:[email protected]@@@@@?  [email protected]@@@@#.   [email protected]@@@G   [email protected]@@#    [email protected]@@@@^    @@@B.   [email protected]@@@G   [email protected]@@?    [email protected]@@:    @@    //
//    @&~     [email protected]&&&BJ:^Y&@@@@@@@@#!.      !&@@@@@@@@[email protected]@@@@@@@P^  !&@&..?&@@@@@G:   ~G&@B     [email protected]@@@5^  !&@&..?&@@@&.    [email protected]@B     [email protected]    //
//    @&#&&&&&&&&&&&&@@@@@@@@@@@@@@@&BBB&@@@@@@@@@@@@@@@@@@@@@@@@&BB&&&@@@@@@@@@@@&&##&@&&&&&&#@@@@@@@&GB&&&@@@@@@&&&&&&&@@&&&&&&&@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DVTN is ERC721Creator {
    constructor() ERC721Creator("Devotion", "DVTN") {}
}