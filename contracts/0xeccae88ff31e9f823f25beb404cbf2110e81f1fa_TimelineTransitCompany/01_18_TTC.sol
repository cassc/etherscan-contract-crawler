//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/*
8%B%%%%%B%%%%%88%@@@@@@@@@@@@@@@@@%88888888888&&&8&&&&&8&W&W&&&&&&&&&&&&&&W&W&&&&&&&&&888888888888888888888888WW8888&WW&88&W&&&&&&&&&&WWW&&&&&%@@@@@@
888888888888888888888888888888888888888888888&&8&&&&W&88&WMW&&&&&&&&&8&&&&W&W&&&&&&&&&&&&&&&&&&888888888888888&WWWWWMW&[email protected]@@@@@@
888888888888888888888888888888888888888888888&&&W8&M&8&W&8&8%BBBBBBBB88&&WW&W&&&&&&&&&&&&&&&&8&&&&&&&[email protected]@@@@@@
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&888888&&&&&&W&M8&W&M&&[email protected]@@@@@@@@B8&W&&W&M8&8&&8&&&&&WMWWWWWWWWWWWW&[email protected]@@@@@@
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMW888&&&8&&MMWW&WMW&&M&&8BBBBBBBBBB8&W&WM&MuI[Q88&&&&&W&&&&&&&&&&&WW&8&&&[email protected]@@@@@@
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW&&&&&&&&WMMMW&&&&&&M&&8BBBBBBBBBB8&W&Wab-x00h&&&&&&&&&&&&&&&&&&&&W&88&&&&&&&88888888888&&&&&&&&&&&888&[email protected]@@@@@@
8888888888888888888888888888888888&&&&&&8888&&&&W&M#MW&M&&[email protected]&W&jvY0000h&&&&&&&&&&&&&&&&&&&&&&88&&&&&&&&888888888&WWWWWWWWWWWWWW&[email protected]@@@%%B
888888888888888888888888888888&&&&&&&&&&[email protected]%&&&&M#MW&&&&&&&&&&&&&&&&&Zr0000000h&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&88888&WWWWWWWWWWWWWW&88888888888
[email protected]@@@@B8&&&&&&&&&&&8%BBBB8&&&&&&&&&&&&&&&&&&&&&8I|0O000000h&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&88&&&&&&&&&&&&&&&&88888888WW8
BBBBBBBBBB%%%%%%%%%%%@@@@@[email protected]&&&&&&&&&&&&&%BBBBBBBBBBB8&&&%BBBBBBBaL|0000000000aBBBB8&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&8&&8
@@@@@@@@@@@@@@@@@@@@@@@@@@@@B8&&&&&&&&&&&&&8%BBBBBBBBBBB&&[email protected]&&&&%%%%%%%%8&&&&&&&&&&&&&&&&&&&&&&&&WWW&&&&&&&&&&&&W&&&&&&&&&&
@@@@@@@@@@@@@@@@@@@@@@@@@@@@B88&&&&&&&&&&&&&&%BBBBBBBBB%&&&%B%BBjz0O000000000000aBB%8&&&&&&%BBBBBBBB8&&&&&&&&&&&&&&&&&&&&&WMM&&&888888&&MMMMMMWWMMMM8
@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@B8&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&W&wr0Yr[(rr|[[|r[[[III[Q&&WWW&&&&&&&8BBB8&&&&&&&&&&&&&&&&&&&&&WMM&&&888888&&MMMMMMMMMMMM8
@@@@@@@@@@@@@@@@@@@@@@@@@@@@B8&&&&&&&&&&&&&&&&&&&&&&WWWppmwuI>]rrrrrrrunrrnvvnrrrrr}~~]11Ymppp&&&8B%%&&&&&&&&&&&&&&&&&&8&&W##&&&&&88888&MMMMMMMMMMMW8
@@@@@@@@@@@@@@@@@@@@@@@@BBBBB8&&&&&&&&&&&&&&&&&&W&WWxrx}{|-~I[)rrrrrcC0LCCXvvXJrrrrrrrrrr/(tttjrr&&&&&&&&&&&&&&&&&&&&&&&&&WMM&&&&&&&&&&&&&&&&&&&&&888
@@@@@@@@@@@@@@@@@@@@@@@@[email protected]&&&&&&&&&&&&&&&&&&W)}}lIl[)r[_I[(rrrrr|}0u[[x00x[rrrrrrrrrrrrrrrrrj[[{WW&&&&&&&&&&&&&&&&&&&&&&8&&&&&&&&8888888888888888
@@@@@@@@@@@@@@@@@@@@@BBBBBBBB8&&&&&&&&&&&&&W&&({{{?IIII[)r[_I[)rjrjrjrrrrr([[|rrrrjrrrrrrrrrrrrrrrrj[[1&W&&&&&&&&&&&&&&&&&&&&&&&&&&&&&888888888888888
@@@@@@@@@@@@@@@@@@BB&&&&&&&&&&&&&&&&&&&&W#d({{{}?lIIIII[)r[_I|jvvvv000000000000000uuvvvvrrrrrrrXJrrrrrj11|dM&&&&&&&&&&&&&&&&&&&8&&&&&&&&&&&&&&&&&&&&&
@@@@@@@@@@@[email protected]@@@BB8&&&&&&&&&&&&&&&&&&&W&cj{{{{[?IIIIIII[)rXXc00000OoooooooooooooooO00000JCJrrrrrrrrrrrrrrrtjvWW&&&&&&&&&&&&&&&&&&&&&&&&W&8&MWWW&WW&MM
@@@@@@@@@@@@@@@BB&&&&&&&&&&&&&&&&&&&&&h}{{{})r}-IIIIIII000000MM#MM##MMMM*WW*######MM#WWW000000rjrrrrrrrrrrrrf[k&&&&&&&&&&&&&&&&&&&&&&&&W&&&W&&W&WW&WW
@@@@@@@@@@@@@@@BB&&&&&&&&&&&&&&&&&MMWt}{}{}[{r}-IIIIQ00000MM****##**MWWW*WW*M###MWMMWWWWWWW000000rrrrrrrrrrrrr{/&&&&&&&&&&&&&&&&&&&&&&&&&&&&W&&W&&WW8
88888888888888888&&&&&&&&&&&&&&&W&dO}{{)jf[[{r}[?Q00wwqWWW*M****##**#WWW*WM#WWWWWWMWWWWMWWWWWWqww00QvxrrrxJcuurj1Zb&&&&&&&&&&&&&&&&&&8&&&&&MM&&MW&MM&
WWWWWWWWWWWWWWWWWWWWWWWMWWWMMMMMar)}}/rCxt[[1rXU0hhh######*######***#*##*MMWWWWWWWWWWXujXnjjqWWMMooo0LJrrrjCLvUUrttr*W&&&&&&&&&&&&&&&8&&&88&888888888
WWWWWWWWWWWWWWWWWWWWWWMMMMMMMMWj{}{1rrrrrf}[|00m#M########*#########*M*#*#########rrr0000000t][mWW&&Ww00urrrn00Lrrrj{f&&&&&&&&&&&&&&&&&&&&&&&&8888888
8888&&&&&&&&&&&&&&&&&&&&&&&&&&&j}{frrrrrrf[C00#W#MWWWW#*#W*WWWWWWWWMWWWM*MWWWMWMQr000rrjrrrrU00t{WWWWW#0OLrrrrru0nrrrX&&&&&&&&&&&&&&&&[email protected]@@@@@@@@@@B%
%%%%888888888888888888888888&#{1(rrrrrrruz0wpWMMWWWWWW#*#W*WWW*bqqpjjjYLmYQwqqqjY0rrrrnu0XvrrrrJQ1d%&W#Mpw0zurrrrrrrjf1*&&&&&&&&&&&&&&[email protected]@@@@@@@@@@@@@
@@@@@@@@@@BBBBBBBBBBBBBBBBBBYrtjrrrrrrnC0ZoWWWWWM#####*##W*0{jYbwqwM*###*MW8%pYCXurrrJQ0000JurrnvCun&WWWW#aZ0CnrrrrrrrrrX&&&&&&&&&&&&&[email protected]@@@@@@@@@@@
@@@[email protected]@@BBBBBBBBBBBBBBBBBB%YrrC00nrrrn00mMMMMMMMMMMMMMM#M[vMWM#WW##WWWMWWW8%Or0zrrY0000000000rrr0t1WWWWWWWm00nrrrrrLCrrY&&&&&&&&&&&&&[email protected]@@@@@@@[email protected]@@@
888&&&&&&&&&&&&&&&&&&&&&&&#[trrC00urrL00#WWMMWWWWWWWWWMMZ[&MWWMWWWWMMMWWWWW8%J[0zrrrrrrr0crrrrrrr0vxWWWWWWW&#00Lrrrrrrrrt[#&&&&&&&&&&&[email protected]@@@@@@@[email protected]@@@
8&&&&&&&&&&&&&&&&&&&&&&&&kqrrrrrrrrrvLOw#WWWWWWWMWWWWomXOMWWWWWWWWWWWMMMMMW&8mvYurrzJ0LC0LJJJJrrxXjtWWWWWWWW#w0LvrrrrrrrrrZd&&&&&&&&&&[email protected]@@@@@@@@@
8&&&&&&&&&&&&&&&&&&&&&&&WXtrjrrrrrrn00mWWWWWWWWWWMMW{jZMMMM#########MMMMMWWMW#*]|rrrruYC0crrrrrrr[Z#WWWWWWWWWWm00nrrrrrrrr?f&&&&&&&&&&[email protected]@@@@@@@@@@
WWWWWWWWWWWWWWWWWWWWWMMWWYjrrrrrrrC00oMM##MMM#####0I*###*###*Moooo*#*#******#MWQr[rrrrrr0crrrrr)}0aMWWWWWWWWWWW*00CrrrrrrrrY&&&&&&&&&&&&[email protected]@@@@@@@@
MMMMMMWMMMMMMMMMMMMMMMM*[trrrrrrrrC00o#*#######**i1*********o******oo******MM#MMd0[[[rrrrrrr)[[z00aWWWWWWWWWWWW*00Crrrrrrrr(l#&&&&&&&&&&&&[email protected]@@[email protected]@
MMMMMMMMMMMM#M#########*1fruxrrrn00ZMMMMWWWWWWWom1xWWW*MMMMMMMMWWMMMMMqqqdqqbbbWMMwwm|///|/|JwwoMwhoWWWWWWWWWWWWWm00nrruurrt[qk&W&&&&&&&&&&&&&8888888
WWWWWWMMMMMMMMMMMMMM#MM*rrruxrrrn00Z****WWWWWWWZI*MWMW#WM#########*jfjtnXJUXJcjXXXM#Maooaaaa#MMMMMCcMMMMMMMMMMMMWZ00nrruurrjtYn{WWW&&&&&&&&&&&&&&&&&8
&&&&&&&&&&&&&&&&&&&&&&x}rrrrrrrrx00Z****WWWWWMWZI*WM#MW##MMMMMMMMQ[rz00pM*#M*p00zrrZ*##*****####*#Yn###########MMZ00xrrrrrrrrrv0l(MMMMMMMMMMMM&&&&8&8
&&&&&&&&&&&&&W&&&W&&&&x}rrrrrrrC00a#****WWWWWW)jMWWMMM#MM#MMMMMM])r0q#M#M*#Mooooq0rrroooooooo*****oo0h*********###[email protected]@@@@@WMWMMMMMM
&&&&&&&Zu|ru|||vvv/[??}1rrrrrrrC00*WMMWMMMMM#M1jM#MM#MM#MM#kZ0OZ-(v##M##M*#Mo*MWMM0zrb*WMdZmwqpmmmmOc0mpqqpqqZmmmm0cvvruvvvvvrv0000/[email protected]@BBBWMW&[email protected]
&&&&&&&M*0000000000000vrrrxJnrrC00o###########rc###MM#MW#*}jOOv-cU0{zo#MMjfj###MMMamJrm#jJZZwqqmmZZ0IIIi?[[[[-!IIlIIIl~--?|[email protected]&[email protected]@@
WWWWWWWWWWp00000000000vx0000urrC00o###########)j####MM#MLI[+II<[I<[[+llIIrjr[[[[[[[[[[[[[[[IIIl-[[>lII>MMMMMMMMMM_+00zIIIII]0xv00000000c[[email protected]&MM&[email protected]@@
&&&&&&&&&&&&0000000000vx0/{00QrC00*WWWWWMMMMMM(rMMMMMMMWO[]_lI<[I<[[[[[[[rjr[[[[[[[[}[[[[[[[>IIll[[]II>M#MMWMWWWW_+00zIIIIli[rv00000000O0[XBWM&[email protected]@@@
&&&8&&&&&&&&&kw0000000vx0Xc0UXrC00*WWWWWWWWWWMnXWWWWWWMWWMjcZZc[cCqjLM*MMjjjo*oMMMamJrwMjLqqqqpwmmmO[<iilllIIl_-[[?iIl~-??|x0xv0000000O000JvhaW&%BBBB
&&&&&&&&&&&&&&&ow00000vr||/0xtrC00*WWWWWWWMWWWnYWWWWWMMW88Mawqpd(rX8WM*MMM##o*oWMM0zrboWMkqqqqqmmZZO}LwqmmZZZZmmppmYcvr/|||||rv0000000000000JqWWWWW&&
&&&&&&&&&&&&&&&&&&0000vrrrj[trrC00*WWWWWWWWWMWWZI*WWWWMMMMM&8%88rrr0dM*MMM#Mo*oMd0rrrMMWMMMMMWMMWMx1#M#MMWWWWWWWWW*00CrrrrrrrQw&&&&&&&&&&&&&&W&WWW&W&
&&&&&&&&&&&&&&&&&&&p00vrrrrrrrr{1O0ZWWWWWWWMWWWZI*WWMWMMMMMW8888%qrrz0QdMM#MopQ0zrrmMWMMMWMWWWWWWMx1#M#MMMWWWWWWWZ001{rrrrrrrQw&&&&&&&&&&&8&&W&&MM&&8
&&&&&&&&&&&&&&&&&&&&&wO0rrrrrrr((00mWWWWWWWWWWWp{OpWMWWWMMMMMW88888YXXrcJJJJJcrXXzMMMMMMMMMWWWWWWbLY##*MM########Z00|(ruurrv0W&&&&&&&&&&&&&&&W&&MM&&8
&&&&&&8&&&&&&&&&&&&&&&#oJurrrrrrn00ZWWWWWWWWWWWWWi1MWWWWWMMMMWMMMMMMMWbbbbbbbbb##########MMMMMMM#rp#MWMMWMMMMMWWMZ00nrruurrv0W&&&&&&&&&&&&&&&W&&MM&&8
&&&&&&8&&&&&&&&&&&&&&&&W0vrrrrrrj[U00*WWWWWWWWWWWMa0MWWWWWMMMMMMMMMMMM**########**#######*#**o#Yr###*MW8%%%%%%%W00U[jrrrrrrv0MWWWWWWWWWWWWWWWM&&MM&&8
888888&&&&&&&&&&&&&&&&&W&wQrJQrrrrJ00*WWWWWWWWWWWMWW!(W&WWWWWM*MMMMMMM*&8888M&8&&MMMMMMWW#W##*rpWWMM#MW8%%%%%%BW00CrrrrrrrQqWWWWWWWW&&&&&&&&&&&&MM&88
@@@@@@@@BBBBBBBBB&&&&&%B%pQrjrrrrr)|00mWWWWWWWWWWWWWWomo*WMWMM**MMMMMM*&8888M&8WWMMWWWWWW#WdCXWWWWWW#MW8%%%%%%m00|)rrrrrrrQq###############MMMMMMM&88
@@@@@@@@BBBBBBBBB&&&&&%B%#oCnrrrrrrj|COw*WWWWWWWWWWWWWWamjXx}jJ*#MMMMW*###########**###*#Ujdo*WWWWWW#MW8%%%%&qOC|jrrUYrrnCa#WWWWWWW&&&&&&&&&&&&&&8&88
@@@@@@@@@@BBBBBBB&&&&&%BBB80urrrrrrrrC00#WWWWWWWWWWWWWWrc00O00v[M#WWWWWWWWWWWMWWWM##W##*[QW#M*WWWWWW#MWWW8%%&00CrrrrrrrrvOM&&&&&&&&&&&&&&&&&&WW&&8888
@@@@@@@@@@BBBBBBB&&&&&%BBBBBwQrrrrrrr{(00mWWWWWWWWWWWWWrc0rrr0UrMMW&8888888888WWWWW##r([W#W#M*WWWWWWMW&%&W&m00({rrrrrrrQq&WW&&&&&&&M&&&&&&&&WW&W&8888
@@@@@@@@@@[email protected]&&&&&%BBBB%bmuxrrrrr--vQmoWWWWWWWWWWWWvxtt/(ft/000*###oa#oaaahh0Xrjj#M*##*M#*MWWWMW8&&8&WomQY|)rrrrrxvmdWW&&&&&&W&&&&&&&&&&&&8&88888
@@@@@@@@@@@@BBBBB&&&&&%BBBBBB80urrrrrrj(?10mdWWWWMWWWMMopYYXcYOhaao####oh#ohhhhhM8WWWW#*#WMWWW&&&W8%%&W&dw0j/tjrrrrrru0MW##W&&&W&&&8BBBBBBBB8&8888888
[email protected]@@@@@@BBBBB&&&&&&%BBBBBB%wQrrn00Crj|IJ00*################*MMW&88888888888888WWWWM##&%%%%%%%%%8WWM00C[trrru0nrrQm#WW##W&WW&&[email protected]@@@@@&&&888888
88888%@@@@@@@BBBB&&&&&&&&888&&&&#0nn00Crrf[!_00wWWMMMMMMMMMMMMMM#MWWWM&88WWW88W888WWWW&8%%%%%%%%%8W&Ww00|}rrrrrrrru0o#M#MMMMM&&&[email protected]@[email protected]@@@@@@&&8888888
WWW&88%@[email protected]@@@BB%&&&&&&&&&&&&&&&&Mwzurrrrrf[[]~uX0oooW&WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWooa0UX1frrrrrrrruzwM&&&&&&&&&&&@@[email protected]@@@@@@&88888888
888W88%[email protected]@@@%&&&&&&&&&&&&&&&&W&&&*hJxrrrf[[{r?-?Q00wwwWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWwww00Q/ttrYCJnrrjxJa*&&&&&&&&&&&&&[email protected]@@@@@@@&88888888
WWW888%[email protected]&&&&&&&&&&&&&&&&&&&&&&&&&wLrjf[[1r}-IIIIQ0000OWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW00000Q[[}rrrrC00ujrLmMMMMMMMMMMWWWM&&[email protected]@@@@@@@@@888888888
88888888&8&&&&&&&&&&&&&&&&&&&&&&&W&&&W#0nf[[{r}-IIIIIII000000WWWWWWWWWWWWWWWWWWWWWWWWWWW00O000[[[jrrrrrrrrrrn0#WMWWWWWWWW&&&&M&&[email protected]@@@@@@@@B888888888
888888888&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&pQ|/tr}-IIIIIII>>~ccc000000oooooooooooo*oo000000XYY111rrrrrrrrrruvuOp&&WW&&&&&&&&&WW&W&&@@@@@@[email protected]
88888888888&&&&&&&8&&&&&&&&&&&&&&&&&&8%%%8M*kC{-IIIIIII[)r-~I????}|000000000000000||||||tttrrrrrrrrrrrxCkooW&&&WW&&&&&&&&&WW&W&&BBBBBBBB8888888888888
88888888888&&&&&&&&&&&&&&WMMMMMMMW&&&BBBBBBB%&O00x)IIII[)r[_I[)rrrrIIII~[I~[[[[[[[rrrrrrrrrrrrrrrrrx00O&&&&&&&&WW&&&&&&&&&W&&W&&&&&&&&888888888888888
88888888888888&888888&&&W&BBBBBB%MW&&BBBBBBBBB8&WO00!Il[1r[_I])rrrrrrrrrrrrrrrrrrrrrrrYQrrrrrjrrr00O&&&&&&&&&&&&#MMMMMMMMW&&W&&&&&&&88&WM888888888888
&MMWWWWWWMMMMMMMMMMMMMM&W8BBBBBBBM&&&BBBBBBBBBB%&WWWwww|fu|[I[)rrrrrrr0CYYC0YYY0zrrrrrrjrnuuvuwww##*&&&&&&&&&&&&W&&&&##MMMMMMMMMMMMMMMW8&W88888888888
&WMMMMMMMMMM#WMWW8W&&&W&W&BBBBBBBM&&&BBBBBBBBBBBB%&W#*#o*aomcYUJJzrrrr|/tYC0Ynt/frrrrrzJJqhaahMM#M##&&&&&&&&&&&&W&&&&MM&&&&&&&&&&&&&&&&&&&&8&W&&&8888
&WWWWWWWWWWWW&MWW8W&8&W&[email protected]@@@BBM&&&BBBBBBBBBBBBBB%&W#&&#W******b00Yrrrr[[[[|rrrrrY00kMMMMMMMMMM###&&%BBBBBB%&&W&&&&MM&&&&&&&&&8888888888888&&W&8888
&W&&&&&&&&&&&&&&&8&&&&W&[email protected]@@@BBM&&&BBBBBBBBBBBBBBBB%&&&#W******#&&k0000000000000rY0##########W&MW#&%[email protected]%&&W&&&&MW&&&&&&&&&888888888888888888888
&WWWWWMMMMMMMMMMMMMMMMM&W&BBBBBB%M&&&BBBBBBBBBBBBBBBBBB&&M&W####MW&&k0000000000JXvwoWM##M&WW&WW&&WW#&BBBBBBBB%&&W&&&&MW&&&&&&&888888888888888&WW&8888
@@@BBBBBBB%8888888888888&&WWWWWWW&8&&BBBBBBBBBBBBBBBBBB&&WWWWWWWWWWMk0000O000YuCp*WW&MMWMM&MM&WMM&&#&BBBBBBBB%&&W888&MW&&&&&&&&&&&&&WM&&&&&&&&&&&8888
@@@@@@[email protected]%88888888888888&&&&&&&&&&&&BBBBBBBBBBBBBBBBBB&&WMMMMMMMMMMb0000000rX0&WM&&&&M#MM*MMM#MMMMM&[email protected]%&&MWWWWMM&&8888888888&WW888888888888888
@@@@@@@@B888888888888888888888&&&&&&[email protected]@@@BBBBBBBBBBBBB&&M##########b00000Yx0d###M#M&WM#&M*W&##W&&&&&[email protected]@@@B%&8&&&&&&MW88888888888&WW&WWWWWWWWWWWWWW
@@@@@@B%8&&WMMM88&888888888888888&&[email protected]@@@@@@BBBBBBBBBB&&M&&&&&&&&&&h00LCuCw&&&&&&MM&WMM&WMW&#MW&&&&&[email protected]@@@@@B%&&W&&&&&MW888%%%88888&WW888888888888888
@@@@@%88&&8&&88&&8&&&&&&[email protected]@@@@@@@@@@@@@@BBBB&&M&#WWWWWWWWwvuXC*#WM#&&&&#M&&&&&&&&&&&&&&&&&[email protected]@@@@@B%&&[email protected]@@@B88&&&&&&&&&&&&&&&&&&&&
@@@%88&&88&88&W88&&888&#[email protected]@@@@@@@@@@@@@@@@@@@@@&&M&M&&&&&&&&h00b&&&W#W&&##W&MMMMMMMMMMMMMMM#&[email protected]@@@@@B%&&WWWWW8&&[email protected]@@@B8&W8W88888888888&&W888
88888W88&&&WW88&&88888W&[email protected]@@@@@@@@@@@@@@@@@@@@@&&M&#MMMMM#M#####MM#W&&M#M&WM&&8&&&&&&&&&&&&#&[email protected]@@@@@@%&&WW8W&[email protected]@@@B8&W8W88888888888&&W888
&88&&8&&88WW&88&W&&&&&&&8888888888888888888888&&888888&&&M&&&&&&&&&&&&&&&&&&W#M&W#W&&&&&&&&&&&&&&&&#[email protected]@@@@@@%8&&W8W&8%%%@@@@@B8&W8W88888888888&&W888
8&&88WWWW&888888888888888888888888888888888888888888&&&&&MMMMMMMMMMMMMMM####W&&[email protected]@@@@@@%8&&W8W&[email protected]@@@@@@B88W8W88888888888&&W888
8888WWWWWW88&WWWWWWWWWWWWWW&88888888888888888888888888888&8&88888888888&&&&&88&8888&&&&[email protected]@@@@@@%8&&W8W&[email protected]@[email protected]@@@B88W8W88888888888&&8WWW
*/

// Contract by: @backseats_eth
// Audited by: @SuperShyGuy0

contract TimelineTransitCompany is ERC721A, ERC2981, Ownable {
    using ECDSA for bytes32;

    // Since TTC rebooted as a free mint, we're making good with our original minters, so this is the supply before we make them whole
    // Total supply of collection below
    uint256 public constant REBOOT_SUPPLY = 8_929;

    // There are 9,999 Timelines
    uint256 public constant MAX_SUPPLY = 9_999;

    // Max mints per transaction
    uint256 public MAX_MINTS_PER_TXN = 3;

    // An address can only mint 4 Timelines
    uint256 public MAX_MINTS_PER_WALLET = 4;

    // Tracking nonces used to provent botting
    mapping(string => bool) public usedNonces;

    // Tracking how many tokens an address has minted
    mapping(address => uint16) public mintCountPerAddress;

    // The address of the private key that creates nonces and signs signatures for mint
    address public systemAddress;

    // The URI where our metadata can be found
    string public _baseTokenURI;

    // If the team has already minted their reserved allotment
    bool public teamMinted;

    // Whether the mint is open
    bool public mintOpen;

    // A boolean that handles reentrancy
    bool private reentrancyLock;

    // Modifier

    // Prevents reentrancy attacks. Thanks LL.
    modifier reentrancyGuard {
      if (reentrancyLock) revert();

      reentrancyLock = true;
      _;
      reentrancyLock = false;
    }

    // Constructor

    constructor() ERC721A("Timeline Transit Company", "TTC") {}

    // Mint

    /**
    * @notice Requires a signature from the server to prevent botting
    */
    function mint(uint _count, string calldata _nonce, bytes calldata _sig) external reentrancyGuard() {
      require(mintOpen, "Mint closed");
      require(msg.sender == tx.origin, "Real users only");
      require(_count <= MAX_MINTS_PER_TXN, "Per txn amount exceeded");
      require(mintCountPerAddress[msg.sender] + uint16(_count) <= MAX_MINTS_PER_WALLET, "Wallet mints exceeded");
      require(totalSupply() + _count <= REBOOT_SUPPLY, 'Exceeds reboot supply');
      require(!usedNonces[_nonce], "Nonce already used");

      require(isValidSignature(keccak256(abi.encodePacked(msg.sender, _count, _nonce)), _sig), "Invalid signature");

      usedNonces[_nonce] = true;
      mintCountPerAddress[msg.sender] += uint16(_count);

      _mint(msg.sender, _count);
    }

    /**
    * @dev Returns an array of token IDs owned by `owner`.
    *
    * This function scans the ownership mapping and is O(totalSupply) in complexity.
    * It is meant to be called off-chain.
    *
    * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
    * multiple smaller scans if the collection is large enough to cause
    * an out-of-gas error (10K pfp collections should be fine).
    */
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
      unchecked {
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        uint256 tokenIdsLength = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);
        TokenOwnership memory ownership;
        for (uint256 i = 1; tokenIdsIdx != tokenIdsLength; ++i) {
          ownership = _ownerships[i];
          if (ownership.burned) {
            continue;
          }
          if (ownership.addr != address(0)) {
            currOwnershipAddr = ownership.addr;
          }
          if (currOwnershipAddr == owner) {
            tokenIds[tokenIdsIdx++] = i;
          }
        }
        return tokenIds;
      }
    }

    // Internal Functions

    /**
    * @notice Tokens are numbered 1–9,999
    */
    function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
    }

    /**
    * @notice The baseURI of the collection
    */
    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    /**
    * @notice Checks if the private key that singed the nonce matches the system address of the contract
    */
    function isValidSignature(bytes32 hash, bytes calldata signature) internal view returns (bool) {
      require(systemAddress != address(0), "Missing system address");
      bytes32 signedHash = hash.toEthSignedMessageHash();
      return signedHash.recover(signature) == systemAddress;
    }

    /**
    * @notice Allows team to mint timelines to specific addresses for marketing and promotional purposes
    */
    function promoMint(address _to, uint256 _amount) external onlyOwner {
      require(totalSupply() + _amount <= MAX_SUPPLY, 'Exceeds max supply');
      _mint(_to, _amount);
    }

    /**
    * @notice A one-time use function. Reserves 500 for the team, and 570 used to
    * make initial minters whole + a bonus and raffle supply for OG Discord members
    */
    function teamMint() external onlyOwner {
      require(!teamMinted, "Already minted");
      require(totalSupply() + 1070 <= MAX_SUPPLY, 'Exceeds max supply');

      _mint(msg.sender, 1070);
      teamMinted = true;
    }

    // Ownable Functions

    /**
    * @notice Sets the system address that corresponds to the private key signing on the server.
    @dev Ensure that you update the private key on the server between testnet and mainnet deploys and
    that the address used here reflects the correct private key
    */
    function setSystemAddress(address _systemAddress) external onlyOwner {
      systemAddress = _systemAddress;
    }

    /**
    * @notice Sets the baseURI where collection assets can be accessed
    */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
      _baseTokenURI = _baseURI;
    }

    /**
    * @notice Sets the value of max mints that a wallet can do
    */
    function setMaxMintsPerWallet(uint256 _val) external onlyOwner {
      MAX_MINTS_PER_WALLET = _val;
    }

    /**
    * @notice Sets the value of how many mints per transaction can be done
    */
    function setMaxMintsPerTxn(uint256 _val) external onlyOwner {
      MAX_MINTS_PER_TXN = _val;
    }

    /**
    * @notice Sets the mint state for the contract.
    */
    function setMintOpen(bool _open) external onlyOwner {
      mintOpen = _open;
    }

    /**
    @notice Sets the contract-wide royalty info
    */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
      _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    /**
    * @notice Boilerplate to support ERC721A and ERC2981
    */
    function supportsInterface(bytes4 interfaceId) public view override (ERC721A, ERC2981) returns (bool) {
      return super.supportsInterface(interfaceId);
    }

}