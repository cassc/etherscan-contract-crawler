// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Faith Love editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    XXXXXXXXNXNNNNNNNNNNNNNNNNNNNNNNNK0kxxddoooooddddxOXNNNNNNNXXKK00OOkkkkxxkkOKXNNNNNNNNNNNNNNNNN         //
//    NNNNNNNNNNNNNNNXXNNNNNNNNNNXKOxdookko:,......    .......cdoolc:;,,''.............'c0NNNNNNNNNNNNNNNN    //
//    XXXXXNNNXXXNNNNNNKOxoooolc:;'... ......................... ..  ........... ....,;cdKNNNNNNNNNNNNNNNN    //
//    XXXXXXXNNNNNNNXNO:......   .......................... ..................;codkO0KXNNNNNNNNNNNNNNNNNNN    //
//    XXNNNNNXNNNNNNNNKd,.................................................. .ckXNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNXx;.................................................... .cKNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNXOo:,.................................................. .':cdKNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNXNNNXNNNNNNNKOx;.....................   ............................c0NNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNXNXOx:................... .;cccloddxkkkkxxc............ .:OKKXNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNXXKx;...................... .d0xxkkOKNNNNNNNx. ..............'';xXNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNXOxolc:,'...........................oKKKXXNNNNNNNO;....................lKNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNXx;........''........................dXKxxO0XXK0xl'........ .....'',;:ld0NNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNX0OOOOO00000000000Ox;....... .....'dXNX0l;,,;,...........,oxkO00KKXXNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNXXXXXXXXNXkl'.  ...:odxxxk0XNXKKKOo'.......   ...xNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNNNNXXXXXNXOollllcckXNNNNNNNXNX0KNNX0ko,',;;:clldOXNNXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNNNNNNNNNNNXNNXXXXXXXNNNNNNKKXNXXXXNNNXNXXXNXXXNXOOKXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    NNNNNNNXXXNNXXXXXXXXXXXXXXXNXNNXNK0XNNX0KNXXXNXKXNXXX0KK0XNXNXXXNNNNNNNXNNXNXNNNNNNNNNNNNNNNNNNNNNNN    //
//    NXXXXXXXXXXXXXXXXXXXXXXXXXXNXXNXNK0XNNOd0NXXXXX00XXNXk0X0KNXNNNXXNXXXNNNXXXXXXNNNNNNNNNNNNNNNNNNNNNN    //
//    NXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNX0KNXdlKNXXXXXO0NNXxdKX0KNXXXXXXNNNNNXXXXXXNNNNNNNNNNNNNNNNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNX0KN0coXNXXXNK0KXXxckNKOKNXXXXXXXNNNNNXXXXXXXXNNNNNNNNNNNNNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXO0NO:dXXXXXXO0N0xcc0NKOKNXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOKNO:dXXXXXOkKX0Odo0N0OKXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX00XXk;oKXXXKxkXK0K0xONKO0XXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0OKX0o;lkKXX0dONK00KOOK0ol0XXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOKX0kccddk0XXXXXKOx0Ko;,,ckXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX00XX0o:okOKXXXX00XK0O0OdkKX00XXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX00XKxclOKXXXXXX0OXXXKOKKOKXKO0XXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0KXkxxkXKKXXXXX00NXX0x0NK0KX00KXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOKOxOk0XK0OOOkookOOkdoOXXKOKKO0XXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX000k00OXXXXKOd;,kKKKKX0kKXX0KXO0XXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXK00X0OXOOXXXXXX0clKXXXXXKxkXK0KXkkKXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXK0OOOKXKk0XOOXXXXXXKdd0XXXXXXxo0KkkOkk0XXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXX0Okk0KXOkKXOOXXXXXXK00O0XXXXXkloxdddOXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXX0xdxxxOKXX00XXXXXX00XKO0KK0x:..lxdxKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXX0OdldxOXXXX00XXXXXX00XXKd,....;lx0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNXXNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXX0xOXXXXXX00XXXXXKOKXXX0o:lx0KX0OKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNXXNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX00XXXXX00XXXXXK000XK0KOOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNXNNNNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0KXXX0O0XXXXXXXKOOKO0XOxKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0KXXKOk0XXXXXXXXX00KKXKxxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX00XXKOOOKXXXXXXXXKO0XXXkoOXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNXXXXN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOKXXOxkOKXXXXXXXXKOOXX0dxKXXXXXXXXXXXXXXXXXXXXXXXXXXXNNXNNXXXXN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKO0XXKKkkKXXXXXXXXKO0XK0k0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0kKXXXkd0XXXXXXXXXK00KOkOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX00XXKdlkXXXXXXXXXXX0O00OOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK00XKkoxKXXXXXXXXXXX0O0kx0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKO0XXOx0XXXXXXXXXXXX0klldkKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0OKXKO0XXXXXXXXXXXXXOokK0k0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX00XXO0XXXXXXXXXXXXXX0OKX0O0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKO0XOkKXXXXXXXXXXXXXXK00K00O0XXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKO0kx0XXXXXXXXXXXXXXXX0OOK0k0XXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK00kxOOO0XXXXXXXXXXXXXX0O0O0KXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKO0OxKOox0XXXXXXXXXXXXXXXKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXO0000kxkKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKO0K0OKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKXXKKKXXXKKKXKkO0OKXKKKKKKKKXXXKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKOxkOKKKKKKKKKKKKKKKKKKKKXXXXXXXXXXXXXKXXXXXXXXXXXXXXXXXXX    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AWAY is ERC1155Creator {
    constructor() ERC1155Creator() {}
}