// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Freak Shots
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ..:^..:^..:^..:^:.:^:..^:..^:..^:..:^..:^..:^..:^:.:^:..^:..^:..^:..::..:^..:^..:^..:^:..^:..^:..^:.    //
//    ::..:^..:^..:^:.:^:..^:..^:..::..::..::..:^..:^..:^:.:^:..^:..^:..::..::..:^..:^..:^:.:^:..^:..^:..:    //
//    ..::..:^..:^..:^:.:^:..^: .::..::..::..::..:^..:^:.:^:..^:..::..::..::..::..:^..:^..:^:..^:..^:..::.    //
//    ::..::..::..:^:.:^:..:. :7JJ!::..::..::..::..::..:^:.:::..::..::..::..:!Y?7~. ::..:^:.:::..::..::..:    //
//    ..::..::..::..:::.::.:?G&@@@G .::..::..::..::..:::.:::..::..::..::..:: [email protected]@@&BY^ .::.:::..::..::..::.    //
//    ::..::..::..:::.::.^Y&@@@@@@@7:..::..::..::..::..:::.:::..::..::..::..~&@@@@@@&P~ .::.:::..::..::..:    //
//    ..::..::..::..::.:[email protected]@@&[email protected]@@@B:::..::..::..::..:::.:::..::..::..::..::[email protected]@@@PY#@@@P^ .::.:::..::..::.    //
//    ::..::..::..::..?&@@&5?5!#@@@@5..::..::..::..::..:::..::..::..::..::[email protected]@@@&757Y&@@&Y:.:::..::..::..:    //
//    ..::..::..::. [email protected]@@P7Y&@[email protected]@@@@?...::..::..::.^^::.:^~..::..::..::[email protected]@@@@[email protected]@[email protected]@@#7..:::..::..::.    //
//    ::..::..::..:[email protected]@@B7J&@@@@[email protected]@@@#^::..::..::.^PJ:.::..?G7..::..::..:^[email protected]@@@[email protected]@@@@[email protected]@@5^..:::..::..:    //
//    ..::..:::[email protected]@&[email protected]@&@@@@[email protected]@@@G..::..::[email protected]#.^~..^[email protected]:..::..::[email protected]@@@Y!&@@@&@@#?J#@@B!.:..::..::.    //
//    ::..:::.::7&@@[email protected]@&[email protected]@@@[email protected]@@@Y...::[email protected]#7BY..?#[email protected]:....:[email protected]@@@Y~#@@@#7J#@@[email protected]@@J.::.:::..:    //
//    ::::::::[email protected]@@Y7#@@[email protected]@@@[email protected]@@@PGBGGBG5J?J#@@&Y?#@@&YJY5PBBGGGG&@@@5!&@@@B~G#[email protected]@&??&@@P:.:::::::    //
//    ::::::.:[email protected]@&[email protected]@&?J&@@[email protected]@@@[email protected]@@@#BPPGGG&@&&@@@@@@@@&&@@BGGGPG#@@@@[email protected]@@@[email protected]@@Y7#@@[email protected]@B~.::::::    //
//    :::::.^[email protected]@[email protected]@[email protected]@@@@&J?#@@@575JJ5BBBGGG&@@@@@@@@@@@@@@@[email protected]@@&J7#@@@@@[email protected]@[email protected]@#~.:::::    //
//    ..::.^[email protected]@[email protected]@[email protected]@&[email protected]@@[email protected]@@GJ#@#[email protected]@@@@@@@@@@@@@@@[email protected]#[email protected]@@[email protected]@@PY#@@#[email protected]@[email protected]@#~.:::.    //
//    ::..:[email protected]@[email protected]@P!#@@P75JJ#@@@[email protected]@@[email protected]&[email protected]@@@@@@@@@@@@@#5PG&@[email protected]@@B?Y&@@&[email protected]@&[email protected]@#[email protected]@#^...:    //
//    ..::[email protected]@[email protected]@5~#@@J?#@@P75&@@&Y7PJJ#@&J7YB&#[email protected]@@@@@@@@@GP#&#57?#@#Y7PJJ#@@@[email protected]@&J?&@&[email protected]@#[email protected]@B:::.    //
//    ::[email protected]@#^[email protected]@P~#@&[email protected]@@@@@Y75&@@#[email protected]@[email protected]@P?^[email protected]@@@@@@@@@5.:[email protected]@P7J&@#[email protected]@&57J&@&@@@G?&@&[email protected]@B^[email protected]@Y..:    //
//    ..^#@@[email protected]@[email protected]@[email protected]@@P^?&@&[email protected]@@B!J&@P!: ^[email protected]@@@@@@@@@@@G~ [email protected]@[email protected]@@BJ7J#@&Y^[email protected]@@#J&@&[email protected]@P~&@@~:.    //
//    ::[email protected]@[email protected]@&[email protected]@[email protected]@@J.:.:J&@@[email protected]&J. ^J#@@@@@@@@@@@@@@&Y~  7&@#?Y57?P&@&5^ ::[email protected]@@#J&@#^[email protected]@[email protected]@P.:    //
//    [email protected]#^#@@[email protected]@[email protected]@@J::..:[email protected]@&[email protected]@&7:7P&@@@@@@@@@@@@@@@@@@@P?^^#@@55#@@#Y: ::[email protected]@@[email protected]@[email protected]@&[email protected]&^.    //
//    :[email protected]@[email protected]@[email protected]@[email protected]@@5..:::..:..~P&@@@&~.#@@@@@@@@@@@@@@@@@@@@@@@@&~:#@@@&G?. ::..::. [email protected]@@[email protected]@[email protected]@[email protected]@!:    //
//     [email protected]&~&@@7#@&?&@@P..^:..::..:: :JGB!::[email protected]@@@@@@@@@@@@@@@@@@@@@@@P.:!BGJ~. ::..::..::[email protected]@@[email protected]&!#@@[email protected]?     //
//    :[email protected][email protected]@[email protected]@[email protected]@#^::..^:..::..:: .^:..^#@@@@@@@@@@@@@@@@@@@@@@@!:..^: .::..::..:^..:^[email protected]@[email protected]@[email protected]@[email protected]:    //
//    .:&[email protected]@J&@[email protected]@@?..:^:..^:..^:..::..:: [email protected]@@@@@@@@@@@@@@@@@@@@@5 .::..::..::..:^..:^. [email protected]@@[email protected]@J&@[email protected]~.    //
//    ^:[email protected]@@[email protected]@G :^:..^:..^:..^:..::..:^[email protected]@@@@@@@@@@@@@@@@@@@#:::..::..::..:^..:^..:^[email protected]@[email protected]@[email protected]#?P.:    //
//    [email protected]#@B~&@@7::.:^:..^:..^:..^:..:^. [email protected]@@@@@@@@@@@@@@@@@@@J:..^:..::..:^..:^..:^...!&@@[email protected]&[email protected]#~~:.    //
//    ^:. [email protected]&@[email protected]@B:.:^:..^:..^:..^:..::..:^[email protected]@@@@@@@@@@@@@@@@@G..^:..::..:^..:^..:^..:^: [email protected]@[email protected]@[email protected]#^ .:    //
//    ..::[email protected]@@[email protected]@?.^:.:^:..^:..^:..^:..:^..:~&@@@@@@@@@@@@@@@@@!::..^:..::..:^..:^..:^..::[email protected]@B!&@5&G.^:.    //
//    ^^. ?&[email protected]&!#@&~..:^:..^:..^:..^:..^^..:^. [email protected]@@@@@@@@@@@@@@@P:..^:..^:..:^..:^..:^..:^: :#@@~#@5#5:..^    //
//    ..:::[email protected][email protected]@G.:^:.:^:..^:..^:..^:..:^..:^:#@@@@@@@@@@@@@@&^.^:..^:..:^..:^..:^..:^..:^[email protected]@[email protected]^.^:.    //
//    ^^..:^[email protected][email protected]@5:..:^:..^:..^:..^:..:^..:^..:[email protected]@@@@@@@@@@@@@Y::..^:..^:..:^..:^..:^..:^:[email protected]@[email protected]:::..^    //
//    ..:^. [email protected][email protected]@7 :^:.:^:..^:..^:..^:..:^..:^[email protected]@@@@@@@@@@@#^ .^:..^:..:^..:^..:^..:^..:^[email protected]@[email protected]^:.    //
//    ^^..::[email protected]@@!:..:^:..^:..^:..^:..::..:^..::[email protected]@@@@@@@@@@@7.^:..^:..^:..:^..:^..:^..:^:..~&@[email protected]!.^:..^    //
//    ..:^..:#5^@&^ :^:.:^:..^:..^:..^:..:^..:^..:[email protected]@@@@@@@@@G::..^:..^:..:^..:^..:^..:^..:^:.#@7J&~:..^:.    //
//    ^:..:^.?G~&#^:..:^:..^:..^:..^:..::..:^..:^.:&@@@@@@@@@! .^:..^:..::..:^..:^..:^..:^:.::[email protected]~5Y .^:..:    //
//    ..::..:^~.##:.:^:.:^:..^:..^:..::..::..:^..::[email protected]@@@@@@@5.^:..^:..^:..::..:^..:^..:^..:^: [email protected]^~:::..^:.    //
//    ^:..:^..::G#:^:.:^:..^:..^:..^:..::..:^..:^..:[email protected]&5Y#@&~:..^:..^:..::..::..:^..:^..:^:.::G#:::..^:..:    //
//    ..::..:^. J#:.:^:.:^:..^:..::..::..::..::..:^[email protected]  [email protected] .^:..^:..::..::..::..:^..:^..:^: GP...^:..::.    //
//    ::..::..::~B:::.:::..::..::..::..::..::..::..::BJ.:7#:::..::..::..::..::..::..::..:::.::B7.::..::..:    //
//    ..::..::..:?:.:::.:::..::..::..::..::..::..::. !?. !?...::..::..::..::..::..::..::..:::.?^:..::..::.    //
//    ::..::..::..:::.:::..::..::..::..::..::..::..::..:::.:::..::..::..::..::..::..::..:::.::...::..::..:    //
//    ..::..::..::..:::.:::..::..::..::..::..::..::..:::.:::..::..::..::..::..::..::..:::.:::..::..::..::.    //
//    ::..::..::..:::.:::.:::..::..::..::..::..::..:::.:::.:::..::..::..::..::..::..::..:::.:::..::..::..:    //
//    ..::..::..:::.:::.:::..::..::..::..::..::..::..:::.:::.:::..::..::..::..::..::..:::.:::.:::..::..::.    //
//    ::..::..::..:::.:::.:::..::..::..::..::..::..:::.:::.:::..::..::..::..::..::..::..:::.:::..::..::..:    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Venom is ERC721Creator {
    constructor() ERC721Creator("Freak Shots", "Venom") {}
}