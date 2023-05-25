// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMWX0kxddxk0NNX0kxdodxOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMW0d:'........,;'...'''..':xXMMMWNKOxxdxkOKNMMMMMMMWNXXXXNWMMMMMMMMWNK000XNWMMMWXKOkkkdlclokKWMMMMWXOkxxxxxxOKWNKOxdooodxOKNWMMMMMMMMMMWXko:;;;;;:odxkOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMNOc..... ......,:ldkO000kdc..;kKkl;'.......';oONWXOoc;,''',:okKWMMNOl,....';lkXXd,......,;;..'oXMNkc'.........':;...',,''...;oO0Oxxk0XN0l'..............':xXWMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWKl...........,lk0KKKXKKKKXXKk;..'..;ldkOOOkdl,..:c,..,:loolc;..'cOKl..;odxdl:..,;.....'lk0KKOl..cx:.....'cdkOko,..;dO0000Okxl,........,;..... ..;ldkOOOkdc'.,dXXkoox0WMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMWk,... .. ...;d0KKKXK0xc;o0XKKKO:..;xKKXKXKXKXK0x;...:k0KXKKXKKOd;..'..c0XXKXXKk;.......oKKKKKX0l.......'oOKKXKKKd'.:0XKKKKKKKK0l..,xkxo;......'lkKKXKKKKKXKOc..,,..'.'oXMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNd..........,d0KKOddoc,..;dKXKKXKx'.;OXKXKXKKXXXKK0o'.,xKXKKKKXKKK0d,. 'xKKKKKKKXO;.... .dKKKKKKXx' ....;kKXXKKKKKx'.:0XKKKKKKXKX0:.'xKXK0x;...;kKXXKKKKKKKKKKKd'..,xOl..lXMMMMMMMMMMMMMMM
MMMMMMMMMMMMMNd..... ....cOKKX0l... .;x0KXKKKKX0c..dKKKKKK0xdOKKKKx,.,x0KKXXK0xldOOc..c0KKKKKXKKd. ....oKXKKKXKO;....,xKXXXKKKK0c..oKXXKKXKXKKX0:..xKKKKK0l..:OXXKKKKKKKKXXKKKx;;dKX0c..kMMMMMMMMMMMMMMM
MMMMMMMMMMMMWx..........l0KKKKK0x;. .dKKKKKKKKKKl..oKXKKKOc.'dKKKXKd'..';lddl;..:OK0l..c0XKKKKKXk, ....:0XKKKKKO;....dKXKXXKKXKd..:OXKXKOoccloo;..c0KOk0KX0c..l0XKKXK0kk0XKKKKKKKKKXKd..dWMMMMMMMMMMMMMM
MMMMMMMMMMMMO,.........l0KKKKKX0o...,kXKKKKKKXXKl..:dxkxl,..l0XKKKX0l...'.......l0KX0c..oKXKKKKXO;.....,kXKKKKXO;. .l0XXXKKKKKd'..dKKKX0c.  ...';oOkl'.lKKXO;.'xKKKK0l..oKXKKKKKXKKXKo..dWMMMMMMMMMMMMMM
MMMMMMMMMMMXc.........:0XKKKXKKd....,kXXKKKKKKX0:..,..... ..c0XKXKKXk,.,dl.......oKXXk,.,kKXKKKXO;.. ...dKKXXKXk,..;OKKKXKKK0o'. 'xKKKXO;... .lx:,,...,xKKKKx'.:OXXKd. .;OXXKKKKKXKK0c..kMMMMMMMMMMMMMMM
MMMMMMMMMMWx.........,kKKKKKKXk,... 'xKKKKKKKXKx,.;kx;.......c0XKKXX0l..oO:......'xKXKo..lKKKKXXk,.. ...lKXXKKKx' .dKKKKKXKk:....,kXKXXk,.....cko,.....:OKXK0l..oKX0c.  .oKKKKKKKXXKx,.:KMMMMMMMMMMMMMMM
MMMMMMMMMMK:....... .lKXKKKKX0c.... .lKKKXKKXK0c..oK0c........oKXKKKKd..c0k,......:OXXk,.;OXKKKKd. .....:0KKXKKo..;x0KKKK0o'.....,kXKKXx' ....;OXx' ....:OXKKk,.;OXO;....'d0XXKKKXKx;.'kWMMMMMMMMMMMMMMM
MMMMMMMMMMk'........,kXXKKKXKk,......'dKKKKKKOc..:OXO;........;OXKKKXx'.:00:..... .dKX0:.'xXXKX0c. .....,kXXKx:.....'o0Kk:.......;OXKKKd. ... 'xXO;......lKKK0c..dKk'.;d:..:x000Odc..'kWMMMMMMMMMMMMMMMM
MMMMMMMMMNo.... ....c0XKXXKXKo. .......::;;::,..lOKKx' ........dKXXKXk,.;OKc. .....c0XKl..oKKKXk,...... 'xXK0o;:looookKx'........:OXKKKd. ... .dK0:......,kXKKo..lKx'.:00o,..','......oNMMMMMMMMMMMMMMMM
MMMMMMMMMX:.........oKKXXXKX0c..........';:;'..'dKKKo. ...... .oKXKKXk'.;O0:. .....;OXKo..oKKXKo. ... . .xXKKKKKKOOOOKKx,. ......:OKKKKo. ... .dK0c.......oKKKx'.:0O:.c0XK0xolccldkOc..dWMMMMMMMMMMMMMMM
MMMMMMMMM0;....... 'xKKKKKKXO;.......,lk0KKKOd,.'dK0c. ...... .oKXKKKx..c0k,...... 'xKKo..oKXKO;.........cO0KKxc,'..;xKKx;.......:OKXKKo. ... .dX0c.......oKXXk,.;kOkxOKKKK00KXXXXKKk,.;KMMMMMMMMMMMMMMM
MMMMMMMMMO,........,kXKKKKKXO;......:OKKKKKXKKx,.;k0:........ .oKKKXKo..lKd. ......,kX0c..dKKKl. ..........;dOd:;...:OKKKOl......:OXKKKo. ..  'xX0c.......dKKXO;...''';cx0k;,dKKKKKXKl..kMMMMMMMMMMMMMMM
MMMMMMMMMO,........;OXKKKKXXO;.....;OXXKKXKKKX0c..d0:........ .dKKKXO:.'x0c........;OXO:.'xXKx'...;lodxkkd:..;xKO:..:OXXKXKd'. ..:0XKXKl. ....;OXO:......c0XKXk,..:llc,..,,..oKXKKKXKo..xWMMMMMMMMMMMMMM
MMMMMMMMM0,........,kXKKKKKX0c.....oKKKKKXKKXXKo..l0l. ..... .,kXXXKx'.:00:........oKKx'.:OXO:..ckKKXXXKKKKx,.'d0c. 'xXKKKKKx'...:0XKXKl. .. .c0Kd' ....:OKKKXk,.;OXKK0x;.. .dKKXKKXKo..dWMMMMMMMMMMMMMM
MMMMMMMMM0;....... 'xXKKKKKXKo. . 'xXKKKKKKKKXKo..oKx'...... .oKKKXO:..dKKo. .....l0X0c..oKKd..c0XKKXKKXXKKKx,.,xl. .lKKKKKXKx'..lKXXXKl......oK0:....;d0KKKXKd..c0XKKKKO:. 'xXKXKKXKo..xWMMMMMMMMMMMMMM
MMMMMMMMMK:....... .dKKKKKKKXk,.. 'xXKKKKKKKKX0:..dK0o.. ...'o0XKKKo..c0XK0o,..,:x0KKx'.;OXKkllOKKKKKKKKKXKKKo..cl. .;OXXKKKKKd'.;kKXXKl.....'xXKxccok0KKKKKKKl..oKXKKKKXk,..dKKKXKK0c.'kMMMMMMMMMMMMMMM
MMMMMMMMMNc.........:0XKKKKK0k:.  .oKKKXKKXKKKx'.;OXXKxc;,;lkKXKKKd'.;kKKKKK0OO0KKKXO;.'dKXKKKKXKKKKKKKKKKKKXk,.;c.  .oKXKKKKKKo..:OKKKl.....:OXKXKKXKKKXKKKKk,.,kKXKKKKKKd;ckKKKXKKO;.;0MMMMMMMMMMMMMMM
MMMMMMMMMWd..........dKKKKKk:......,xKKXXKKKXO:..dKKKKXKK0KKKKKKKd'.,kKXXXKKKXKKKKKO:..o0KXKXKKKKKKKKKKKKKKKXk'.;c.. .,kKKXKKKK0l..lKXKd'.....ckKKKXXKKKXKKKO:..oKKKKXXKKKKKKKKKXKKKd..lNMMMMMMMMMMMMMMM
MMMMMMMMMM0,.........,kKKXKOdodxdc'..l0XXKKX0c..l0XKKKKKKKKXKKK0o..;kKXXKKKKKKKKKKk:..l0XKKKXKKXKKKKKKXKKKXX0l..lo. . .;kKKKKKKKO;.'xXXKOxxdl,..oKXKKKKKKKKk:..l0XX0xox0KXKXKKXXKKKk,.;0MMMMMMMMMMMMMMMM
MMMMMMMMMMNl........ .;kKKKKKKXKKKOdld0XKKKOc..c0KXKKKKKKKKXKKk:..:OKKKXKKKKKKKX0d,.'o0K0dccok0KXKKKKKKKKXKkc..:kl. ....;xKKXKKXKl..oKXKKKKKXx'..cx0KKKK0kl'..c0XX0l...,okKKXKKXK0o,.,OWMMMMMMMMMMMMMMMM
MMMMMMMMMMM0;..........;xKXKKKKKKKKXXKKXKKk;. .cOKKKKKKKKKKKkc'...ckKXXKKKXKKK0x:..,x00kc.. ..,cokO00KK0Oxc'...::... .. ..cx0KKKk;..dKKKKK0Od;.....,cllc,.. ...:ll;...  ..;clllc:'..;0WMMMMMMMMMMMMMMMMM
MMMMMMMMMMMWk'..........'lOKKXKKKKKKKKKKkc......':okO000Oxl;........:oxOOOOkdc,.. ..;;,... .......',,,,'....................';:;'...;cc::;,........ ...  ... .... ...... .. .... ...lNMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMWk,............:oxO0KKKK0ko:.. .........',,'......... .. ...''..................  . ....  ................  .... .  ..... ..  .  ... .. ...........  ....... ..........'kWMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMW0:...............,;;;;'....'',,,,''......... ... ..',;;;;;,'..................',;;,...... ............,:::,...............';:ccc:;.............,;:;'................;kWMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMXd,................':loxkOO000K00Okdc,.........,lxO0KKKKK0Oko:'...........'lxO0KKKOo,.. ..........;oO0KKK0xc........ ..cx0KKKKXKKx'........'lk0KKKOd:..'ldc;''',;lkXMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWXxc;'...... ...'o0KKKXKKKKKKKKKXXXK0o......'oOKXXKKXKKKKKXXKOl'........lOKXKOkOKKKOxl..........c0KXKKKKKKKd'........:0XKKKKKKKXk,.......:kKXKKKKKX0d,.,kNNXKXNWMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMWNKKOc..  ...dKXKKKKKKKKKKKKKXKKKK0l.  .'xKKKKKKKXKKKKXKKKKKo. ....,xKKKOl'.'o0KKXKo.........dKKKKXKKKXKKo........,kXKKKKKKKKd..... .cOKKKKKKKKKKKk;.'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMWk'......:0XKKKKKXXKKKKKKKKKKKXKl. ..:0XXKKKK000KXKKXKKKKd. ...'xKXXO:. ..,kXKKK0l. .... .oKXKKXKKXKKXO;........lKKKKKKKK0c......;OKKKKKKKKKKKKKk,.;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMK:..... .oKXKKKKKKKKKKXXKOooOK0o'.....;lllcc;'':kKKKKXXKO:.....oKXKKo. ....oKXKKXO;. .....c0XXKKKXXKKX0c. ......,kXKKXKKXk,.....,xKKKKKKKKXKKXXXKl..dWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMk.....  .oKKKXKKKKOllkKXKl..';,...... .... ..;cdOK0kdolc'.....c0XKXk,......c0XKKXKo. .....;kXKKXXXKKKKKl. ..... .dKKKXKKKd. .. .oKKKKKKKKKKXXKKKO:..kWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMNo........;OKKKKKXO:..dKKKo. .  ............,d0XKKO:..........,kKKKKd.......'xKKKXXk,..... .dKXKXKKKKKK0c.........lKXXKKKKo. . .c0KKXKKKKKKKKKXKx;..dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMNl.........;dOKK0k:..c0XKKd. ....;oo:......,xKXKKKo. ....... .lKXKXKl.. .....:OXXKK0:.......lKXKKKKKKKKO;....... .c0XKKKXKc.. .;OKKXKKKKKKKKKKkc...'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMNo...........',;,...l0XKKKx. ...c0XX0o.....dKXKXX0c..........'kXKKKKd'.......:OXXKKKl. .....c0XKKKKKKXKx'....... .c0XKKKKO:. .'oO0KXKKKKKKKKx:......cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMO'...........  ...dKKKKKKx' ..;OKKXK0:...:OXKKXX0:..........c0XKKXXKOdddxkkO0KXXKKKo.......:OXKKXKKKK0l. ...... .lKX0o:,'.......,dKKKKKK0d:........;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMNx'... ..........;OKKKKKXx'  .oKXXKKKd. .oKKKKKX0:........ .oKKKKKKKKKKKXXKKKKXKKKKd. .....;OXKKKKKKXk,..........lKX0l;:cllooooookKKKKOo;..........lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMW0l;'...........c0XKXKKXk'  'kXKKKKXx' ,kKKKKXX0c. . .... 'xXKKKKXXKK0xkKKKKKKXKKKx. .... ,kKKXKKKXKo. .. ......:dxO0KKXK0OkO0KKXXKkc'...........cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWNXKx'........lKKKXKKXk, .;OKKKKKXk, ;OXXKKKXKl........ ,kXKKKXKKX0c.;kXKKKKKKKXx' .... ,kXXKKKKXO:. .............,cd0x,...;xKXKd..... ......;xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,........oKKKKKKXO:..c0XKKKKXOc'l0XKXKKXKo. .......;OKKKKKKXXO;.,kXXKKKKKKXx' .....,kXKKKKKKx'..  ...;coxxxdl;..;ll,...l0XKkl,.......,lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;...... .lKKKKKKKKk:;xKKKKKKXK000KKKKKKKKx' .......:0XKKKKKKXk,.;OXXKKXKKKKx.......,kXKXKKKKl.....;okKKKKXKXKKx;..lo' ..oKXKK0kdc,...lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc...... .lKKKKKKKXKKKKKXXKKKKXKKKKKKKKKXXO;........c0XKKKKKKXk;.,k000KXXKKKd. .....;OXKXKKXO;...;x0KKKKKKKKKXXKOc..,'...'dKKKKXXK0xc'.'o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo........:0KXXKKKXKXK0OkkxkkkO0KKKKKKKKXX0c........c0XKKKKKKX0:..,,',cox0KKo. .....:OKKKKKXk, .o0XKKKKKKKKKKKKXX0c.......,xKKKKKXXKKOo,.'oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx........,kXKKKKKKOo:,'.......'l0XKKKKKKKKo. ......,d0KXXKKKKKo...:c,...o0Kl..... .:OKKKKXXx'.c0XKKKKKKKKKKKKKKKKk,.......;kKXKKXXXKKKOl'.;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,........oKXKKKKKd,,;l;. .;oold0KKKKKKKKXx'.........':d0KKKKK0xdkKKO;..,kKo..';:,..;xKXKKX0xdOKKKKKKKKKKKKXKKKKX0:.... ...;kKKKKKKKKKXKx,.,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.........;OXKKKKKK00KKd. .;OXXKKKKKKKKKKXO:...;dkOxo;..:OXXKKKXXXKX0:..'xX0kxOKK0x,.'xKKKKXKKKKKKKKKKKKKKKKKKKKXO;.',. ....,xKKKXKKKKKXKk,.;0MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMNd'........ .'dKXXKKKKXXKKd. ..c0KKKKKKKKKKKX0c..;OKKKXKKkod0XKKKKKKKKKk,..,kKXXKKKKX0c..oKXKKXKd:;lk0KXKKKKKKKKXXKOc..co' ......l0KKKKKKXKKKl..xMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMNd..........:ld0KKXXKKKXKK0c.....;x0KXKKKKKKKXKl..oKKKKKKKKKXKKKKKKKKXKk:. .oKKXKKKKKOl..;OXXXXKo.. ..;ldO0KKKK0Oxoc'..lOx'........;d0KKKKKKXO;.,OMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMO,....... .dKXXKKXKKKKKXKKo. ......;ok0KXXXXXKO;..oKXKKKKKXKKKKKXKKKK0d,..;o0KKK0Okdc'...,oxkxo:..........,;;:;'.....'ldo;...........;d0KKXKk:..dNMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWo......   .o0KKXXKKKKKKKOl...... .. ..,:lloool,...'cdk0KKKKXKKKXKK0xl,....,;;;;;,'........................... .........................,cooc'..:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWo........ ..,coxkkkkkxo:'. ............ ..... ........,;cloodddoc:'.........  .......................................... .............. .... ..:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWk'...... ..............................................  .......  .................................................. .... .............. ......;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMNd......................':................................................  ........................................ .....:l;..................cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMNk;...... ..... .......xN0l'...............':,....................................................,,........';,.........lXWNOo;..............,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc'...............,kNMMWKxc,...........c0WXOdc;'........ ......cdoc;'.......';lxOkoc:,''''',:oONX0xdllloxKNXOdocccld0WMMMMMNOdc,........;o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdl:;,'''',;:okXWMMMMMMWN0kdlc:ccld0NMMMMMMNX0kdoc:;,,,,:ld0WMMWNXK000000XNWMMMMWWNXXXXXNWMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMWNKOkxxkOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXXXNWMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMWWNNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

I see you nerd! ⌐⊙_⊙
*/

contract CoolKidsWalk is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public maxTokenSupply;

    uint256 public constant MAX_MINTS_PER_TXN = 3;
    uint256 public mintPrice = 0.055 ether;
    uint256 public maxPresaleMintsPerWallet = 2;

    bool public preSaleIsActive = false;
    bool public saleIsActive = false;
    mapping (address => uint256) public presaleMints;

    bool public isLocked = false;
    string public baseURI;
    string public provenance;

    address[5] private _shareholders;
    uint[5] private _shares;

    // replace with merkle root
    bytes32 public merkleRoot = 0xa7226142b67f7c1b77b3997e9cfbb8331d2e518be561419d7d4607b3fe5bafa4;

    event PaymentReleased(address to, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 maxCKWSupply) ERC721(name, symbol) {
        maxTokenSupply = maxCKWSupply;

        _shareholders[0] = 0xaf705c1790719Dbe05663989402ff239f30AeF89; // Coolest Kid
        _shareholders[1] = 0xDc8Eb8d2D1babD956136b57B0B9F49b433c019e3; // Treasure-Seeker
        _shareholders[2] = 0x54d2df18A8445aFA139AE7Cc9423b7eeeB29d08d; // iwakvisual
        _shareholders[3] = 0x6812a0E76607bF63e558cFF5A373EF20d078A3a8; // TheButch
        _shareholders[4] = 0x4Fe33D85730b92640aC20916E72e3b4fd3c4CE26; // Project Wallet

        _shares[0] = 3000;
        _shares[1] = 3000;
        _shares[2] = 3000;
        _shares[3] = 500;
        _shares[4] = 500;
    }

    function setMaxTokenSupply(uint256 maxCKWSupply) external onlyOwner {
        require(!isLocked, "Locked");
        maxTokenSupply = maxCKWSupply;
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setMaxPresaleMintsPerWallet(uint256 newLimit) external onlyOwner {
        maxPresaleMintsPerWallet = newLimit;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function withdrawForGiveaway(uint256 amount, address payable to) external onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 5; i++) {
            uint256 payment = amount * _shares[i] / totalShares;

            Address.sendValue(payable(_shareholders[i]), payment);
            emit PaymentReleased(_shareholders[i], payment);
        }
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        _mintMultiple(reservedAmount, mintAddress);
    }

    function _mintMultiple(uint256 numTokens, address mintAddress) internal {
        require(_tokenIdCounter.current() + numTokens <= maxTokenSupply, "Exceeds max supply");

        for (uint256 i = 0; i < numTokens; i++) {
            _tokenIdCounter.increment();
            _safeMint(mintAddress, _tokenIdCounter.current());
        }
    }

    /*
    * Pause sale if active, make active if paused.
    */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * Pause pre-sale if active, make active if paused.
    */
    function flipPreSaleState() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    /*
    * Lock provenance, supply and base URI.
    */
    function lockProvenance() external onlyOwner {
        isLocked = true;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function hashLeaf(address presaleAddress) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            presaleAddress
        ));
    }

    /*
    * Mint Cool Kids Walk NFTs, woot!
    */
    function adoptCoolKids(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale not live");
        require(numberOfTokens <= MAX_MINTS_PER_TXN, "Exceeds max per txn");
        require(mintPrice * numberOfTokens <= msg.value, "Incorrect ether value");

        _mintMultiple(numberOfTokens, msg.sender);
    }

    /*
    * Mint Cool Kids Walk NFTs during pre-sale
    */
    function presaleMint(uint256 numberOfTokens, bytes32[] calldata merkleProof) public payable {
        require(preSaleIsActive, "Presale not live");
        require(presaleMints[msg.sender] + numberOfTokens <= maxPresaleMintsPerWallet, "Exceeds max per wallet");
        require(mintPrice * numberOfTokens <= msg.value, "Incorrect ether value");

        // Compute the node and verify the merkle proof
        require(MerkleProof.verify(merkleProof, merkleRoot, hashLeaf(msg.sender)), "Invalid proof");

        presaleMints[msg.sender] += numberOfTokens;

        _mintMultiple(numberOfTokens, msg.sender);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(!isLocked, "Locked");
        baseURI = newBaseURI;
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!isLocked, "Locked");
        provenance = provenanceHash;
    }
}