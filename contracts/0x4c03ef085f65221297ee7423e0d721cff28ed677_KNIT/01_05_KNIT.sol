// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Knit by Knit
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    dddddddddddxkkxxkxdddkOkxddddddddddxxkOOkdddddddxxkkxdddxxkkkkxddddddddddddddddddddddddddddxkkOOOkxdoddddddddkOOxdoddddd    //
//    ddddodddddxxxxkkxxddddxxkkxxdddddddddddddddddxxkkxdddxkkOOOkxxddddddddddddddodddddddddddddddddxkkOkxoddddddddddxxdoddddd    //
//    dddddddddddxxxdddddddddddxxkkkxddddddddddxxkkxxddxxkOOOkxxdddddxdddddoddoddddddddddddddddddddddddddodddddddoddoddddddddd    //
//    dddddddddddddddddddddddddddxxxxxxdddddxkkxxdddxkkOOOkxddddddddddddoddodddddddxxddddddddddddxxdddddddddddddddddddddddddod    //
//    dooddddddddddddddddddddxxxkkxdddddxxkkxxdddxkOOOkkxdddodddddodddoddddddxkkOkxkOkdddddddxxkkxxddxxddddddddddddddddddddddd    //
//    dddddoddddddddddddddxxkkxxdddddxkkkxdddxxkOOOkxddddddddddddxxdoddddxxkOOO0OOkxddddddddkkxdddxkkOOxdoddddddddddddddxxxddd    //
//    dddddooddddddddddxxkkxdddddxxkkxxdddxkOOOkkxdddddxxkOkkxdodxkxddxkkOOOkkkkxddddddddddddddddxOOkkxdddddddoodddddxkkxxdddd    //
//    ddddddddddddddxkkxxddddddddxxxddxxkOOOkxddddddxkkOOO0OkxdodxxxkOOOkkxxdddddddddxkxddddddddodddddddddddddddddddxxddddddod    //
//    ddddddddddddddxddddoddddddddddxkOOkkxdddddxxkOOOOOOkxddddxO0OOOkxxxkxxddddddddddxxxxdddddddddddddddddddddddddddddddddddd    //
//    dddddddddxxxdddxkkkxdddddddodddxxxdddddxkkOOOkxddxddddddx0X0kkkddxxdddddddddodddddddddxdodddddddddddddddddddddddddddddxk    //
//    ddddddddxkxddddxkkOkxddddddddddddddxxkOOOkxxdddddodddddkKXX0kkkkxddddddddddddddddddxkkxdoddddddddddddkOkxddddddddddddddd    //
//    ddddddddddddddddoddddddddddddddddxkOOOkxddddddddddddddkKXXX0kkkkkxdddddddddddddxxkkxxdddddddddddddddddxxdddxxddddddddddd    //
//    ddddxkkOkxdddddddddddddxkkxxdddddxxxxddxxkkxddooddddxOXXXXX0Okkkkkkxddddddddxxkkxxdddddddddddddddddddddxxkkxxddddddddddd    //
//    dddxxkkxxdddddddddddddxxxxkkkxxdddddddxkOOOOOkxxdddx0XXXXXX0Okkkkkkxddddddddxxddddddddddddddddddddddddxkxddddddddddddddd    //
//    dxkOkxdddddddddddoodddddxkkkxxxkkxdoddddxkkOOOkxddk0KKKXKXK0kkkkkkkkxddddddddddddddddddodddddddddddddddddddddoddddddddod    //
//    ddxxxddddddddddddddddddddddxxkkxxxdodxkxxdddxxdddk0KKKKKKKK0kkkkkkkkkkxddddddddddddddddoddddddddxddddodddddddddddddddxxk    //
//    dddddddddddddddddddddddddddddddxkkxxdddxkkxxxxkkO0KKKKKKKKK0kkkkkkkkkkkkkxddddddddddddddddddxkkOOkxdddddddddddddddxkkOOO    //
//    ddddddddddddddddddddddddddddddddddxxxdddddxkkO00KXXKKXKKKKK0kkkkkkkkkkkkxddddddddddodddddxkOO0OOOkkxxkOkkxdddddddxOOOOOO    //
//    ddddddddxxxddddddddddddddddddddddddddddddddddx0KKKKKKKKKKKK0kkkkkkkkkkkkkxddddddddddddddxkOOOOkxddxOOOOOOkddddddoddxdxxk    //
//    dodddxkOkxdddddddddddddddddodddddddddddodxkOk0KKKKKKKKKXKKK0kkkkkkkkkkkkkkkxdddddddddddodddxxddddddxkkxxdddddddddddddddd    //
//    ddddddxxxdddddddddddddddddddddddddddddddddxOKKXXKKKKKKKKKKK0kkkkkkkkkkkkkkkkxdddddddxxdodddddddddddddddddddddddddddddddd    //
//    dddddddodddddddddddddddddddddddddxkxxdddddk0KKKKKKKKKKKKKKK0kkkkkkkkkkkkkkkkkxdddddxOOxddddxkkxddddddddodddddddddxkxdddd    //
//    dddddddddddddddddddddddddddddxxkOO0OOOkxxk0KXKKKKKKKKKKKKKK0kkkkkkkkkkkkkkkkkkxddddddxxdddkOOOOOkxdoddddddddddddoddddddd    //
//    ddddddddddddddddddddddddddxkkOOOO0OO00OO0KKXKKXXKKXXKXXXKKK0OkkkkkkkkkkkkkkkkkkxddddddddoddxxkOkkxdodddddddddddxxddddddd    //
//    dddddddddxkxddddddddddddxkOO0OO0OO0Okkk0KXKKKKKXKKKKKKKK00OOOOOOkkkkkkkkkkkkkkkkxdddddddddddddddddddddddddddxxkOOkxddddd    //
//    dddxkOOkkxxxxddddddoddddddxkkOOOOkxxdx0KKKKKKKKKKKKK00OkkkkOOOOOOOOOkkkkkkkkkkkkkxdddddddddddddddddddddddddxkOkkxddddddd    //
//    dddxkOOOOOxddddddddddddddddddxxxddddx0KXKKKKKKK00OOOkkkkkkkOOOOOOOOOOOOOOkkkkkkkkkkxxdddoddddddddddddddddddddddddddddodd    //
//    odddddxkxddddddddoddddddddddoddddddk0KKKKKK00OOkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOkkkkkkkxdddoddoddodddddddddddddddddddddddxk    //
//    dddddddddddddddddxkkkkxdddddddddddkKKKK00OOkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOkkkkxddoddddddddddddddddddddxxddddddddd    //
//    kxdddddddddddddxOOOO0Okxddddoddodk00OOkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOkxddddddddddddddddddddddxxkkxxddddd    //
//    OOOkxdddddddddddxxkOOOkxxddddddddxxkkkkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOkxddddddxdddddddxdddddddddddxxodxxd    //
//    OOOOkxddxddxkxddddddxkOOOkkxddddddddxxkkkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOkkxdddddxxkOOkxdxxkOOOkxddddddddddodddd    //
//    dxxddoodxkkkxxddxxxxkkxxkkOOOkdddddddddxxkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOkkxddoddxkkOOOkxxxkOOOOO00OOkxddxxkxxddddd    //
//    dddddddkOOOkxdddxkOOO0OkxddxxxdddxkkxdddxkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOkxxddddddxkOOkxxdddddxkxxkOOOkkkxkkkxxddddddd    //
//    ddddddddxxdddddddddxkkxddddddddddxO000OOO0OkkxxxkkkkkkkkkkkOOOOOOOOOOOOkkxxddddddxxkkxxdddddddodddddddxxkkOOOkdddddddddd    //
//    dddddddddddddddddddddddddddddddxkOO0KKXKKK0kxddddxxkkkkkkkkkkxxxxxxxxxxddodddxxxkkkxdddddddddddddddddddxkOOOkkxddddddddd    //
//    dddddddxxxdddddddddddddxkkkxxddxxkOOkO0XXXK0Okxddddddxkkkkkxxxddddxxkkxdddxxkkkkkkxddddddxddddddddddddddddxxddddoddddddd    //
//    doddddddxxdoddddddxxxxdddddxxxddddddddx0KXXXXKK0kxddddddxxxxkxdxkkOO0OOkxkkkkkkkxddddddxOOOkxxddddddddddddddddxxdddddddd    //
//    dddddddddddddddxkkO0OOkxxdddddddddddddddOKXXXXXXXK0OxdddddddxdddxkOOOOOkkkkkkkkxdddddddddxkOOOkkxdddddddodxkxdxdddxxkkxd    //
//    kdddddddddddddkOOkkOOO0OOxdddddddxdddddddk0KXXXXXXXXK0OkxdddddddxxkkkkkkkkkkkkddddddddoododdxkOOOOkddddodxdddddxxkxxxddd    //
//    dddddddddddddddxxkkOOOkxxddddddddxkxxddddddOKXXXXXXXXXXKK0kxxxxkkkkkkkkkkkkkxdddddddododdddxkkOOOkxddddodxxxxkkkxddddddd    //
//    ddddddddddddddddxkkkxddddddddxxkkkkxxkkxxdddk0KXXXXXXXXXXXK0kkkkkkkkkkkkkkkxddddddddddddddkOOkkxxdddoddodddxxddddddddddd    //
//    dddddoodddddddddddddddddddddxkOOO0OOxddxxddddxOKXXXXXXXXXXX0OkkkkkkkkkkkkxdddddddddddddddddxxkkOOkxddddddddddddddddddddd    //
//    kxdxkxxddddddddddddddddddddddddxxkkxdddddddddddkKXXXXXXXXXX0kkkkkkkkkkkkkxdddddddddddddddddxkO0OOkxddddddxddddoddddddddd    //
//    kkOO0OOkddddddddddddddddodddddddddddddddddddddddk0KKKKKKKKK0kkkkkkkkkkOOOOkxxdddddddddddddddxxkxdddddddodxxxdddddddddddd    //
//    O0OOOkxdddddddoddddddddddddddddxxddddddddddddddddxOKKKKKKKK0kkkkkkkkkOOO0OOOkxddddddddodddddxkkxxddddddddddddddddddddddd    //
//    Okxxddddddddddxxxxdddddddddddxkkkkddoddddddddddddddk0KKKKKK0kkkkkkkkkkOOOkxxddddddddddddddxkkxxxkkxxddddoddddddddddddddd    //
//    ddddddddddddxxkkxxkOOkxddddddxddxxxxddddddddxdddddddx0KKKKK0kkkkkkxdddxxddddddddddddddddddxkkxddddxxxddddddddddddddddddd    //
//    dddddddddddddxkkkxxxkOkxddddddxkkkxdddddddxkOOxdddddddOKKKK0kkkkkxddddddddxxxddddddddddddddddddoddddddddddddddddddddddxk    //
//    ddddddddddddddxkkxddxddddoddddxxddddddddddddxkxdddoddddk0KK0kkkkdddddddddxkOOOkxdddddddxxkOkxdddodddddddddddddddddddkOOO    //
//    ddddddddddddddddddddddodddddddddddddddddddxkxdddddddddddxOK0kkxddddodddddddxxkOOOkxxdddxkkkxddddddddddddddddddddddddxxkO    //
//    ddddddddddddddddddddddoodddddddddddddddddxxxdddddddxOkkxddkkkxdddddddddddddddddxxxxdddddddddddddddddddxkxxdddddddddddddd    //
//    ddddddddddoddddddddddddddxxdddddddddddddddddddddooddxkkxddddddddddddddddddddddddddddddddddddddddodddddddxxxddddddddddddd    //
//    dddddxkxxdddxxdddddddddddxxkkxddddxxdddddddddddddddddddddddddddddddddddddddddddddddodddddddddddddddddddddddddddddddddddd    //
//    dddddddddxkkkxxxkOkdddddddddxxxxkOOOkkxdddddddddddddkkxxddddddddddddddxxdodddddddddddodddddddddxxddxddddddddddddoddddddd    //
//    dddddxxkkxxkkOOOkkxdddddddodddxkOkxxdxxxddddddddddddddxkkxxxxdddoddddddxddddddddddddddddxkkOOkxxdddddddddddoddddddddxkkx    //
//    ddddxxxxxkOOOkxxdddddddddddddddddddddddddddxkxdddddddddddxxxxdddddddddddddddddddddxkkxddxkkOOkxxdddddddddddodxddddodxkkx    //
//    dddddddddxkxddddddddddddddddddddddddddddddxkOkkkxxdddddddddddddddddddddddddddddxkkkxdoodddddxddddddoddddddxxkxxddddddddd    //
//    dddddddddddddoodddddddddoodddddddddddddddodddddxxxkxxdddddoddddddddddddddddxxkkxxddddoddddddddxxxdddddddxkxxxxkxdddddddd    //
//    xdddddddddoddddddddddddddddddddddddddddddddddddddddxOkxdoddddddddddddddddxkOkxxkxdddddddxxdddoddddddddddddxOOxdddddddddd    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KNIT is ERC721Creator {
    constructor() ERC721Creator("Knit by Knit", "KNIT") {}
}