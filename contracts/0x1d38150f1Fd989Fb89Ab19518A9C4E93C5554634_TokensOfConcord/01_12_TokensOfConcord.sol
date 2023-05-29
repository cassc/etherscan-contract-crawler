//
//      ...    .     ...           ..                    ....        .          ....              .....     .        ..      .
//   .~`"888x.!**h.-``888h.     :**888H: `: .xH""     .x88" `^x~  xH(`      .xH888888Hx.        .d88888Neu. 'L    x88f` `..x88. .>
//  dX   `8888   :X   48888>   X   `8888k XX888      X888   x8 ` 8888h    .H8888888888888:      F""""*8888888F  :8888   xf`*8888%
// '888x  8888  X88.  '8888>  '8hx  48888 ?8888     88888  888.  %8888    888*"""?""*88888X    *      `"*88*"  :8888f .888  `"`
// '88888 8888X:8888:   )?""` '8888 '8888 `8888    <8888X X8888   X8?    'f     d8x.   ^%88k    -....    ue=:. 88888' X8888. >"8x
//  `8888>8888 '88888>.88h.    %888>'8888  8888    X8888> 488888>"8888x  '>    <88888X   '?8           :88N  ` 88888  ?88888< 888>
//    `8" 888f  `8888>X88888.    "8 '888"  8888    X8888>  888888 '8888L  `:..:`888888>    8>          9888L   88888   "88888 "8%
//   -~` '8%"     88" `88888X   .-` X*"    8888    ?8888X   ?8888>'8888X         `"*88     X    uzu.   `8888L  88888 '  `8888>
//   .H888n.      XHn.  `*88!     .xhx.    8888     8888X h  8888 '8888~    .xHHhx.."      !  ,""888i   ?8888  `8888> %  X88!
//  :88888888x..x88888X.  `!    .H88888h.~`8888.>    ?888  -:8*"  <888"    X88888888hx. ..!   4  9888L   %888>  `888X  `~""`   :
//  f  ^%888888% `*88888nx"    .~  `%88!` '888*~      `*88.      :88%     !   "*888888888"    '  '8888   '88%     "88k.      .~
//       `"**"`    `"**""            `"     ""           ^"~====""`              ^"***"`           "*8Nu.z*"        `""*==~~`
//
//
//     .....                            ..                                  .x+=:.                                     ...                                                                          ..
//  .H8888888h.  ~-.              < [email protected]"`                                 z`    ^%                    oec :        xH88"`~ .x8X                                                                  dF
//  888888888888x  `>        u.    [email protected]                      u.    u.        .   <k           u.     /88888      :8888   .f"8888Hf        u.      u.    u.                    u.      .u    .   '88bu.
// X~     `?888888hx~  ...ue888b   '888E   u         .u     [email protected] [email protected]    [email protected]"     ...ue888b    8"*88%     :8888>  X8L  ^""`   ...ue888b   [email protected] [email protected]       .    ...ue888b   .d88B :@8c  '*88888bu
// '      x8.^"*88*"   888R Y888r   888E [email protected]    ud8888.  ^"8888""8888"  [email protected]^%8888"      888R Y888r   8b.        X8888  X888h        888R Y888r ^"8888""8888"  .udR88N   888R Y888r ="8888f8888r   ^"*8888N
//  `-:- X8888x        888R I888>   888E`"88*"  :888'8888.   8888  888R  x88:  `)8b.     888R I888>  u888888>    88888  !88888.      888R I888>   8888  888R  <888'888k  888R I888>   4888>'88"   beWE "888L
//       488888>       888R I888>   888E .dN.   d888 '88%"   8888  888R  8888N=*8888     888R I888>   8888R      88888   %88888      888R I888>   8888  888R  9888 'Y"   888R I888>   4888> '     888E  888E
//     .. `"88*        888R I888>   888E~8888   8888.+"      8888  888R   %8"    R88     888R I888>   8888P      88888 '> `8888>     888R I888>   8888  888R  9888       888R I888>   4888>       888E  888E
//   x88888nX"      . u8888cJ888    888E '888&  8888L        8888  888R    /8Wou 9%     u8888cJ888    *888>      `8888L %  ?888   ! u8888cJ888    8888  888R  9888      u8888cJ888   .d888L .+    888E  888F
//  !"*8888888n..  :   "*888*P"     888E  9888. '8888c. .+  "*88*" 8888" .888888P`       "*888*P"     4888        `8888  `-*""   /   "*888*P"    "*88*" 8888" ?8888u../  "*888*P"    ^"8888*"    .888N..888
// '    "*88888888*      'Y"      '"888*" 4888"  "88888%      ""   'Y"   `   ^"F           'Y"        '888          "888.      :"      'Y"         ""   'Y"    "8888P'     'Y"          "Y"       `"888*""
//         ^"***"`                   ""    ""      "YP'                                                88R            `""***~"`                                  "P'                                 ""
//                                                                                                     88>
//                                                                                                     48
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./token/ERC1155.sol";
import "./access/Ordainable.sol";

