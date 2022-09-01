// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: vuLoN_
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@&@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?~~~^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#~~~^^[email protected]@@@@5^~~^~~^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@[email protected]@@@@@#[email protected]@@[email protected]@7.:^7::[email protected]@@@@@@@@@@@@#PJ7!~~!7J5B&@@@@@@#::.YJ:.:J&@@@Y.:^7^:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@7...^: ^[email protected]@@@&~.:~...~&!..^:[email protected]@@P..:[email protected]@7:[email protected]?::[email protected]@@@@@@@@@&Y~::!?YY5Y?!^:^[email protected]@@@#^:^@@&?:[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@&!:[email protected]!.~&@@@7.:B&^.^[email protected][email protected]:[email protected]@@P:[email protected][email protected]@7:[email protected]?::[email protected]@@@@@@@@5^.!P#BPYJJJ5B#G7.:J&@@#^:^&#[email protected]~.:[email protected][email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@#^.^#&^[email protected]@J.:[email protected]!.:[email protected]@[email protected]:[email protected]@@P:[email protected][email protected]@7:[email protected]?::[email protected]@@@@@@@J.:[email protected]!:^7??7~:[email protected]^.!&@#^:^&B.7#&J:.~7::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@G:.^&#:.J5:[email protected]?.:[email protected]@@[email protected]:[email protected]@@P:[email protected][email protected]@7:[email protected]?::[email protected]@@@@@@P.:[email protected]:5&@@@@@[email protected]:[email protected]#^:^&B:.^[email protected]~.:::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@5:[email protected]:::[email protected][email protected]@@@[email protected]:[email protected]@@P:[email protected][email protected]@7:[email protected]?::[email protected]@@@@@@?.^&&^[email protected]@@@@@@@G:[email protected][email protected]#^:^&B:::[email protected]::[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@[email protected]@5..!&@@@@[email protected]:[email protected]@@P:[email protected][email protected]@7:[email protected]?::[email protected]@@@@@@J.^#@[email protected]@@@@@@@5.:[email protected][email protected]#^:^&B::^~.:[email protected]#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@7:[email protected]@P.:^#@@@@@7.^@#:[email protected]@@[email protected][email protected]@7:[email protected]?..7&&&&&&@#^[email protected]~.!P#&&&G?.^[email protected]::[email protected]#^:^&B::!&?:[email protected]@[email protected]@&&&&&&&&&&&&&&&&@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@&~:[email protected]@B.::[email protected]@@@@@[email protected]~:~7!:^[email protected]@@7:[email protected]:^^~~~~^:[email protected]^.!#&5!^^^^^^~Y#&?.:[email protected]@#^:^@#::[email protected]@P~.:?&@@[email protected]@7^^~~~~~~~~~~^:[email protected]@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@B^:.YP:.:[email protected]@@@@@@@?:.?B#BGPGB#BJ:.7&@@7::~G#BBBBBBB~ [email protected]@#?::7PBBBGGBBBP?:[email protected]@@#:::PY.:[email protected]@@&?:.^5&[email protected]@! 7BBBBBBBBBB~ [email protected]@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@P::..::[email protected]@@@@@@@@@G?^:^~!!!!^:^[email protected]@@@7::::^^^^^^^^::[email protected]@@@#Y!^:^~!!~^::[email protected]@@@@#^::::::[email protected]@@@@P~::^:::[email protected]@!::^^^^^^^^^^::[email protected]@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@&BG55555GB&@@@@@@#BBBBBBBBBBBBBB#@@@@@@@&BG5555PB&@@@@@@@@@BBBBBBB#@@@@@@&BBBBBB&@@#BBBBBBBBBBBBBB#@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    &@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VLN is ERC721Creator {
    constructor() ERC721Creator("vuLoN_", "VLN") {}
}