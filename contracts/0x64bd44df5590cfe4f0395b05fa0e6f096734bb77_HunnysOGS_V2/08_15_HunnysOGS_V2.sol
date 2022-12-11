// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**************************** HUNNYS OGS UNLEASHED *****************************
:::::::::::::::::::::::::::::::::::ccccc::::ccc:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::cccccccccccccccccccccccccc::::::::::::::::::::::::::
:::::::::::::::::::::::cccccccccccccccccccccccccccccccccccc:::::::::::::::::::::
::::::::::::::::::::c:;;;;:ccccccccccccccccccccccccccccccccccc::::::::::::::::::
:::::::::::::::::cc:;;cllcc::clcc::;;;;;;;:cllllllllcccccccccccc::::::::::::::::
::::::::::::::cccc;,:ddlllc::;;;;;;,,::::::clllcccllllllccccccccccc:::::::::::::
:::::::::::::cccc:,;ddclol:;;;:loolodxkxxxdddoolllcccllllllcccccccccc:::::::::::
::::::::::::ccccc;,cdlllc;';colcldkkxolcc:::;,;:cc:;;:clllllllccccccccc:::::::::
::::::::::ccccccc;,ldolc:';ddoldkkdlcclloooddoooddol:;,;cllllllccccccccc::::::::
:::::::::cccccccc;,lxdl;,,ldlokOkocclodxxxddxxxxddxxxdc,.;lllllllcccccccc:::::::
::::::::ccccccccl;,lxo:,:c:clxOOo:coxxxxxdodxxxdloxxxxdl;';lllllllcccccccc::::::
:::::::ccccccclll;,lxo;':oooolll;:oxxxdolldxddxocoxxxxxoc:,:llllllllccccccc:::::
::::::cccccccllll:'cxo;;dOOOOkoc:coxxxocloddlodlcodddddo:c:;lllllllllccccccc::::
:::::ccccccccllllc,:dlcdOkxxkkOdlccoxdccool:;c:;:clllool:::;llllllllllccccccc:::
:::::ccccccclllllc,;dllkkxxkxxkkolcclc,',',,:loodddooc;;,;::clllllllllccccccc:::
::::ccccccclllllll;,olokxxxxOxxOxll:;cc;,,''..';lOOo,..'',odccollllllllcccccc:::
::::ccccccclllllll:,llokxxxxkxxkxll:,ooc::ccc::lxOo,.,c:':kklclllllllllccccccc::
::::ccccccclllllllc,:olxkddkkdxkxll:;xd,...:dxxO0o,..:l;'lkOoclllllllllccccccc::
::::cccccccllllllll,;olokkxxxxkOdll,:kxlcloxkO000dccldxc,oOOoclllllllllccccccc::
::::cccccccllllllll;,ol:lkOkkkOxllc,ckolox00000O0Ododk0d,lOklclllllllllccccccc::
::::ccccccclllllllo:,loccldxkxdlc;;;lO0OO00000kdxddddk0o,ckxcclllllllllccccccc::
::::cccccccllllllllc,cocclc:;::::,,:o000000000Odlloooxd:;cxl:llllllllllcccccc:::
:::::ccccccclllllllc;:occll:;ll:cc,;o00000000Odccc:;,;;,,;ccllllllllllccccccc:::
:::::cccccccllllllll;:oc:ll:;ll;:c,;coxO00000Oxddl;'':c;,;collllllllllccccccc:::
::::::ccccccclllllll;:oc:cl:;ll:;;;dOdooooxk0000Oko;coc;';llllllllllcccccccc::::
:::::::cccccccllllll;;lc::lc;cc;;,ck000Okdc:lodddoccloc,,:lllllllllcccccccc:::::
:::::::cccccccclllll:;cc;:cc;c:;;;d000000d:clccccclloo:,,clllllllllccccccc::::::
:::::::::cccccccclll:;c:;;::;;:,;oO0000Okl:looooooolll;';llllllllcccccccc:::::::
::::::::::cccccccccl:;::;;::,';;oO00000Oxc:lolllllllll,,clllllllcccccccc::::::::
:::::::::::ccccccccl:,::;;::',loddxkO00OOo;::ccllllll:,:llllllccccccccc:::::::::
:::::::::::::ccccccc:,;;,;:clxO00kxdddddxdocclooc:clcc:clcclccccccccc:::::::::::
:::::::::::::::ccccc:',cdxkO000000000Okxxxxxl;:loloolc:;::;:ccccccc:::::::::::::
:::::::::::::::::ccc;,oO0000000000000OOkkkxdo:;:cllddcclodc:;:cc::::::::::::::::
::::::::::::::::::c:,lO00000000kxkOkxl:::cccloolllc::ldkkkkxl,;:::::::::::::::::
:::::::::::::::::::,,d00000000klcdl:ccldxxkkkkkkkkkdoxkkkkkkkl,;::::::::::::::::
::::::::::::::::::;;:x00000000x:,::oxkkkkkkkkkkkkkkxlokkkkkkko;;::::::::::::::::
:::::::::::::::::;:dddkO000000x,'lxkkkkkkkkkkkkkkkkklokkkkkkkl;;::::::::::::::::
:::::::::::::::::;:d0Oxxxxxxxkd:lkkkkkkkkkkkkkkkkkkdcdkkkkkko:;:::::::::::::::::
:::::::::::::::::;codxkkkkkO0Kklxkkkkkkkkkkkkkkkkkdcokkkkxlc;;::::::::::::::::::
:::::::::::::::::;;lOOxxxxkO0kccxkkkkkkkkkkkkkkkko:okkkko;';::::::::::::::::::::
*/

import "./FlickDropNFT.sol";

contract HunnysOGS_V2 is FlickDropNFT {
    constructor(
        address feeReceiver,
        uint96 feeBasisPoints,
        string memory baseURI
    ) FlickDropNFT("Hunnys OGs", "HUNNYS-OGS", feeReceiver, feeBasisPoints) {
        setBaseURI(baseURI);
    }
}