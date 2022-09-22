// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/******************************************************************************

  ███╗   ██╗███████╗██████╗ ██╗   ██╗ ██████╗ ██╗   ██╗███████╗
  ████╗  ██║██╔════╝██╔══██╗██║   ██║██╔═══██╗██║   ██║██╔════╝
  ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║   ██║██║   ██║███████╗
  ██║╚██╗██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║   ██║██║   ██║╚════██║
  ██║ ╚████║███████╗██║  ██║ ╚████╔╝ ╚██████╔╝╚██████╔╝███████║
  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ╚═══╝   ╚═════╝  ╚═════╝ ╚══════╝
  work with us: nervous.net // [email protected] // [email protected]
  ██╗  ██╗
  ╚██╗██╔╝
   ╚███╔╝
   ██╔██╗
  ██╔╝ ██╗
  ╚═╝  ╚═╝


                           .;odo;.       .''.         .:dxo,                    .lkko,      .;cc,.
                          ;kXWMWNk;    .oOKX0x,      ,kNWMWXo.      ,lddo:.    ,OWMMWXd.   :ONWWXk;
                         cXMMMMMMMX:  ,0WMMMMMK;    ,KMMMMMMWo.   .dNMMMMW0:  .kMMMMMMWd. :XMMMMMMX:
                        .kMMMMMMMMMO.'OMMMMMMMMO.   oWMMMMMMMk;.  lNMMMMMMMX; ,KMMMMMMM0' dWMMMMMMMx.
                        ,KMMMMMMMMMXcdWMMMMMMMMN:  .dMMMMMMMMx'. .xMMMMMMMMMk.'0MMMMMMM0' oWMMMMMMMx.
                        :XMMMMMMMMMNOKMMMMMMMMMWo   oWMMMMMMX:   .dMMMMMMMMMNc'kMMMMMMM0' cNMMMMMMWo
                        cNMMMMMMMMMMWWMMMMMMMMMMx.  :XMMMMMM0,    oWMMMMMMMMM0lOMMMMMMMk. cNMMMMMMX;
                        lWMMMMMMMMMMMMMMMMMMMMMMO.  '0MMMMMM0'    cNMMMMMMMMMWXNMMMMMMWd  cNMMMMMM0'
                        oWMMMMMMMMMMMMMMMMMMMMMMX;  .kMMMMMMK,    :NMMMMMMMMMMMMMMMMMMN:  cNMMMMMMk.
                       .xMMMMMMWWMMMMMMMWNWMMMMMWx.  oWMMMMMX;    cNMMMMMMMMMMMMMMMMMMK,  :NMMMMMMO.
                       '0MMMMMMKKMMMMMMMKONMMMMMMX:  cNMMMMMNc    oWMMMMMMXXMMMMMMMMMMO.  cNMMMMMMK,
                       :NMMMMMNloNMMMMMMkl0MMMMMMMx. cNMMMMMWl.  .xMMMMMMMkoXMMMMMMMMMO.  lWMMMMMMNc
                       oWMMMMMO.'OMMMMMNc.xMMMMMMMO. lWMMMMMWo.  .OMMMMMMWd.oNMMMMMMMMk.  oWMMMMMMWl
                       lWMMMMX:  ;OWMWXl. :XMMMMMMO. lWMMMMMNc   .kMMMMMMX: .dNMMMMMMMk.  lWMMMMMMX:
                       ,OWMWKc    .,:;.   .lXMMMMXc  'OWMMMWx.    :KWMMWKc   .lXWMMMMNl   .xNMMMMXo.
                        .;c;.               'lxxl'    .cdxo;.      .:cc;.      .:dkkx:.    .,looc'


     .:ll:.      .,;'            ..,;;,.      ...                   ..',;,'.   ....            ..''..
    cXWMMWKc   .lKWWNk,    .,:lox0XWWWWKl. .cOKXKkc.     ..,;;::codk0XNWWWNKocxKXX0d'   .:oodxOKNNNX0o.     .:oxkO0Okd:.
   '0MMMMMMX;  oNMMMMM0'  :0WMMMMMMMMMMM0' cNMMMMMWo.  ;xKNWWWMMMMMMMMMMMMMMMWMMMMMMO' ;KWMMMMMMMMMMMNl  .:kXWMMMMMMMMWXo.
   ,KMMMMMMWx.'0MMMMMMNc .OMMMMMMMMMMMMXo..dMMMMMMMK, cXMMMMMMMMMMMMMMMMMMMWWMMMMMMMN:.dWMMMMMMMMMMMWO, ,OWMMMMMMMMMMMMMNc
   ,KMMMMMMMO':XMMMMMMNl '0MMMMMMWX0kdl'  .xMMMMMMMK,.dWMMMMMMMMMMMMMMMWN0odXMMMMMMMX; oWMMMMMN0kxdl;. '0MMMMMMWWMMMMMMMNc
   ,KMMMMMMMXcoWMMMMMMNl .kMMMMMWx'...     dWMMMMMM0, .oOKKKKKKXMMMMM0l:'. '0MMMMMMMk. :XMMMMM0,       oWMMMMM0:,cd0NWNKl.
   ;XMMMMMMMWkOWMMMMMMWo  lWMMMMW0xkO00x,  oWMMMMMM0'    .....'dWMMMWd.    .xMMMMMMWo  '0MMMMMXkxkxo, .dMMMMMMKl,'',;;,.
   cNMMMMMMMMNNMMMMMMMMk. cNMMMMMMMMMMMXc  lWMMMMMMO.        .'dMMMMMk.     cNMMMMMWo  .OMMMMMMMMMMMO. :KMMMMMMWWNNXKko'
  .dWMMMMMMMMMMMMMMMMMMK, ;XMMMMMNX0kdl,   lWMMMMMMx.        .:kMMMMMK,     ,KMMMMMMx. .kMMMMMWXKOko'   ,kXWMMMMMMMMMMMXl.
  '0MMMMMMMMMMMMMWMMMMMNl ;XMMMMXc..       oWMMMMMNl. ..     'l0MMMMMNc     .OMMMMMMk. .kMMMMWx'.         .:loooooxXMMMMX:
  lNMMMMMNWMMMMMN0XMMMMMx.;XMMMMXl:oxO0Ox;.xMMMMMMW0k0K0Ol.  ,xKMMMMMWd     .kMMMMMM0' .kMMMMWd.';:cc,. .;odoc,. .:KMMMMNc
  OMMMMMWkOMMMMMOcOMMMMM0';XMMMMMWMMMMMMMNkKMMMMMMMMMMMMMWd. ;kKMMMMMMd.    .OMMMMMMK, .OMMMMMNXNWMMMW0ldNMMMMWK00NMMMMWk.
  NMMMMMX:;KMMMXc.dWMMMMX:;XMMMMMMMMMMMMMX0XMMMMMMMMMMMMMWd. ,dKMMMMMWl     .OMMMMMMO. .xMMMMMMMMMMMMMM0kXMMMMMMMMMMMMNx.
  NMMMMWx. 'col,  :XMMMMX:.xWMMMMMMWWNXOd,'kWMMMMMWNNXXX0o.  .'dWMMMWO'     .oNMMMMXc   ,0MMMMMMMMWWNKx,.;d0NWMMMMWNKx;
  c0XNKo.          c0NN0l. .lO0Odl:;,..    .:odol:,'.....      .lkOkl.        ,lddc'     .lxkdlc::;,'.     .':clcc;'.
   .,;.             .;;.     ...                                  .


                                                                           ..  ...
                                                          .....'''''';clldkxdddxddoc:c,
                                                  .';cldkO0KXXXNNNNNX0xool;...'. .,;;ckxol;.
                                             .;ldOKXNX0OxolccdkKWOc;,.                .''cOkc'
                                         .:dOXNX0xl:'..    'dOKKx.     ':cccllll:;:c,     .:x0l
                                      'lkXWXko;..         ;KWOl,  ,cllkOd:;,. ..,,,:xxoll;. .OK,
                                   .ckXNKd:.              :KWNKOxOXKxol'    ..'''....',;dKOloKO'
                                 ,dKNKd;.    .             .:okOKOl.   .,ldxxxxddddxdl;..;dOXWKc.
                               ;kNNOc.     ''.                  .    ,okko;..     ..,cdxl.  ,kWWk;
                             ,xNNk;.     .l:           ..          ,xko'    ..'''''....'okc. .cKWXd.
                           .oXNk;        :k:.,::'    ';..        .oOl.    .,;;;:ldxxxo:..;Ox.  .dNW0;
                          ,OWKc.         .cddl;ck:  ;o.         .xk,    .,;;;lkKWMMWWWXkc.;Ox.   :KWXl.
                         cXWk'                 .OO,;Od.        .kO,    .,;;ckNMMMXd::oKWXo'lKl    'OWNo.
                       .lNNo.                  .cO00x'       .'d0;    .,;;l0WMMMX:    ,KMXl,kO.    .kWNo.
                       lNNo. ..        ...       ...   ..    ;k0d.   .,;;:OWMMMMx.    .kMWk,l0:.  . .kWXc
                      :XNo..,.  .     .'.             ..     oNK;    ';;;oXMMMMMx.    '0MM0;:Oc...'. ,0M0'
                     '0Wk..;..,::l;   ;;              ;.    .dW0,   .,;;;dNMMMMMNd.  'xNMM0;:Oc ,'':. cXWd
                     oWK;.:, :l. lx.  cl.             :,     oW0,   .,;;;oXMMMMMMWX0Oxc:OWk,cO: ;;.l: .kM0'
                    '0Wx.,l..d; .dk. ,xl     .,.      :c     cK0:   .,;;;lKMMMMMMMMMNc  oKo'oO, ::.oo  cNNc
                    :XNc :d;lk' ;0l.cOc      .:'     ;d;     .lko    .;;;;dNMMMMMMMMWk:l0x;,kx..dc.kd  '0Wo
                    cNK; .cdo, .kO' :0c       .;:'  :k:       .lk,   .';;;:xXMMMMMMMMMWNx:.cO: .OOk0;  .kMd.
                  .;OWK,       cXo  .d0,        :x, ;Oc        .xx.   .',;;;lxKNWMMMMWKd;.,kd.  ,lo,   .kMx.
                .o0WMMX;      .dNc   ;Kx.       :Kl .Ox.        'xx'    .';;;;:ldxkkxo:,..dx.          .OM0:.
              .lKW0oxNWl       oNd.  :Xx.       ,K0lxKc  .;:'    .oOc.    ..',,,,,,,'...'xx.  ,c'      ,KMWNKd;
             .xWXo. 'OMk.      'kXkldKO, .....   ,oxd;  '0WWO'     ;xx:.       ....   .lkl.  .OWo      lNXl;o0Xk,
            .dWXc    lNNo,:cloookNMNOl;cxkxxddoc.       .ckk:.       ,oxo:'.      .':odl'     ;c.     .kWk.  .oXXl.
            ;XNl     :XMWWNXKK000KXN0k00l'.   .;c'   ,c:.   .,:;.      .;looollcllllc,.    ;:.  :c.   cNNc     :XXc
            lWK,  .;xXXOo:,........,cxKKc.       .  '0MK;   cXMWd.          .....      .. '0K; .OK;  .kMNx:.   .dWk.
           .dWK; .xNKo'      .;cc:,   .lOd.          ,c,    .;c:.   'c.              .,d:  ,,.  .'    ,ldOXKx,  dWO.
        .;d0XXNklOXo.        ,:,.,c:.   'xc                        .loccc;;,''',;;:ccdklc,                .l0KolKM0:.
       ;ONXd,.lKW0:                ..    'c.                      .;' .od;::cx0KOl;'.cx' ..                 .oXWXO0XO:
     .oNNx'    dK:                        .                       .    ld.  .oocdc..,xo.                     .oKc .c0No.
    .oNXc     .dd.                                                     .:oloo:. 'clll;.         ..            ,x;   ;KNl
    :XXc      .l:                                                         ..                    ,:.           'l.   .dWO.
   .xWx.       ;,                                  ..;'  .;,.                               .  ;k;    .'      ..     lWO'
   .ONl        ..     ..                             ,xcckdlc'...                         .';coOk.    .:.           .xWk.
   .kWo               :,                              ,dx:                                   .:c'    .c;            :XX:
    lNK;              ll                                                                            ,kc            :KNl.
    .dNKc.            ;k:          ..                       ';;,..              .                   cKc         .:kX0:
     .cKNOc'          'kXd'         ,:'..;cc:.    .:cll;.  c0l..             .''.    .             'ONk:,'',;cok00x:.
       .lOXXOdlc:::ldkKWN00ko:'.    .cOXNXOoldo. .dl''lK0dxX0,             'ckOl'.   .',;cl,    'cdOkookKNX0O0NXl.
          ':ok0KNWWXk0W0:..:oOKKOkkOO00O0Kx:''xx.:x,.:xXX0XWXxdl:,'...';ldkxlok0K0kdollox0NX: .lxl:,.. 'kMNo.;KO.
               .cKWOlO0;     cXOc:c::,'..:d0KKXK;;0KKKOl,.'cdO0KXXXKKK0Oxl;....';codxkxxdolOd..xl.......xWWXk00;
                 'dKWNl     ,00;............;l0X;.dKo'..........',;;;,'.................. .kd. od......,0NxkWO'
                   cXO.    .xNx::;....;lol;..'kK, 'kd....'......',;,...':cc,....',;'...,:cd0l  :Oo;,;ccl0Wd:OO.
                   cXo     cXNNKOO0kk0KOk0KOdkXk.  oKxxkOOOkxxkkOkkOOkO0KKXKOddkO0K0OkOKXXN0,  ;KNXXNWX00x, lKl
                   oXc    .O0lkXxodolodc''lOKNWd. .dXOl:,:dkkOOd,..';coxddlclooc;:odkOkd::0O.  oNNNKkK0;.   .oOx:...
                  .dX:    :Xx.,OKOl'..':lcc:;dNKl:dXO;,:::;..;cc:;,',cl:;cl,.....,lddl;...dKxcdKWMK,'0O'      .okddxo'
                 .lKO'    ;0Kc..,xXx'..;odl:'.:xOOkdoodc'.......:oooo:....;cc:::cc;,;ccc,.:xkOKXNXl.oKc .;.        'kO'
                'kKo.      .dKx:.'OXo:c:;'',::..'::::::l:.....';c:',c:.....'colo:......:ooocoKX0o, '0k.  ,:.        dK:
               'OXc         'dkKKxxXXx'......;ccl:'....':lc::cl:'....;::;,:c:'.,cc'..';clc:oKWx.   '0x.   ...  .,;;oKx.
               lNo.            ,0Xl;kXo.....':llc:'....'clclo;........,lool,.....:lloo:,...,OWo     l0:        ;0Oxd;.
               dX:             .xNl ,K0;.;cll:'..':;'':l:...cool:'...:lc:lddl;...,lodxl,...;0Nc     ;0l     .  :0c
               ;0d.        .;;:dKk' .dNK0KKK0Oxl,,ck0KKKkdodOXNKOkkk000000O0XX0xxO00000OkdxKXd.    ;Od..,. ,,  .dO'
               ,0d... ..  .dKxdo;.   .:xkko:;ckKXNX0d:,;ldxdONXo..;ldkXXl...'cdOO0N0:..':clc,    .lOc.'c'.cl.   lK:
              ,Ok',; .:.  .o0:.                .oNO.        cXXl     .OX;        ,0k.            ,0d.:d'.ox.   .k0,
             .kX:'o, 'o,   .lOk;                cNk.        lXXl     '0K;        '0k.            .dOxKd.,0o   'xXo
             :XO':k' .xl     .kK;               lNx.        lXXl     ,0K,        '0k.              .;dOdkXKdld00c.
             cN0,l0;  l0c    .dX:             .;kNo         lNWO:. .;dN0'        ;KXd'                .;:;;:lc;.
             'ONOOXo. .l0kolokOl.             oNWNOlccccllodOKXNNxckNMMNxllllooodkKXWKollc;.
              .oOXNXo.  cXNkl:.               :X0xxkkkkkxkO00KKKKKKKXNWWNKkxxxxxO0000000KXXKOl.
                 .'l0KOk0Xd.                  lXkoooooook0KOkddoooooodk0XNXkddO0Oxdooooooodk0XKo.
                    .,cc:'                   .kKdooooodO0kdooooooooooolodkXWKOkdoooooooooooood0Nk'
                                            .oKkooooooxkooooooooooooooooookXWOooooooooooooooood0Nx.
                                         .,;dKOooooooooooooooooooooooooooooONXxooooooooooooooooxXX:
                                        ;KXKNXxooooooooooooooooooooooooooooxXNOooooooooooooooooo0Nd.
                                        oWKxkKKkdooooooooooooooooooooooooooxXMNKxooooooooooooood0WN0c.
                                        'ONKkxk000OkdooooooooooooooooooodxkKNKXWXxoooooooooddxk0XK0NK,
                                         .l0XXOkxkOOOOOOOOOOOOOOOOOO0000000OxkKWN0OOOO000000000OxdONO'
                                           .,oOKXK0OkxxxkkkkOOOOkkkxxxxxxxkOKNNKOkkkkkxxxddddxxO0KKx'
                                               .;ldO0KXXKK000OOOOOOO00KXXXK0KXXKK000000KKKKKK00kd:.
                                                    ..,:cloddddxxdddolc:,.....',;::cccccc:;,'..