contract TokensOfConcord is ERC1155, IERC2981, Ordainable {

    /**
     *  @dev 𝔗𝔥𝔢𝔯𝔢 𝔦𝔰 𝔬𝔫𝔩𝔶 𝔬𝔫𝔢 𝔠𝔬𝔫𝔰𝔱𝔞𝔫𝔱...
     */
    bool public constant __WeAreAllGoingToDie__ = true;

    string public name = "WAGDIE: Tokens Of Concord";
    string public symbol = "CONCORD";

    string private baseURI;

    uint256 internal toll = 570;

    mapping(uint256 => string) private tokenURIs;

    constructor(
        string memory _baseURI
    ) ERC1155(){
        baseURI = _baseURI;
    }

    /**
     *  @dev 𝔅𝔢𝔰𝔱𝔬𝔴 𝔱𝔬𝔨𝔢𝔫𝔰 𝔲𝔭𝔬𝔫 𝔠𝔯𝔢𝔞𝔱𝔬𝔯.
     */
    function bestowTokensUponCreator(
        uint256 _token,
        uint256 _quantity
    ) external onlyCreator {
        _craftTokens(msg.sender,_token,_quantity,'');
    }

    /**
     *  @dev 𝔅𝔢𝔰𝔱𝔬𝔴 𝔪𝔞𝔫𝔶 𝔱𝔬𝔨𝔢𝔫𝔰 𝔲𝔭𝔬𝔫 𝔠𝔯𝔢𝔞𝔱𝔬𝔯.
     */
    function bestowTokensUponCreatorMany(
        uint256[] memory _tokens,
        uint256[] memory _amounts
    ) external onlyCreator {
        _craftTokensMany(msg.sender,_tokens,_amounts,'');
    }

    /**
     *  @dev 𝔅𝔢𝔰𝔱𝔬𝔴 𝔱𝔬𝔨𝔢𝔫𝔰 𝔲𝔭𝔬𝔫 𝔱𝔥𝔬𝔰𝔢 𝔡𝔢𝔢𝔪𝔢𝔡 𝔴𝔬𝔯𝔱𝔥𝔶.
     */
    function bestowTokens(
        address[] memory _to,
        uint256 _token,
        uint256 _quantity
    ) external onlyOrdainedOrCreator {
        for (uint256 i = 0; i < _to.length; i++) {
            _craftTokens(_to[i],_token,_quantity,'');
        }
    }

    /**
     *  @dev 𝔅𝔢𝔰𝔱𝔬𝔴 𝔪𝔞𝔫𝔶 𝔱𝔬𝔨𝔢𝔫𝔰 𝔲𝔭𝔬𝔫 𝔱𝔥𝔬𝔰𝔢 𝔡𝔢𝔢𝔪𝔢𝔡 𝔴𝔬𝔯𝔱𝔥𝔶.
     */
    function bestowTokensMany(
        address[] memory _to,
        uint256[] memory _tokens,
        uint256[] memory _amounts
    ) external onlyOrdainedOrCreator {
        for (uint256 i = 0; i < _to.length; i++) {
            _craftTokensMany(_to[i],_tokens,_amounts,'');
        }
    }

    /**
     *  @dev ℜ𝔢𝔱𝔲𝔯𝔫 𝔱𝔬𝔨𝔢𝔫𝔰 𝔣𝔯𝔬𝔪 𝔴𝔥𝔢𝔫𝔠𝔢 𝔱𝔥𝔢𝔶 𝔠𝔞𝔪𝔢.
     */
    function burn(
        address _from,
        uint256 _token,
        uint256 _quantity
    ) external onlyOrdained {
        _burn(_from,_token,_quantity);
    }

    /**
     *  @dev ℜ𝔢𝔱𝔲𝔯𝔫 𝔪𝔞𝔫𝔶 𝔱𝔬𝔨𝔢𝔫𝔰 𝔣𝔯𝔬𝔪 𝔴𝔥𝔢𝔫𝔠𝔢 𝔱𝔥𝔢𝔶 𝔠𝔞𝔪𝔢.
     */
    function burnMany(
        address _from,
        uint256[] memory _tokens,
        uint256[] memory _amounts
    ) external onlyOrdained {
        _burnMany(_from,_tokens,_amounts);
    }

    /**
     *  @dev 𝔊𝔢𝔱 𝔡𝔢𝔱𝔞𝔦𝔩𝔰 𝔣𝔬𝔯 𝔡𝔢𝔰𝔦𝔯𝔢𝔡 𝔱𝔬𝔨𝔢𝔫.
     */
    function uri(
        uint256 token
    ) public view virtual override returns (string memory) {
        string memory tokenURI = tokenURIs[token];
        return bytes(tokenURI).length > 0 ? tokenURI : baseURI;
    }

    /**
     *  @dev 𝔖𝔢𝔱 𝔡𝔢𝔱𝔞𝔦𝔩𝔰 𝔣𝔬𝔯 𝔡𝔢𝔰𝔦𝔯𝔢𝔡 𝔱𝔬𝔨𝔢𝔫.
     */
    function setURI(
        uint256 _token,
        string memory _tokenURI
    ) external onlyCreator {
        tokenURIs[_token] = _tokenURI;
        emit URI(uri(_token), _token);
    }

    /**
     *  @dev 𝔖𝔢𝔱 𝔡𝔢𝔱𝔞𝔦𝔩𝔰 𝔣𝔬𝔯 𝔞𝔩𝔩 𝔱𝔬𝔨𝔢𝔫𝔰 𝔶𝔢𝔱 𝔱𝔬 𝔟𝔢 𝔨𝔫𝔬𝔴𝔫.
     */
    function setBaseURI(
        string memory _baseURI
    ) external onlyCreator {
        baseURI = _baseURI;
    }

    /**
     *  @dev 𝔖𝔢𝔱𝔰 𝔱𝔬𝔩𝔩 𝔣𝔬𝔯 𝔟𝔞𝔯𝔱𝔢𝔯𝔦𝔫𝔤 𝔬𝔣 𝔱𝔬𝔨𝔢𝔫𝔰.
     */
    function setToll(
        uint256 _toll
    ) external onlyCreator {
        if (_toll > 2500) revert NotWorthy();
        toll = _toll;
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) public view virtual override returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * toll) / 10000;
        return (owner(), royaltyAmount);
    }

    /**
     * @dev 𝔖𝔢𝔢 {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, IERC165) returns (bool) {
        return
        interfaceId == type(IERC1155).interfaceId ||
        interfaceId == type(IERC1155MetadataURI).interfaceId ||
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

}