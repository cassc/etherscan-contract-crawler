// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
                                             ██     ███████       ██     ██ ███████  ███████  ████████
                                            ████   ░██░░░░██     ████   ░██░██░░░░██░██░░░░██░██░░░░░
                                           ██░░██  ░██   ░██    ██░░██  ░██░██   ░██░██   ░██░██
                                          ██  ░░██ ░███████    ██  ░░██ ░██░███████ ░███████ ░███████
                                         ██████████░██░░░██   ██████████░██░██░░░░  ░██░░░░  ░██░░░░
                                        ░██░░░░░░██░██  ░░██ ░██░░░░░░██░██░██      ░██      ░██
                                        ░██     ░██░██   ░░██░██     ░██░██░██      ░██      ░████████
                                        ░░      ░░ ░░     ░░ ░░      ░░ ░░ ░░       ░░       ░░░░░░░░
                        `  `  `                                       ..   `                  `
                                 `  `  `  `  `                       .r7CO+.                       `
              `      `                           `                   .O_  ?ri       `  `..JzrrOz-.
                 `                                   `  `  `  `  `   .ZML  (O>  `   ` .zC<`   ` ?1O, `
                        `    `              `                     `  JC     (O   `  .OC`   ..,    jZ
             `      `                  `` .(.. `               `   .JZ!     (Z    .zC!     (^-.(zZC`
                `          `    `   `   .zC<?7O&.  `             .zC!    ` .O: ` (Z!     ..zC7!`
                       `                .r_7d\ _1O+.   `  `    .JC`      .JZ!  .zv`    .JZ!`
             `     `                     zo.      ?Cw&-.   `   (Z`    ` .Z>   JZ!   `.JZ!          `  ` ` ` ......` `
                                       `  1w&.       _?1Oz+..` jI     .jv`  .O>  ...-zr++zz&++(((-......(JzOC7???Cw+
                `     `   `   `  `          ~?IO&-.       _?zO+JI     jZ .JZC`   ?<?!~??Oo-.  ``~~??????!` T7>    .r:
            `                       `          `_?7Oo-. ..    ?1O_   `(CC7!             `_?OO-.      .......  ...JO>
                   `                        `....(((JwwzC!                    `  ((-..       ?1Oo.   ?1OrOI7777<?`
               `      `              `` ..JzOC7?!``_zZ7`       .O_         `..   ``~?Oo.        _?O+. .z+?CO&-..
            `             `  ` ``  ..Jzv7?` ..-.  .O>    .. ` .O>` .` `.  ` z>       .+zOrz+-. `   jO.  jO.  ??7OOOz(-..`
                  `         `.Jzrwv7!`    .JZ!` .JC`   .zC`  -Z! (r>  (Z!   r: jI.    ?CO+.-?O&e    OI   zo.      ` _??zO+. `
                     `     ` rI_`d}   ` .(O>  (&O>  .JrrO  .zv`.zrc  .r!    O>  ?O-.     jO- (w?Y  .O>    1O-.  ...      ?Oo.  `
            `  `        `     ?COOtrvrrrO7`   .O! (rC!    .w>  jrr:  (Z.    (O.   ?Oo.    jrw&zw-.JZ>       ?7OzrrrrO-..xJ ?w-
                               ..xrrrOC!  .(zrZ! JZ!      jC   rvr~  .rl`    1O.    ?Oo   .r<?Oo~!` .Oo.        ?7Orc?zO-...zI
                  `       ` .JO71+Z7!   .zv!.rl..r!      .O!   rvr:  .rro.`   ?O&.   .uo.  zl  jO.    ?zO+..  `   ._Co. ~?<<!`
            `        ` ` .(O7! JZ!    .zC`  .r;?jO_  (rC jv    zIzo   jOjO.     ?Oo.   Ol  (r_  ?Oo.     _?1Oo.   ?o.Jw-
                `     ` (Z>   (Z9.` .Ov` ` .JZOtv! .O>`  w{    (O?r- `.zo(1o.     ?1O..(r-  jo.   _?Cr&-..   _1O-..zCuI.
                     `.qP`   .wo?<JO7``..JZ>`    .zC`    Ol    (Z (w-   1w-_1O-.   .0?r-(w-?xuw+.      ??7OO&-. ?7<!  jo. `
            `         zv"!.(Z7`?<zO: .xAa_     .jC!      (O&J66O>  ?w-   .?Oo-?CO&(z((zC`?r< .r<7Oz-.     `.(?Cw+      ?Oi.
                `     uo(xZ>`   .r{ (O!.9` ..+ZC!          ??<!`    (Oo.   ` (yO&.`~!~`   .1OOC`   ??OO&-..?^` .r:..     ?r+.`
                        `    `.JZ!   ?OzzOvC!`       `                ?Oo.. `JD Ol                     _??7COOC7! jO.` `   ?O&.`  `
            `     `  `      .uC!     `                 `                _?7OOzzOC!                            ..   ?O. zw&.  ?Oo.
               `        ` .zC!    `  ..          ` `..J,              ` ..(...`              ``.J,           `jI.   _zrr:?zo.  ?r<
                      ` .zC`     .JzrZ!            .MMM%`         `  ..HM9UVWMN,`  `    `     .MMMb            zo. `  -?OO(zw(,.-O>
            `        ` (Z:  `  (ZCzZ!  `..   `     `.T"         ` `.JH#6llllllWMm,   `     `   _7`              ?O..      ?1wro/ (t_
                 `    .v:.,` .zv-zC`   .O>      `           `  ``[email protected],  `                   ``    ?O&.  ` .  uOOOxZ`
                     `([email protected]_` .JC(r>  `.Jv!                   ` `[email protected]                    j<     _1Oo-,7D (Z`
            `          jo..Jwwzv!  .JZ!    `  `               .HM0OVHHmHkmQQQQQQWmHSlldMN,                   r{   .-. ` ??COOOO-.
               `` ``  ` _<zrrC!  .JZ!    ` `..O:             [email protected]@#`  `           ` ` zl    jo.        _?zO-.` `
              ` .J++++zrv7<!   .JZ!    ` .JOC>`    `        .HDZWHmmmmmmgmmHHqWHHmmmgmmHHD                z> (O. `  ?w-` `.z+.    ?7O+.  `
            `  zC`jc    `     (Z!     .zC<`           `  `  ,[email protected]`               `(I  ul     (Oi   1rrO-. `  ?z&.
               ?OzH&.....(+zZwZ~&.` .Jr: (,                 `?MHeOllllllllllllllllzuQHB^`                 (I  .O> (O&. 1o.  1w-?Ood[.. ?O-  `
                  _!????!jrC`jI  "-JZ<v!(Z``   `  ` ` `     `  ?THMHmgeszzzzzuuQQkMB"`      `  `          z>   (ri  jO- ?O-  (Oi._?Or+..zI
                        JZ!   1wzOv!`(Z(O!    ..   .+.  `          -?"TYWHMHHYY"=`                 `  `   zl    (Ol. jO. (Oi   ?r+.  _?!`
            `         .jC` ``.JZ!   (Z1r>  `.(zI    (O>                                         `  `.-  ``(O-`    1o..r;  .Oo.   ?zo..
                     .zA, `.JZ!  .JO7(O:  `.JZzI    `jI                                 `  `     ..  jI..&.?ri     jOJrl  `(rv&.  `_?O&.
               `  `  J8``.JZ!..JOC!.zC`  `.Ov`z>     (O                    ` `     `            `(Oo  jOJI   jw..,.<(rrO    zI?O+.    ?Oo.
            `      ` vi.zZ1+rv?` .jv!  `.JZ! .r:   ` (Z  `.(.` `  `   ` `  .  w{ `  ` `     `     .O>  1rw_   _Cw-.  OZr>-d+r:  ?Odb?^  jw.`
                     _??_JZWe  `.O!Ti..JZ!   jC      jI  .OC   `.-       `,O` r{    .     ..       (O.  ?rw-    jrrrtrI_O&JZ:     ?7OO&+zC` `
                         1O&((+zrw-.JOC!  ` (Z`     .w> .r>     .r~ ..   `(I  jI   (w-    .zo       zl   _zro.   (zo.(I   `
            `  `  `          .JO>???!   .+zzZ!    ` (Z`.r>      JC (Z`   (jI  .r< ` jI.    .Ol`  ` `.O<    ?OrO-. `-?OO-
                            .O>      .JZ>-xC`      .Z!.w>      .Z! zI    zrr_  (O-  .O>     (O. zo.  (Oo.    _?CvO-.  (Zr&.
                     `   ` JZ!.)`  .xC~Jtvqa.`  `.Jrzzr>    ``.r:  O>   .w>Ol   (Oi  jO   ` .r:  jO.  (rro.`   ` _1rrOz-.zv>``
            `              Ol  ?>(zv`.Jw<..7_..(zrrrrZ!      .r:  .r:   (Z (r-   .UI..r_  ` .r:   zl   (w+vO-..., -O~r>~?!`
                `       `  _COzZv!` .O>`?1rrrv?!(zrCl    ``.JO!  .z>  `.rr> (O+    jO(r{ uT!.O~   (w_` .OO>_?OrOzwv!.Z`
                   `    `    `` ...JO?S.(Zzr>  .r>  ?" ` .JO77OO&JI` ` jC(O   1O+.. OOr: `  (I-.JxzrZt  jI_~~jO.   .rOz+(... `  `  `
            `        `  `  ..J=z<<<O> .Ov(r>``.zO-. ...Jrv>(+wOCjr?"^ .r!.r.   .rvwrZzZ`  `.OrwOzZ!OZ"  (O_~~_?OzzOC<~~~<<?1zz-..`
                `      ` (ll<~~~_((wOwOI~jZ` 7TwI77zz7<+(zOrv!  jI  `.r: .r~ ` .rM#XIr{    (wqNkZ! jI   (Z~~~~~~~~~+==z++--_~_(1lv
                 ` ..(+gNMNmyllzz<<<<~_((zI` .zC~_((+zuyOZ>` .Jwww..(Z!  (r;..,.rUZ!(Z`   .wdMSC`  (O- .r>~~~.~~~((--_~<??+1llzdNNagJ..  `
            `  `.&MMMMMMMMNylz((((++lzz<<?r&+rOzzuggMMSZ!  `.wqMMNsrv   (wmO(i(wrv` (w-..zQMMXG, .JwmwwQmgyz+--_~~<?1zlz+++-(+ludMMMMMMNm,
                (HMMMMMMMMMMNNNNNIv<~~_((+zwQgNMMMMM#0W<r  JwdMMMMSI    wdMNmmwm~    _?jrqMMSC (OwgMMMMMMMMNNNgszz+--_~~+zWNNNMMMMMMMMMM#^
                   [email protected]   .JQMMMMMNwl.  .vdMMMEZ!T`    .wdMMMkwwQNMMMMMMMMMMMMMMNMMNmgas&gdMMMMMMMMMH9"!
            `              ~?7"""HMMMMMMMMMMNMMNMMNMNyOzwQMMMMMMMNrC? `(wMMMMKO.   .(wQMMMMMMMMMMMMMMMNMMNMMNMMMMMMMMMMMHB"""?!`
                                      `   ``~??77"""""""""BWHHMMMMSO- .zdMMMMMkOzOOOdMMMMMMMHHBYB""""""""77?!!~`    `
                                                                   ?OOC!
**/

// Author: blacktanktop
// Twitter: https://twitter.com/black_tank_top

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ARAIPPE is ERC721, Ownable{
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter internal _totalSupply;

    string private baseURI = "";
    string constant private URI_SUFFIX = ".json";
    uint256 constant public MAX_SUPPLY = 44;
    bool public isSBT = false;

    constructor() ERC721("ARAIPPE", "ARAIPPE") {
        setIsSBT(true);
        setBaseURI("ar://L8w-1-lZcSJzmy-4K-ecyohoBt5su-RsAemYHjhwkGY/");
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // view
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(ERC721.tokenURI(tokenId), URI_SUFFIX));
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.current();
    }

    // onlyOwner
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // airdropMint function
    function airdropMint(address[] calldata _airdropAddresses) public onlyOwner {
        uint256 _mintAmount = _airdropAddresses.length;
        require(totalSupply() + _mintAmount < MAX_SUPPLY + 1, "max NFT limit exceeded");
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_airdropAddresses[i], totalSupply() + 1);
            _totalSupply.increment();
        }
    }

    // SBT
    function setIsSBT(bool _state) public onlyOwner {
        isSBT = _state;
    }

    function getIsSBT() public view returns (bool) {
        return isSBT;
    }

    function _beforeTokenTransfer(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
        require(isSBT == false || from == address(0) || to == address(0x000000000000000000000000000000000000dEaD), "transfer is prohibited");
        super._beforeTokenTransfer(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(isSBT == false , "setApprovalForAll is prohibited");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        require(isSBT == false , "approve is prohibited");
        super.approve(to, tokenId);
    }

    // supportsInterface
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721) returns (bool) {
        return
            super.supportsInterface(interfaceId);
    }
}