*/

import "./ERC721S.sol";
import "@nervous-net/contract-kit/src/ScopedWalletMintLimit.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// @title  NervousNFT Mini-Melties ERC-721
// @dev    An ERC-721 contract for creating mini-melties.
// @author Nervous - https://nervous.net + Mini-Melties - https://minimelties.com
contract NervousNFT is
    ERC721Sequential,
    ReentrancyGuard,
    PaymentSplitter,
    Ownable,
    ScopedWalletMintLimit
{
    using Strings for uint256;
    using ECDSA for bytes32;

    string public constant R =
        "We are Nervous. Are you? Let us help you with your next NFT Project -> [email protected]";

    string private constant PRESALE_PREFIX = "NERVOUS";
    string public baseURI;
    uint256 public mintPrice;

    string public vipPresaleName;
    string public generalPresaleName;
    string public crossmintPresaleName;
    bytes32 public crossmintMerkleRoot;

    address public vipPresaleSigner;
    address public generalPresaleSigner;
    address public crossmintAddr;

    uint64 public startPublicMintDate;
    uint64 public endMintDate;
    uint64 public presaleDate;
    bool public mintingEnabled;
    uint16 public immutable maxSupply;
    uint8 public maxPublicMint;

    constructor(
        string memory name,
        string memory symbol,
        string memory initBaseURI,
        uint16 _maxSupply,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721Sequential(name, symbol) PaymentSplitter(payees, shares) {
        baseURI = initBaseURI;
        maxSupply = _maxSupply;
        mintPrice = 0.2 ether;
        startPublicMintDate = type(uint64).max;
        endMintDate = type(uint64).max;
        presaleDate = type(uint64).max;
        mintingEnabled = true;
        maxPublicMint = 10;
    }

    ///////
    /// Minting
    ///////

    /// @notice Main minting. Requires either valid pass or public sale
    function mint(uint256 numTokens, bytes calldata pass)
        external
        payable
        requireValidMint(numTokens, msg.sender)
        requireValidMintPass(numTokens, msg.sender, pass)
    {
        _mintTo(numTokens, msg.sender);
    }

    /// @notice Crossmint public minting.
    function crossmintTo(uint256 numTokens, address to) external payable {
        crossmintWithProof(numTokens, to, new bytes32[](0));
    }

    /// @notice Crossmint presale or public minting. Requires proof of presale
    function crossmintWithProof(
        uint256 numTokens,
        address to,
        bytes32[] memory merkleProof
    )
        public
        payable
        requireValidMint(numTokens, to)
        requireValidCrossmintMerkleProof(numTokens, to, merkleProof)
    {
        _mintTo(numTokens, to);
    }

    /// @notice internal method for minting a number of tokens to an address
    function _mintTo(uint256 numTokens, address to) internal nonReentrant {
        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(to);
        }
    }

    ///////
    /// Magic
    ///////

    /// @notice owner-only minting tokens to the owner wallet
    function magicMint(uint256 numTokens) external onlyOwner {
        require(
            totalMinted() + numTokens <= maxSupply,
            "Exceeds maximum token supply."
        );

        require(
            numTokens > 0 && numTokens <= 100,
            "Machine can dispense a minimum of 1, maximum of 100 tokens"
        );

        _mintTo(numTokens, msg.sender);
    }

    /// @notice owner-only minting tokens to receiver wallets
    function magicGift(address[] calldata receivers) external onlyOwner {
        uint256 numTokens = receivers.length;
        require(
            totalMinted() + numTokens <= maxSupply,
            "Exceeds maximum token supply."
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(receivers[i]);
        }
    }

    /// @notice owner-only minting tokens of varying counts to
    /// receiver wallets
    function magicBatchGift(
        address[] calldata receivers,
        uint256[] calldata mintCounts
    ) external onlyOwner {
        require(receivers.length == mintCounts.length, "Length mismatch");

        for (uint256 i = 0; i < receivers.length; i++) {
            address to = receivers[i];
            uint256 numTokens = mintCounts[i];
            require(
                totalMinted() + numTokens <= maxSupply,
                "Exceeds maximum token supply."
            );
            _mintTo(numTokens, to);
        }
    }

    /// Mint limits

    function crossmintPresaleLimit() external view returns (uint256) {
        return _scopedWalletMintLimits[crossmintPresaleName].limit;
    }

    function vipPresaleLimit() external view returns (uint256) {
        return _scopedWalletMintLimits[vipPresaleName].limit;
    }

    function generalPresaleLimit() external view returns (uint256) {
        return _scopedWalletMintLimits[generalPresaleName].limit;
    }

    ///////
    /// Utility
    ///////

    /* URL Utility */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    /* eth handlers */

    function withdraw(address payable account) external virtual {
        release(account);
    }

    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    /* Crossmint */

    function setCrossmintConfig(
        string memory name,
        address addr,
        uint256 limit,
        bytes32 merkleRoot
    ) external onlyOwner {
        crossmintPresaleName = name;
        crossmintAddr = addr;
        _setWalletMintLimit(name, limit);
        crossmintMerkleRoot = merkleRoot;
    }

    /* Sale & Minting Control */

    function setPublicSaleStart(uint256 timestamp) external onlyOwner {
        startPublicMintDate = uint64(timestamp);
    }

    function setEndMintDate(uint256 timestamp) external onlyOwner {
        endMintDate = uint64(timestamp);
    }

    function setPresaleDate(uint256 timestamp) external onlyOwner {
        presaleDate = uint64(timestamp);
    }

    function setVipPresaleConfig(
        string memory name,
        address signer,
        uint256 limit
    ) external onlyOwner {
        vipPresaleName = name;
        vipPresaleSigner = signer;
        _setWalletMintLimit(name, limit);
    }

    function setGeneralPresaleConfig(
        string memory name,
        address signer,
        uint256 limit
    ) external onlyOwner {
        generalPresaleName = name;
        generalPresaleSigner = signer;
        _setWalletMintLimit(name, limit);
    }

    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function setMaxPublicMint(uint256 _maxPublicMint) external onlyOwner {
        maxPublicMint = uint8(_maxPublicMint);
    }

    ///////
    /// Modifiers
    ///////

    modifier requireValidMint(uint256 numTokens, address to) {
        require(block.timestamp < endMintDate, "Minting has ended");
        require(mintingEnabled, "Minting isn't enabled");
        require(totalMinted() + numTokens <= maxSupply, "Sold Out");
        require(numTokens > 0, "Minimum of 1");
        require(numTokens <= maxPublicMint, "Maximum exceeded");
        require(
            msg.value >= numTokens * mintPrice,
            "Insufficient Payment: Amount of Ether sent is not correct."
        );
        _;
    }

    modifier requireValidMintPass(
        uint256 numTokens,
        address to,
        bytes memory pass
    ) {
        if (block.timestamp < startPublicMintDate) {
            if (pass.length == 0) {
                revert("Public sale has not started");
            }
            address signer = keccak256(abi.encodePacked(PRESALE_PREFIX, to))
                .toEthSignedMessageHash()
                .recover(pass);

            if (block.timestamp < presaleDate) {
                revert("Presale has not started");
            }

            if (signer == vipPresaleSigner) {
                _limitScopedWalletMints(vipPresaleName, to, numTokens);
            } else if (signer == generalPresaleSigner) {
                _limitScopedWalletMints(generalPresaleName, to, numTokens);
            } else {
                revert("Invalid presale pass");
            }
        }

        _;
    }

    modifier requireValidCrossmintMerkleProof(
        uint256 numTokens,
        address to,
        bytes32[] memory merkleProof
    ) {
        if (msg.sender != crossmintAddr) {
            revert("Crossmint required");
        }
        if (block.timestamp < startPublicMintDate) {
            if (merkleProof.length == 0) {
                revert("Public sale has not started");
            }
            if (block.timestamp < presaleDate) {
                revert("Crossmint presale has not started");
            }
            if (
                !MerkleProof.verify(
                    merkleProof,
                    crossmintMerkleRoot,
                    keccak256(abi.encodePacked(to))
                )
            ) {
                revert("Invalid access list proof");
            }
            _limitScopedWalletMints(crossmintPresaleName, to, numTokens);
        }
        _;
    }
}

