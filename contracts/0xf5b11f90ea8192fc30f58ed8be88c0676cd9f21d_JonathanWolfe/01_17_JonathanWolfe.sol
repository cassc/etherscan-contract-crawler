// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz
/// @artist: Jonathan Wolfe

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                        .clc;'.         ...                                                                                                                        //
//                     .:oONWWWX0x:.  .:okO0KOo'              ...,::cc:;,'.                                                                                          //
//                     .xK0XWWKdccclxk0NWWNNWNXl     ....,:ldk0KNWMMWWWWNNK0kol;'.....                       ...''''.....      ...',;::ldxkkxdol;'.                  //
//                     cx,.;0NOd:..oXWWWWWWWWWNOxkkOO0KXXNWMMMMMWK0NNX0KNWWWWMWWN0o:;;;;;;;;;;,,;;;;;;;;;:::::;;;;;;;;::;;,,;;;;::;;,;oO0XWMMMMMWNKx;                //
//                  .;oc,;cdKWWWXxxXWWWMWWN0k0N0xkKNWWWWWNkoddxxdl;''...c0NWWWMMM0'               ..........                          cXWWMMWMMMMWWMNd.              //
//                 .oxloOXWWWWWWWWWWWNx:;,.. .'.  .';:cllc.     ....'',,,;:;;:dKWk.         ...''.                   .::;,.            .;oKWMMMMMWWMMWk.             //
//                ,olkNWWWWWWWWWWWWWW0'                    .;lxOKXXXNNNWNX0xdlclo,.  .':lodOKKKNNKxolc:'..   'oxkxddxKWWWWXx:,,,.         .:oxkxdxOKWMWd.            //
//               :dokNWWWWWWWWWWWWMWW0'                  'dKWMWWWWWWWWWWWWWMMMMWXK0O0KNWWWWWWWMWWWMMWWWNX0OkxKWWWWWWWWWWWWMWWNWW0;                ,kNWWK,            //
//             .lllKWWWWWWWWWWWWNWWWWK;   ,d:           :KWWMMMWWWWWWWWWWMMMMMMMMMMMMWWWWWWWWWWWWWMMMWWWWMMMMWWWWWWWWWWWWWWWWWXx,                 lNWWWNl            //
//            'dc.:NMMMMMMMWWMWWNNWNWX;  ,0Wd.         '0WWMMMMMMMWNXNNX00KWWWWMMWWWWWWWWWWMMWWX0OkkkkO0XWMMMMWWWWWWWWWWWWWWWMk.           ...    cXWWWWx.           //
//           ;Ol  :NMMMMMMMMMWWWWWWWNklodkNM0'        .dWWMMMMMMMMW0dl;.. .,:;;odolcclc:;,:llc;',coxl'...:kNMMWWWNNWWWMWWWWMMWo          .dKX0o:cxKNWWWWd            //
//         .dXd.  .OMMMMWMMW0OX0ooxOxONWWWWMWk'       '0WWMMMMMMMMMWWXc        .cxkOOOkxddkOOOOOKWMMWKc.  .dNWWWWWWWWMMWMMMMMK,          'kNWWWWWWWWWWWNc            //
//       .:kXx.   .oNMWWWWNx. ..  .xXNNWWWWWWNd.      ,KMWMMMMMMMWWWWWd.      .kWWWWWMMMMMMMMMMMMMMMWWNd.  'xWWWWMMMMMMMMMMWWd            .OMWWWWWWWWWMX;            //
//      'xo,..     .oXKxol,   .;clkNWWWWWWWWWXl       :XMMMMMMMMMWWMWWNx.    .dNWWWWMMMMMMMMMMMMMMMKo:;.  'oo0MMMMMMMMMMWMWWO'           'dKWWWMWWWWWWW0'            //
//      :kdl.        ...   :kdk0KNNNNNWWMMWWWWKo.     dWWMMMMMMMMMMMMWWX;    ;ONWMWWWWMMMMMMMMMMMWO'      .dxkMMMMMMMMNKOxo:.            lNWWWWWNNNWWWWd             //
//       ,oxo;'...;ldkO0Oxd0NNNNNXXNNWWWWWWWWNNW0;   .xXXMMMMMMMMMMMMWWX;   .;dXXKNMWXXNXKOkKWOdXK;        oKKMMMWMMMWd.                 :XWWWWNNWWWWWX:             //
//          .;c::cx00Oxoc;'.....'..'cONWWWWWWWNNWk.  .OolNMMMMMMMMMMMMMWk'   .o0;.xWXc,lxxdoONl oO.        oWMMMWWMMM0'                  ;KWWWWWWWWWWWO.             //
//                 ..                .lXWNWWWWNNWN:  ,0c;XMMMMMMMMMMMMMMW0,  ,kc  :0K0ONWWMMWWXk0Xd;.  ;xl.:NMMMMMMMX:              ..   cNWNWWWWWWWWWo              //
//                                    .dNNNNWWWWWMk. ;0;;XMMMMMMMMMMMMMMMNl ,0Nl .xNWWWWWWMWWWWWWWW0' cXWX:'0MWMMMW0;             'd00;.oKWNNWWWNWWWW0'              //
//                                     '0WNWWWWWWNk' ,d';XMMMMMMMMWWMMMMWWo.oWWx.,KMWWWWWWWWWWWWWWK; :XWWNc.xMMWWNx.             '0WMNkkNWWWWWWWWWWWWl               //
//                                      cXNWWWWWW0,     '0MMMMMMMXdlkXNWWWl.dWWo .OMWWWWNXXXkoldoc. .xWWW0' lWMWk,               '0MMWWWWWWWMWWWMMWMK,               //
//                                      .dNWWWWWMX:     .OMMMMMMWo   .':ll. 'oo.  'clddl;...         .;lc'.,kWMO.                .kWWMMWWWWWWWWWMMMWx.               //
//                                       .dNWWWWMWk.    .OMMMMMMK,                                       .dNMMWo                .oNWWWWWWWNWMMWWMMWWl                //
//                                        .lXWWWWWNd;'  .kWMMMMM0'                                       '0MWWWl              .l0WWWWWWWWNNWMMWWMWWN:                //
//                                          ;0WWWWWxck: .xMMMWMMNc             .;:clodxxxo,              .OMWWWo              ,0WWMWWWWWWWWMMMWMNXWX;                //
//                                           .dXWWN0dOd. lWMNKNMW0,           .dNWWWWWWWMWXo.            ,0MMWNc    ....       .xWMMMMMMMMMMMMMKcdWK,                //
//                                             .ckKXXNk..xWWXlc0NWK:        .';dXWWWWWMMWWMWk;.          cXWMWWk.   .';col;.    .dNMMMMWWXXWMM0,,0W0,                //
//                                                ...:k;.dKXXo..kWK;     ..,kXWMMMMMMMMWWWMMMNXx.        dNWNOkx'       .;xOl.    ,dOkl:,.cXWk'.oKNX:                //
//                                                    lc  .... .xWKl,,,,,;;,:x0XWMMWMMWWMMMMMMW0:.       lXXo.            .kW0,     .     cN0' ;dOXKd.               //
//                                                    ;Oxl,    .xNl           ..;codx0XNWMMMMMWWN0d;.     ..            .;:ldkk'          cKc 'cxOkdd:               //
//                                                    .kWNXl   .xK,                  ..':lox0NWWWWWWKkoc,.          .,;:;'.  .dkc;.      .ol .::ddllcc.              //
//                                                     lNWNo   .kd.                         .';cdkKNWWWWNx.     .';;;,.       ;KWNo  ,,  ;o. .:,:,,:...              //
//                                                     oWMNo.  ;O:                                .':loxko;,,',,;;.           .xWWO'cNK,.o;  ';.'  .                 //
//                                                    .xWWWNO; lk.                                        ..                   cXWNOKMN:;d.  ;;                      //
//                                                    .kWWWWX:.ko                                                              :XNWWWMWOkl   :;                      //
//                                                    .xNWWWK;:O,                                                              'ONNWWMWWX:  .c;                      //
//                                                    .dNWWX0lxk.                                                              .dNWWWWWWX:  .c,                      //
//                                                    ;OXNXl.'xl             ..     .,,                '.                      .kWWWWMN0O;  .c.                      //
//                                                   .oodk:..dd.            .xKo.   ,KNc    .cc.      lNk.                     .xWWMMMX0O;  ,:.                      //
//                                                   ;d.:o. ,Oc              ,OW0,  .xMk.   oWMO'    ;XNl                      .kNWWWWx;xo  ;c                       //
//                                                  'o; cl  ,x;               .oNXl..;XNl  '0WWWO'  .kWx.                     .xNNWWKo. cx. :c                       //
//                                                 ,d; .oc  ,x,          'xd,   :XNXo.lNX:.oW0cxW0, lNX;                      lXNWW0;   ;x' :c                       //
//                                                'OKdldx'  'k:          .dXNkl;,xWMNc.dW0xXNc .dNKkKWo                      ;0xdNX:    ,d' :l                       //
//                                               'OOkXWNo   ,O:            .cx0XXXXXKc .xWMWd.   :KWNo.                     'o:..dd.    ,x, :l                       //
//                                               .ldxXN0,   ,0c               .......   .lxc.     .;'                      .o,  .d:     ;x' ,d.                      //
//                                                 .,xNXOoc;l0c                                                           .l,  .lc.     :k, .d:                      //
//                                                 .dNWNNWWNXo.                                                          'l'  .lc       cKc  ld.                     //
//                                                 'kNWWMNX0c                                                           ,Oo. .ll       'OWXd,;x:                     //
//                                                  .;oxxdl'                                                           ,0WKkdkd.      'OWWMWNK0c                     //
//                                                                                                                    .dWWNKKKc       ,xO0K0dc'                      //
//                                                                                                                     ,dkkdl,           ...                         //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract JonathanWolfe is AdminControl, ICreatorExtensionTokenURI {
    address private constant _creator = 0x2438A0eeFfA36Cb738727953d35047fb89c81417;
    string private _tokenURI;
    bool private minted;

    function mint() public adminRequired {
        require(!minted, 'Already minted');
        minted = true;
        
        address[] memory addressToSend = new address[](1);
        addressToSend[0] = msg.sender;
       
        uint[] memory amounts = new uint[](1);
        amounts[0] = 15; 
        
        string[] memory uris = new string[](1);
        uris[0] = "";

        IERC1155CreatorCore(_creator).mintExtensionNew(addressToSend, amounts, uris);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function setTokenURI(string memory newTokenURI) public adminRequired {
        _tokenURI = newTokenURI;
    }

    function tokenURI(address creator, uint256) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return _tokenURI;
    }
}