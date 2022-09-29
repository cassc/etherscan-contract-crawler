// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz
/// @artist: LIŔONA

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                       ..'.                                                                   //
//                                                                                       .';'                                                                   //
//                                                                                                                                                              //
//                                                            ..','...                                                                                          //
//                                                         ..,:cccccc:,'.                                                                                       //
//                                                        .,;;'....',:ll;.      ...'''...                                                                       //
//                                                      .';,..     ..':l;.     .;cc:;;;;;;,'..                                                                  //
//                                                    ..,,..    ..';::;'.      .cdc'. ....,;::;.                                                                //
//                                                   .,,..    .':c:,'.         .:ol'.       .':lc'.                                                             //
//                                                  .''.   ..;c:;..             ':l:.       .,..;cc,.                                                           //
//                                                  ...  .':c:'.                ..;l,.     .:o,  .,ccc:'                                                        //
//                                                 ..  .'::,..                    .cl'     .:d,    .':dd,.                                                      //
//                                               .,:'..;:,.                       .,o:.     .,.      ..;;.                                                      //
//                                               'oo,,c:'...             ..,,,;'...'ll.         .;;'.                                                           //
//                                              .cxdcldolcc:::;,'...    .coc::lolcccoc.        .lxxxc...                                                        //
//                                              .cxd:,;:::ccloodddoc:,..:d:. ..';:lo:.         ,ddokd,,:.                                                       //
//                                              .:xd;.    .....',;:ldxolod;.  .  ..co,.        .lkkOd'.:;.                                                      //
//                                              .;dd;.             ..;coxxl'..     .lo,         .;lxo..'c,.;'                                                   //
//                                               ,dx:.                ..,lxd:.      'oo.          .oo.  ,lox:.                                                  //
//                                               'ox:.                   .:xc.      .;d:.         .lo.  .,ox:.                                                  //
//                                               .lxc.                    .'.        .ll.         .lo''...:d;.                                                  //
//                                               .cxl.                                ,c.         .cd,;oc;cx;                                                   //
//                                               .cko.                                 ..          'c,.'cdkk;                                                   //
//                                               .:kd.                                              .   .,dx;                                                   //
//                                                :kd'                                                   .ld,                                                   //
//                                                ;kx'                                                   .ld'                                                   //
//                                                ,xk,                                                   .ll.                                                   //
//                                                .ok;                                  ..                .'                                                    //
//                                                .lO:                                 'dc.                                                                     //
//                                                 ;kl.                               .cOd'                                                                     //
//                                                 .:,                                .:Ok,                                                                     //
//                                                                                     ;kO:                                                                     //
//                                                                                     ;kO:                                                                     //
//                                                                                     :Ok;                                                                     //
//                                                                                    .l0x'                                                                     //
//                                                                                    'x0l.                                                                     //
//                                                                                   .l0x'                                                                      //
//                                                                                  .:OO:.                                                                      //
//                                                                                 .;kOc.                                                                       //
//                                                                                .;xOc.                                                                        //
//                                                                     ......   ..:kk:.  ..                                                                     //
//                                                                     ...',;;'.,ldd;......                                                                     //
//                                                                     ..';cl:,...........  .';;,'....                                                          //
//                                                                 ...,:lol:'.              .'cc:,''''''....                                                    //
//                                                            ...',;:ccc;'..                 .:c:'.  .....'''.....                                              //
//                                                        ..';::cc:;,'..                     .,cc,.         ....'''...                                          //
//                                                   ..',;:cc:;,'...                          .:c;.              .';'...                                        //
//                                                .',::::,,'...                               .,cc,.             .;l;....                                       //
//                                             .';::;,...                                      .;c:'.            .:c:.                                          //
//                                      .,;...,::;'..                                          .':c;.           .':c;.                                          //
//                                     .:oc,,:lc;..                                             .;cc,.          .':c;.                                          //
//                                    .,ldc;:cccc:,..                                            .:c:..          .':;.                                          //
//                                    .,ooc,,:ccccc:;,...                                        .;cc,.            ...    ..                                    //
//                                    .,loc'..,;:ccccc:;,'..                                     .'cl:.                 .;oo;.                                  //
//                                    .,loc'. ...',::ccccc:;,'..                    ..........   .'clc,.               .;oxd;.                                  //
//                                    .;ool,.     ...',;:ccccc:;,...            ...';:cccccc:;'...'clc;.               'ldxl,.                                  //
//                                    .:odo;.         ...',:cccccc:;'..        .,;:cc:;,;;:cccc:;::clc,.              .;oxo:.                                   //
//                                    .:dxd:.             ...,;:ccccc:;'..    .'cllc;......,:cclllc:;'.               .:ddc..                                   //
//                                    .cdxxc.                ...';:ccccc:;'....;ccc:..     ..,clllc,..                .:do;..                                   //
//                                    .cdkxl.                    ..',:ccccc:;'':lll:.        .,clllc,.                .;oo:.                                    //
//                                   ..cdxxo'.                      ..',:clllc:clll:..        .;llllc,.               ..:l;.                                    //
//                                   ..:dxko,.                         ..,;clllllllc'.        .;lllllc,.               ....                                     //
//                                    .:oxkd;.                           ...,:clllll:'..      .,lllcclc'.                                                       //
//                                    .,lxkd:.                              ..,:cllllc:'.     .,lll;;ll:..                                                      //
//                                    .'lxxd:.                               ...,:cllllc;.    .;lol;,clc,.                                                      //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract LIRONA is AdminControl, ICreatorExtensionTokenURI {
    address private constant _creator = 0x2438A0eeFfA36Cb738727953d35047fb89c81417;
    string private _tokenURI;
    bool private minted;

    function mint() public adminRequired {
        require(!minted, 'Already minted');
        minted = true;
        
        address[] memory addressToSend = new address[](1);
        addressToSend[0] = msg.sender;
       
        uint[] memory amounts = new uint[](1);
        amounts[0] = 10; 
        
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