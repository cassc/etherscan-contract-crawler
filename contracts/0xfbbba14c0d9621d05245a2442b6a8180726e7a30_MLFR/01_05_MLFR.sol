// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MALFORMΞD
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        p|lTLF||||[email protected]@@P|||L%@@@@@@@@@[email protected]@@@[email protected]@[email protected]@@@@@@@@@@[email protected]@@@@@@@@NB`||lL|4|$|lL    //
//        @@@@@@@@g|[email protected]@@W||L|[email protected]@[email protected]@@@@@@[email protected]@@@[email protected]@$%@@@@@@@@@@[email protected]@@C||;[email protected]@@g|$||Tl    //
//        @@@@@@@@@|@@@@@@@|[email protected]@@@@@@@@@@@@@@Q$$#@@@@@[email protected]@@@@@@@@@@@@@@[email protected]|[email protected]@@@@@@@@|L|||L    //
//        @@@@@@@@|]@@@@@@@@|L|@@@@@@@[email protected]@@@@@@[email protected]@@@[email protected]@[email protected]@@@@@@[email protected]@@@@$b|[email protected]@@@@@@P`|||l|T    //
//        @@@@@@P|[email protected]@@[email protected]@@[email protected]@@@@@@[email protected]@[email protected]@@[email protected]@@@@[email protected]@@@@@@@@@[email protected][email protected]@@@@|[email protected]|T||||Lwz|O    //
//        @@@@P|TlFL|i|"`|T||;@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@[email protected]@[email protected]@@@@L|[email protected]@@|L|gggg|T||||    //
//        @@@PT|||||L||LLL|L]@@[email protected]@@@@@@@@@@[email protected]@@@@[email protected]@@[email protected]@@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@    //
//        @@@pLL||||||L||||l]@@@@@@@@@@@@@@@@@@@[email protected]@@@@[email protected]@@@@@@[email protected]@@@B|||@@@@@@@@@@@@@@@@@@@    //
//        @@@@p|||||L|||}||[email protected]@@@@@@@@@@@@@@@@@@[email protected][email protected]@@@@@[email protected][email protected]@@@[email protected]@$|||[email protected]@@@@@@@@[email protected]@@@@@@@@    //
//        @@@@@@@g|L|||lL}||@@@@@@@@@@@@[email protected]@@@@@[email protected]@@@@@@@@@@@@@@@[email protected]|L|||@@@@@@@@R||||TTT|    //
//        @@@@@@@@pL||TTL|L|@@@@%%@@[email protected]@@@@@@@[email protected]@@@@@@[email protected]%@[email protected]@@@@@@@[email protected]@@@@@@@@CT||L|||||    //
//        @@@@@@@@@|||L||L|L|%@[email protected]@@@@@@@@@[email protected]@@@@@@@@[email protected]@[email protected]@@[email protected]@[email protected]@@@[email protected]@@@@@P|||||||l|||;    //
//        @@@@@@@@@p|,ggg|LL|||[email protected]@@@@[email protected]@@@[email protected]@@@@@[email protected][email protected]@@@@@[email protected]@@@@]@@@@@@|T||||||||||@@    //
//        @@@@@@@[email protected]@@@@@Ll||T]@[email protected]@[email protected]@@@@@@[email protected]@@@@$$&%@[email protected]@@@@@[email protected]%[email protected]@@[email protected]@@@|||[email protected]@@@@@@@@@@    //
//        @@@@@@@@@@@@@@@DL|}|L]@@@@@@@@@@@@@@@@@[email protected]&[email protected]@@@@[email protected]@@@%[email protected]@@@M|[email protected]@@@@@@@@@@@@    //
//        @@@@@@@@@@@@@@@@TL|||[email protected]@@[email protected]@@@[email protected]@@@@[email protected]@[email protected][email protected]@@@@@@@@T|||[email protected]@@@@@@@@@@@@@@    //
//        @@@@@@@@@@@@@@@@@pLLL||[email protected]@@@@@[email protected]@@@@@@&@Q&@[email protected]@@[email protected]@@@@@B||||[email protected]%@@@@@@@@@@@@@@@    //
//        @@@@@@@@@@@@@@@@@@T|||||[email protected]@[email protected]@@@[email protected]@@@@$$&$$$$%[email protected]@@@@@|L|[email protected]]@[email protected]@@@@@@@@@@@@@@    //
//        @@@@@@@@@@@@@@@@@[email protected]@|[email protected]$%[email protected]@@@@@@@@@&[email protected]@@@@@@@@@L|@p|[email protected]@@@@@@@@@@@@@@@    //
//        @@@@@@@@@@@@@@@@)@@[email protected]@$&[email protected][email protected][email protected]@@%@@@@@@@@@@@@[email protected][email protected][email protected]@@@@||[email protected]|@@@@@@@@@@@@@@@@    //
//        @@@@@@@@@@@@@@@@]@]@@@@$$&@[email protected]@@@[email protected]@@@@[email protected]@@@[email protected]@@@@)]@@@@@@@@@@@@@@@@    //
//        @@@@@@@@@@@@@@@@Q1]@@@M&[email protected][email protected]$$$&[email protected]@@@[email protected]@@@@@@@&@$&$$#@@@@[email protected]%@@@@@@@@@@@@@@@    //
//        @@@@@@@@@@@@@@@[email protected][email protected]@@@@[email protected][email protected]@@@@@[email protected]@@@[email protected]@[email protected]@@[email protected]@@@@@@@@@@@@@    //
//        @@@@@@@@@@@@@@@@@&$%@@@@@@@[email protected]@@@@@@@[email protected]@[email protected]@#@@@@@@[email protected]@@[email protected]@[email protected]@@@@@@@@@@@@@    //
//        @@@@@@@@N%%@@@@[email protected]@$#[email protected]@@@@@@@@@@[email protected]@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected][email protected]@@R%@@@@@@@@@    //
//        @@@@@@@@@@@[email protected]@@$%@@$$Y$&&&&&N%[email protected][email protected]@@@@@@@@@@$%@$%&&&&&WM$&[email protected]@[email protected]@@[email protected]@@@@@@@@@@    //
//        @@@@@@@@[email protected][email protected]@[email protected]@@@g$%@g$&[email protected]&$$%M$$$$$$MB$Q#[email protected]@l$$$&[email protected]@[email protected]@@@[email protected][email protected]@@@@@@@@@    //
//        @@@@@@@@@[email protected]@@@@@@@@[email protected]@[email protected][email protected]@%%%%%@@$&$$$$%@&[email protected]@[email protected]@@@@@[email protected]@@[email protected]@@@@@@@    //
//        @@@@@@@@@[email protected]@@[email protected]@@@@@@[email protected][email protected]@$&&@@[email protected]@W&@[email protected]@$$%@[email protected]@[email protected][email protected]@@@@@[email protected]@@@@@@@@@@    //
//        @@@@@@@@@@@@[email protected]@[email protected]@@@@[email protected][email protected][email protected]$B$|J||||||P|$%[email protected]@[email protected][email protected]@@@[email protected]@[email protected]@@@@@@@@    //
//        @@@@@@@@@@@$%[email protected]@[email protected]@@@@[email protected][email protected]$|]g||g||p|L|[email protected]@@[email protected]@@@[email protected]@[email protected]@[email protected]@@@@@@@@@@    //
//        @@@@@@@@@@@@[email protected]@@[email protected]@@@@[email protected][email protected]@[email protected]@@@@@@@@@@@@@[email protected][email protected]@@@@[email protected][email protected]@@@@@@@@@@    //
//        @@@@@@@@@@@@@@@@@[email protected]@@@@[email protected][email protected][email protected]@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@@@[email protected]@@@@@@@@@@@@@@    //
//        @@@@@@@@@@@@@@@@@[email protected]@@@[email protected][email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@[email protected]@@@@@@@@@@@@@@    //
//        @@@@@@@@@@@@@@@@@@[email protected]@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@[email protected][email protected]@@@@@@@@@@@@@@@    //
//        @@@@@@@@@@@@@@@@@@[email protected]@@[email protected]@@@@@$$$$$$$$$%@@@@@@@[email protected][email protected]@@@[email protected][email protected]@@@@@@@@@@@@@@@    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract MLFR is ERC1155Creator {
    constructor() ERC1155Creator(unicode"MALFORMΞD", "MLFR") {}
}