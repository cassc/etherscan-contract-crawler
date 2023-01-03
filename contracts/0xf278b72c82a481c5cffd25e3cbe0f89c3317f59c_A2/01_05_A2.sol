// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A2
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMWXXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXNWMMMMMMMM    //
//    MMMMW0d:,''cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c,,:okXWMMMM    //
//    W0xxo,...:okO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMXXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXOo:...cxxx0W    //
//    o'....:dKNN0dccxXMMMMMMMMMMMMMMMMMMMMMMMMMWXXMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMNkod0NNKx:'...'o    //
//    ,...lONWXxoloxxdxONMMMMMMMMMMMMMMMMMMMMMMMNXNMMMMMMMWNXXWMMMMMMMMMMMWWMMMMMMMMMMMNXNMWXkooxXWNOl...,    //
//    O:,oXWXxoxKWMWKd;.;OWMMMMMMMMMMWNWMWNWMMWWNXNXXKKKXK0O0XWWWWWNNWWNNXXWMMMMMMMMMWO:';dKWMWKxoxXMXo,:O    //
//    MNkololxXMMW0l'. ..;kXWMMMMMMMMWNXXXXXX00O0XXKX0xOXKK0Odlx0O00KXXXNWMMMMMMMMMWXk;   .'l0WMMXxlollkNM    //
//    MMMNk:;o0NKl.. .   .,:OWMMMMWXNNXKKOkOOOXXNWMMMMMMMMMMMNkokOdokOOXWWMMMMWNWMWO:,. .   ..lKN0o;:kNMMM    //
//    MMMMMNkc;:,. .. ......:dONNNNXXXKKxcxNMMMMMMMMMMMMMMMMMMMXOKNNNXKXKKNWNXXNNOd:....  .   .,:;ckNMMMMM    //
//    MMMMMMMNOc'.. ...    ....lOXNNXKXW0kNMMMMMMMMMMMMMMMMMMMMMNXNMMMMMWKkOKNWKl......   .. ..'cONMMMMMMM    //
//    MMMMMMMMMN0o,...  .. ... .'dKKKNMMNNMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMWXkxOd,.......   ...,o0WMMMMMMMMM    //
//    MMMMMMMMMMMWKxc,..   .  ...;d0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0x;...   .  ..,cxKWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNOd;'..   .',;dKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNN0c,'..  ..':d0NMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWKkl;...,;''o0KNWMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMWNXXOc','...;lkKWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNKxlcl:..cx0KOO000OxxkkkOkxxxddxxxkkxookOkxddxkOkOKKOl,;c:lxKNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWXKO:..;loooooxkOxdxkxxxxkOxlcoxxxd::okOkdlcloolldd:.:k0NWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWXOkd,...;loo,,xXNXXXXK00kdl,...,cx00KXXXXXXKOxdoc,'';,;oOXNWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWXkodOOc...'ll'..:0WWNXXXXXXOc.....lKXXXXXXNWWN0o:cc,.;::loclx0XWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWNNOkOKN0l..'':,...'oXWWWNNXNNk'..'..dXNNNNWWWWNxc'.;l:;,,oKX0kdkXXNNNNWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWKx0XXNOl',,...':oddkKNWMWWWXl......lOxooON0kXk,..'cl;;,,dXWWNxdXWWWWWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW0dONNNKd,::...':okOXWWMMMNOo:......:l:..:d,':,..',;;,;::oKNWXlcKMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW0x0XXXKx;cxc,;cokKXXXXKK0xl:;;:::::,,,;:;'...';cc,'..cxcoKXX0oo0WMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWWNNNNWW0xKNNX0x;:ko,.',:llc:;;;;;;;xKKOx0X0c.',,'.'';:;'....lo:dKNWWKOKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWNNNNNNNKOKXK0Ox,.'..'.........;ccox0NW0kKWNOdc;cl;...... ....,;d0XMNOkXMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWXOKOk0Oxc;'.,c'. ...,,';lodkOKKdcxKKOkxdo:,,,...  ....clodkXNdxXNNNNNWWWWWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNKOlck0dlc'.:o,.. ..,;,...,:ldx:.:dl::,...,;,.  ......,''',dOkKWWWWNNNNNNNWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWNN0xxx:;;..lx:;:'.. .... .....,;,..... .... ..';,....;,';lxKNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWWWXd;;''oOxoxxl'.  ..  ...,lolo:......  .'cdo;'..,lloOXWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWO:,,.,k0kkxo:,,'.......;looo;...;c:;,,:ldl,....;dkKWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWNKo;;..:kOO000KK0kxo:..'.....''.:kKNNXK0Okl'....'oO0NMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWXX0oc,..,:cokOKK0000x:;,..'...,lkKK0O00Odc'......:d0WMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWX0Okl,.......,;;;:okkol:.';,.'coxdl:,,,'.... .'..,o0WMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNOl,ckd:..  .;'...;oookkxoc;;;,:oooldd;..';,.....'''cox0XWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWKx:..,cdd:,'..'oo,..;xkdooooolllcccloxOd,..;oc... .:;;c,.'cd0XWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNOl'...,,,lxllo;..ld:,..ckOkxdoxo:dookkOxo,';:co:....'llcc,....,cxKWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMW0o;.  .....;lkxx0l,,lolo:..,ldOkkKklOOdkkx:..':loolo:.;loooc;... ...;oOXMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMXkc....  .....';xdlo;.,codoc;. .;:,:oc,cc,,,,...;llooxk:.'lOOl:,.      ..':dKWMMMMMMMMMM    //
//    MMMMMMMMMMXOo. ......  ..,okkdl:'.,;odlooc'.......  .  ....cOkddxo;..'dKOdl:..    .. ...,o0NMMMMMMMM    //
//    MMMMMMMMMWXkc. ..'.....'oKN0dc:;'ckdlkOxdxo;... .   . ..'cdxkk0Ol,';:dKXXXKkl,...      ...,lONMMMMMM    //
//    MMMMMMMMMMWKc..,,..,''cONMN0d'':cx00OkKKxoxkdl:'...',;:ldkxoddooldk00XWWMMMWXo...      .'okl;cONMMMM    //
//    MMMMMMMMMMMXOxxc,cxlcxXWMMWX0dlcl0WWN0O0OdddkO0x;:ck000OdllodclOK0KNNXWMMMMMMXxc. .  ..c0WMNk;;lONMM    //
//    MMMMMMMMMMMMMWNO0N0kKWMMMMMWNNKk0WMMWNX0OxlcodxkdolkOxdccldkxxO00KWMMWWMMMMMMMMXl. .'l0WMWXxox0OooON    //
//    MMMMMMMMMMMMMMMMMNKNMMMMMMMMMMWNNMMMNXWN0O0xoddooc;:codooO0xxO0O0XWMMMMMMMMMMMMMNkldKWNXOdoxKMW0c..l    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWWN0OkdkdldOOxldxxxkxkKNNNWWMMMMMMMMMMMMMMMMWKkoccokXWXOc.. .,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNMMMWX0xxdclk0xldxxxOKNWMMMMMMMMMMMMMMMMMMMMMMWKxx0X0xc,....,l0    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXXWMMMMMWWX00KKKKKKKXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMWXk:....,:dOXWM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNMMMMMMMMMWWNNNWWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdox0XWMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract A2 is ERC1155Creator {
    constructor() ERC1155Creator("A2", "A2") {}
}