// # OWNERSHIP LICENSE
//
// This Ownership License sets forth the terms of the agreement between you, on
// the one hand, and Buff Monster (the "Artist") and Maraschino Distribution LLC,
// a company ("Company"), on the other hand, with respect to your ownership and
// use of the Mini Melties, a collection of 2000 digital characters by the Artist
// (the "Artwork") to which this Ownership License applies.
//
// References to "you" herein mean the legal owner of the digital non-fungible
// token ("NFT") minted as the Artwork, as recorded on the applicable blockchain.
// References to "us" herein means the Company and the Artist, jointly and
// severally. References to the "Artwork" herein means the NFT, the creative and
// audiovisual design implemented, secured, and authenticated by the NFT, and the
// associated code and data that collectively constitute the above-referenced
// digital work of art.
//
// Your acquisition of the Artwork constitutes your acceptance of, and agreement
// to, the terms of this Ownership License.
//
// ## Ownership of the Artwork.
//
// References herein to your ownership of the Artwork mean your exclusive
// ownership of the authenticated NFT that constitutes the digital original of the
// Artwork, as such ownership is recorded on the applicable blockchain. Only a
// person or entity with the legal right to access and control the cryptocurrency
// address or account to which the Artwork is assigned on the blockchain will
// qualify as an owner of the Artwork hereunder.
//
// ## Your Ownership Rights.
//
// For so long as you remain the owner of the Artwork you will be entitled to
// exercise the following rights with respect to the Artwork (the "Ownership
// Rights"):
//
// - To store the Artwork in any account (i.e., cryptocurrency address) and
// to freely transfer the Artwork between accounts.
//
// - To privately view and display the Artwork for your personal purposes on
// any device.
//
// - To sell the Artwork to any third party, to exchange it in a swap with
// any third party, to list and offer it for sale or swap on any marketplace
// and/or through any platform or outlet that supports such sale or swap, to
// donate or gift the Artwork to any third party, and to transfer ownership of the
// Artwork to the applicable purchaser or other intended recipient.
//
// - To reproduce the visual imagery (and any audio, if applicable) produced
// by the Artwork (the "Imagery") in both digital media (e.g., online) and
// physical media (e.g., print) for your reasonable, private, noncommercial
// purposes, such as displaying the Imagery on your personal website and/or in
// your personal social media, or including the Imagery as an informational
// illustration in a book, magazine article or other publication dealing with your
// personal art collection.
//
// - To use the Imagery as your personal profile image or avatar, or as a
// similar personal graphic that serves to personally identify you in your
// personal social media and in comparable personal noncommercial contexts.
//
// - To include and exhibit theArtwork, as a digital work of fine art by the
// Artist, in any public or private art exhibition (or any comparable context),
// whether organized by you or by any third party such as a museum or gallery, by
// means of a Qualifying Display Device installed on site if the exhibition is
// presented in a physical space, or, if the exhibition is presented solely online
// or by other purely digital means, display and exhibition in a reasonably
// comparable manner. As used herein, a "Qualifying Display Device" means a video
// monitor, projector, or other physical display device sufficient to display the
// Artwork in a resolution and manner that does not distort, degrade, or otherwise
// materially alter the original Artwork.
//
// The foregoing rights are exclusive to you, subject to the rights retained by
// the Artist below.
//
// The Ownership Rights also include the limited, nonexclusive right to make use
// of the Artist's name and the Artist's IP Rights (as defined below) to the
// extent required to enable you to exercise the aforementioned usage rights.
//
// ## Faithful Display & Reproduction.
//
// The Artwork may not be materially altered or changed, and must be faithfully
// displayed and reproduced in the form originally minted. The Ownership Rights
// only apply to the Artwork in this original form, and do not apply to, and may
// not be exercised in connection with, any version of the Artwork that has been
// materially altered or changed.
//
// ## Excluded Uses.
//
// You may not reproduce, display, use, or exploit the Artwork in any manner other
// than as expressly permitted by the Ownership Rights, as set forth above. In
// particular, without limitation, the Ownership Rights do not include any right
// to reproduce, display, use, or exploit the Artwork for any of the following
// purposes or usages:
//
// - To create any derivative work based on the Artwork.
//
// - To reproduce the Artwork for merchandising purposes (e.g., to produce
// goods offered for sale or given away as premiums or for promotional purposes).
//
// - To make use of the Artwork as a logo, trademark, service mark, or in any
// similar manner (other than personal use as your personally identifying profile
// image, avatar, or graphic, as expressly permitted above).
//
// - Use of the Artwork to promote or advertise any brand, product, product
// line, or service.
//
// - Use for any political purpose or to promote any political or other cause.
//
// - Any other use of the Artwork for your commercial benefit or the
// commercial benefit of any third party (other than resale of the Artwork, as
// expressly permitted above).
//
// - Use of the Artist's IP Rights for any purpose other than as reasonably
// required for exercise of the Ownership Rights, such as, without limitation, use
// of the Artist's name for endorsement, advertising, trademark, or other
// commercial purposes.
//
// ## Artist's Intellectual Property Rights.
//
// Subject to your Ownership Rights (and excluding any intellectual property owned
// by Company), the Artist is and will at all times be and remain the sole owner
// of the copyrights, patent rights, trademark rights, and all other
// intellectual-property rights in and relating to the Artwork (collectively, the
// "Artist's IP Rights"), including, without limitation: (i) the Imagery; (ii) the
// programming, algorithms, and code used to generate the Imagery, and the
// on-chain software code, script, and data constituting the applicable NFT (but
// excluding, for the avoidance of doubt, programming, script, algorithms, data,
// and/or code provided by Company and/or used in connection with the operation of
// the Company platform and marketplace) (collectively, the "Code"); (iii) any
// data incorporated in and/or used by the Artwork, whether stored on or off the
// blockchain; (iv) the title of the Artwork; and (v) the Artist's name,
// signature, likeness, and other personally identifying indicia. The Artist's IP
// Rights are, and at all times will remain, the sole property of the Artist, and
// all rights therein not expressly granted herein are reserved to the Artist. The
// Artist also retains all moral rights afforded in each applicable jurisdiction
// with respect to the Artwork. You hereby irrevocably assign to the Artist any
// and all rights or ownership you may have, or claim to have, in any item falling
// within the definition of the Artist's IP Rights, including, without limitation,
// the copyrights in the Imagery and in the Code. We, the Artist and Company, will
// be free to reproduce the Imagery and the Artwork for the Artist's and Company's
// customary artistic and professional purposes (including, without limitation,
// use in books, publications, materials, websites, social media, and exhibitions
// dealing with the Artist's creative work, and licensing for merchandising,
// advertising, endorsement, and/or other commercial purposes), and to re-use
// and/or adapt the Code for any other purpose or project (including, without
// limitation, the creation and sale of other NFTs), and to register any or all of
// the Artist's IP Rights (including, without limitation, the copyrights in
// theImagery and the Code) solely in the name of the Artist or his designee.
//
// ## Transfer of Artwork.
//
// The Ownership Rights are granted to you only for so long as you remain the
// legal owner of the Artwork. If and when you sell, swap, donate, gift, give
// away, "burn," or otherwise cease to own the Artwork for any reason, your rights
// to exercise any of the Ownership Rights will immediately and automatically
// terminate. When the Artwork is legally transferred to a new owner, as recorded
// on the applicable blockchain, the new owner will thereafter be entitled to
// exercise the Ownership Rights, and references to "you" herein will thereafter
// be deemed to refer to the new owner.
//
// ## Resale Royalty.
//
// With respect to any resale of the Artwork, the Artist will be entitled to
// receive an amount equal to 7.5% of the amount paid by such purchaser (the
// "Resale Royalty"). For example, for any sale of the Artwork, following the
// original sale, to a subsequent purchaser for 1.0 ETH, the Resale Royalty due
// will be 0.075 ETH to the Artist. The Resale Royalty is intended to be deducted
// and paid pursuant to the smart contract implemented in the Code whenever the
// Artwork is resold after the initial sale. However, if for any reason the full
// amount due as the Resale Royalty is not deducted and paid (for example, if some
// or all of the applicable purchase price is paid outside the blockchain), in
// addition to any other available remedies the Artist and Company will be
// entitled (i) to recover the full unpaid amount of the Resale Royalty along with
// any attorneys' fees and other costs reasonably incurred to enable such
// recovery; (ii) to terminate and suspend the Ownership Rights until full payment
// is received; and (iii) to obtain injunctive or other equitable relief in any
// applicable jurisdiction.
//
// ## Illegal Acquisition.
//
// If the Artwork is acquired by unauthorized means, such as an unauthorized or
// unintended transfer to a new cryptocurrency address as the result of hacking,
// fraud, phishing, conversion, or other unauthorized action, the following terms
// will apply until such time as the Artwork is returned to its rightful owner:
// (i) the Ownership Rights will immediately terminate and be deemed suspended;
// (ii) the Artist will be entitled to withhold recognition of the Artwork as
// constituting an authentic work of fine art by him; and (iii) the Artist and/or
// Company will be entitled to take any and all steps necessary to prevent the
// Artwork from being sold or traded, including, without limitation, causing the
// Artwork to be removed from the Company platform and/or any marketplace or
// platform where it is listed for sale. Notwithstanding the foregoing, nothing
// herein will obligate the Artist or Company to take any action with respect to
// any unauthorized acquisition or disposition of the Artwork, and neither we nor
// they will have any liability in this regard.
//
// ## Limited Guarantee.
//
// We guarantee that the Artwork will constitute an authentic original digital
// work of fine art by the Artist. In all other respects, the Artwork and the NFT
// are provided strictly "as is." Neither the Artist nor Company makes any other
// representation, provides any other warranty, or assumes any liability of any
// kind whatsoever in connection with the Artwork, including, without limitation,
// any representations, warranties, or conditions, express or implied, as to
// merchantability, fitness for a particular purpose, functionality, technical
// quality or performance, freedom from malware or errors, or value, each of which
// representations, warranties, and conditions is expressly disclaimed. No
// statement made by the Artist or Company (or by any listing platform or
// marketplace), whether oral or in writing, will be deemed to constitute any such
// representation, warranty, or condition. EXCEPT AS EXPRESSLY PROVIDED ABOVE, THE
// ARTWORK AND THE NFT ARE PROVIDED ENTIRELY ON AN "AS IS" AND "AS AVAILABLE"
// BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.
//
// ## Your Knowledge & Experience.
//
// You represent and warrant that you are knowledgeable, experienced, and
// sophisticated in using blockchain and cryptocurrency technology and that you
// understand and accept the risks associated with technological and cryptographic
// systems such as blockchains, NFTs, cryptocurrencies, smart contracts, consensus
// algorithms, decentralized or peer-to-peer networks and systems, and similar
// systems and technologies, which risks may include malfunctions, bugs, timing
// errors, transfer errors, hacking and theft, changes to the protocol rules of
// the blockchain (e.g., forks), hardware, software and/or Internet connectivity
// failures, unauthorized third-party data access, and other technological risks,
// any of which can adversely affect the Artwork and expose you to a risk of loss,
// forfeiture of your digital currency or NFTs, or lost opportunities to buy or
// sell digital assets.
//
// ## Acknowledgement of Inherent Risks. You acknowledge and accept that:
//
// - The prices of blockchain assets, including NFTs, are extremely volatile
// and unpredictable as the result of technological, social, market, subjective,
// and other factors and forces that are not within our, the Artist's, or
// Company's control.
//
// - Digital assets such as the Artwork may have little or no inherent or
// intrinsic value.
//
// - Fluctuations in the pricing or markets of digital assets such as the
// Artwork could materially and adversely affect the value of the Artwork, which
// may be subject to significant price volatility.
//
// - Providing information and conducting business over the Internet and via
// related technological means with respect to cryptocurrencies and digital assets
// such as the NFT entails substantial inherent security risks that are or may be
// unavoidable.
//
// - Due to the aforementioned risk factors and other factors that cannot be
// predicted or controlled, there is no assurance whatsoever that the Artwork will
// retain its value at the original purchase price or that it will attain any
// future value thereafter.
//
// ## Limitation of Liability.
//
// Our and Company's maximum total liability to you for any claim arising or
// asserted hereunder or otherwise in connection with the Artwork will be limited
// to the amount paid by the original purchaser for the original primary-market
// purchase of the Artwork. Under no circumstances will the Artist or Company be
// liable for any other loss or damage arising in connection with the Artwork,
// including, without limitation, loss or damage resulting from or arising in
// connection with:
//
// - Unauthorized third-party activities and actions, such as hacking,
// exploits, introduction of viruses or other malicious code, phishing, Sybil
// attacks, 51% attacks, brute forcing, mining attacks, cybersecurity attacks, or
// other means of attack that affect the Artwork in any way.
//
// - Weaknesses in security, blockchain malfunctions, or other technical
// errors.
//
// - Telecommunications or Internet failures.
//
// - Any protocol change or hard fork in the blockchain on which the Artwork
// is recorded.
//
// - Errors by you (such as forgotten passwords, lost private keys, or
// mistyped addresses).
//
// - Errors by us (such as incorrectly constructed transactions or
// incorrectly programmed NFTs).
//
// - Unfavorable regulatory determinations or actions, or newly implemented
// laws or regulations, in any jurisdiction.
//
// - Taxation of NFTs or cryptocurrencies, the uncertainty of the tax
// treatment of NFT or cryptocurrency transactions, and any changes in applicable
// tax laws, in any jurisdiction.
//
// - Your inability to access, transfer, sell, or use the Artwork for any
// reason.
//
// - Personal information disclosures or breaches.
//
// - Total or partial loss of value of the Artwork due to the inherent price
// volatility of digital blockchain-based and cryptocurrency assets and markets.
//
// **UNDER NO CIRCUMSTANCES WILL WE BE LIABLE FOR ANY INDIRECT, SPECIAL,
// INCIDENTAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES OF ANY KIND, EVEN IF WE HAVE
// BEEN ADVISED OR OTHERWISE WERE AWARE OF THE POSSIBILITY OF SUCH DAMAGES.**
//
// The foregoing limitations on our liability apply to all claims, whether based
// in contract, tort, or any other legal or equitable theory.
//
// Notwithstanding the foregoing, nothing herein will be deemed to exclude or
// limit in any way the Artist's or Company's liability if it would be unlawful to
// do so, such as any liability that cannot legally be excluded or limited under
// applicable law. It is acknowledged that the laws of some jurisdictions do not
// allow some or all of the disclaimers, limitations or exclusions set forth
// herein. If these laws apply in your case, some or all of the foregoing
// disclaimers, limitations or exclusions may not apply to you, and you may have
// additional rights.
//
// ## Indemnification & Release.
//
// To the fullest extent permitted under applicable law, you agree to indemnify,
// defend and hold harmless the Artist and Company and their respective
// affiliates, and, as applicable, their respective officers, employees, agents,
// affiliates, legal representatives, heirs, successors, licensees, and assigns
// (jointly and severally, the "Indemnified Parties") from and against any and all
// claims, causes of action, costs, proceedings, demands, obligations, losses,
// liabilities, penalties, damages, awards, judgments, interest, fees, and
// expenses (including reasonable attorneys' fees and legal, court, settlement,
// and other related costs) of any kind or nature, in law or equity, whether in
// tort, contract or otherwise, arising out of or relating to, any actual or
// alleged breach by you of the terms of this Ownership License or your use or
// misuse of the NFT or Artwork.
//
// You hereby release, acquit, and forever discharge each of the Indemnified
// Parties from any damages, suits, or controversies or causes of action resulting
// from your acquisition, transfer, sale, disposition, or use of the NFT or
// Artwork in violation of the terms of this Ownership License, and you hereby
// waive the provision of California Civil Code Section 1542 (if and as
// applicable), which says: "A general release does not extend to claims that the
// creditor or releasing party does not know or suspect to exist in his or her
// favor at the time of executing the release and that, if known by him or her,
// would have materially affected his or her settlement with the debtor or
// released party." If any comparable legal provision applies in any other
// jurisdiction, you hereby also waive such provision to the maximum extent
// permitted by law.
//
// ## Applicable Law.
//
// This Ownership License is governed by the laws of New York State applicable to
// contracts to be wholly performed therein, without reference to
// conflicts-of-laws provisions.
//
// ## Arbitration.
//
// Any and all disputes or claims arising out of or relating to this Ownership
// License will be resolved by binding arbitration in New York State, and not by
// court action except with respect to prejudgment remedies such as injunctive
// relief. Each party will bear such party's own costs in connection with the
// arbitration. Judgment upon any arbitral award may be entered and enforced in
// any court of competent jurisdiction.
//
// ## Waiver of Jury Trial.
//
// YOU AND WE WAIVE ANY AND ALL CONSTITUTIONAL AND STATUTORY RIGHTS TO SUE IN
// COURT AND TO HAVE A TRIAL IN FRONT OF A JUDGE OR A JURY. You and we have
// instead agreed that all claims and disputes arising hereunder will be resolved
// by arbitration, as provided above.
//
// ## Waiver of Class Action.
//
// ALL CLAIMS AND DISPUTES FALLING WITHIN THE SCOPE OF ARBITRATION HEREUNDER MUST
// BE ARBITRATED ON AN INDIVIDUAL BASIS, AND NOT ON A CLASS-ACTION,
// COLLECTIVE-CLASS, OR NON-INDIVIDUALIZED BASIS. YOUR CLAIMS CANNOT BE ARBITRATED
// OR CONSOLIDATED WITH THOSE OF ANY OTHER OWNER OF AN NFT OR OTHER WORK BY THE
// ARTIST. If applicable law precludes enforcement of this limitation as to a
// given claim for relief, the claim must be severed from the arbitration and
// brought in the applicable court located in New York State. All other claims
// must be arbitrated, as provided above.
//
// ## Artist's Successor.
//
// After the Artist's lifetime, the rights granted to the Artist herein will be
// exercised by the successor owner of the Artist's IP Rights, which owner will be
// deemed the Artist's successor for all purposes hereunder.
//
// ## Modifications & Waivers.
//
// The terms of this Ownership License cannot be amended or waived except in a
// written document signed by an authorized person on behalf of the Artist and
// Company. Our failure in any instance to exercise or enforce any right or
// provision of this Ownership License will not constitute a waiver of such right
// or provision.
//
// ## Severability.
//
// If any term, clause, or provision of this Ownership License is held to be
// invalid or unenforceable, it will be deemed severed from the remaining terms
// hereof and will not be deemed to affect the validity or enforceability of such
// terms.
//
// ## Conflicting Terms.
//
// In the event of any conflict between the terms of this Ownership License and
// any terms imposed by or in connection with any platform, marketplace, or
// similar service or application on which the Artwork is offered, listed, sold,
// traded, swapped, gifted, transferred, or included the terms of this Ownership
// License will control.
//
// ## Entire Agreement.
//
// This Ownership License sets forth the entire agreement between the parties with
// respect to the Artwork, superseding all previous agreements, understandings,
// statements, discussions, and arrangements in this regard.
//
// ## Contact.
//
// Inquiries regarding this Ownership License may be sent to:
// [email protected]
//
//