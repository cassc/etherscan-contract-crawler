// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz
/// @artist: JAKE

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    GGGGEJ|/]]J/*||/*||*||******:::**:.***|/|*|/|/*:.....:|***||/|**/J]]]I//]]]JII]]J/]*:::::::**J*/$EG]    //
//    O]EE]/JI]II|*|//|||******:::::**:*...*|**/|*//*....:*||**|/|***//J//I**]]]I/||**|/]:::::.::|*/|*KAE]    //
//    A$E]]]]EE]]*|/I/||*******::::**:******:*:::///....*/*I**/J****|//*|/**|JJ//||***:*::.....::/|*|*GOE]    //
//    DOE|JEEGE]J|III/|********::::::********JI*..:....*I|/*|J/||***//**|**|//|****::::::.......://*|/G$GE    //
//    WWJ||]G$$]/JGE]J/*****:::::::::******|/JI:*.....*I*J*/J*****/J//|*********:::::::|].......:|***J]]E]    //
//    WW]J//EKAEJ]GKE]//****:::::::*:*****|///::....:/]//*J/|||**//||||***:**::::::::::*/.......::***JJJJJ    //
//    WWOEI|J$K$]]EAEE]/|**:::::::::******|||/....::J]//|/|**/J*|*|*|****::::::::::......:......::***/|JJ/    //
//    WDDO]|*JGAEEEA$GEJ***:::::::::*******|/.....:/]I]/|***//|**/|****:::::....................::*:*||JJ/    //
//    DDDDE/|/]EGEE$K$AJ**:*::::::**********.....*IJIE/*****|********:::::.......................:::**|J/*    //
//    DDDDEI//J]E]]E$EE*:*:::::::***:*****:......//J]*****||*****||**:::::.......................:.:**|/**    //
//    DDDWE]JJ]]]]]EEE|:*:::::****:*****::......*|//************||***::::..........................::*/*::    //
//    WWWWD$]]JI]]]EE]********|||*///||**......*|/|*******|/|**||**::::::::........................*:**:**    //
//    WWWWDAE//J]]J]]I******//IJ/]EGGEGE:.....*J/********/||**||**::::::::::::::::::::............:*:**:**    //
//    WWDDDOE|]J]I||]||***:*/I]/E$KKOOD$:....IK]**|//**//*|/|//|**:::**||*|J]]]]EE]/IJ/*:.........:::****/    //
//    WWDDDO]IEI/I********]GE]||E$DDDD]*..::]W]**/IJI]J///J|||/|*****/JI/JGAAKOKAE/GE]]/*:......:.:**/|*/A    //
//    DDDDDKI]EJ|/*::::*****::**|$DDD]...*:EB$J/******|||||*:::::::::|J/EKK$AGODA]J...//]]*:......:*JI|*ED    //
//    DDDDDG]]]I/**:::::::::::***|]GA.:.:|]NEJ]J/**::::****:.......:]]JGNOAEKOGKK$E.....:|/:......*/]J*JOD    //
//    DDDDDDAE///*::::::::::::**/JIE...:]OD]/]GE/*:::::::**:.......*/JGODKOOKOOKGJ::..:..........:*//*JKDD    //
//    DDDDDDDG/I/|:::::::::::::*****...:WKJJEE]|*:::::*::::........:|EEGGGAEOO$GGJ/**............:*|:|KDDD    //
//    DDDDDDDGEEIJ::::::::::::::***....]E]IJ/**:::::::::::::.........|]EEEEEE]]J/*:..............:::*EDDDD    //
//    DDDDDDO$KOEE/:::::::::::::**....*IJ/|**:::::::::::::::.......*..:JIE]]$I/**................:.:]DDDDD    //
//    DDDDDDDDDDAGE*::::::::::***...../****:::::::::::::::::...........::|I/|**::.....:...........:*ODDDDD    //
//    DDDDDDDDDDD$GI:::::::::****....******::::::::::::::::................::::.................::*GDDDDDD    //
//    DDDDDDDDDDDO$E|:::::::::**...**:**:::::::::::::::::::....................................:::]DDDDDDD    //
//    DDDDDDDDDDDDOAE*:::::::::...:*:*:::::*:::::::::::***:...................................:::IADDDDDDD    //
//    DDDDDDDDDDDDDD$G*:::::::...:******:::::::::::::*:*:::..................................:::JODDDDDDDD    //
//    DDDDDDDDDDDDADOOE::::::...:********::::::::::**::::::.................................:::]ODDDDDDDDD    //
//    DDDDDDDDDDDDDDDDO*:::::..::::********:::::::::::::::.................................::*EDDDDDDDDDDD    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract JAKE is AdminControl, ICreatorExtensionTokenURI {
    address private constant _creator = 0x2438A0eeFfA36Cb738727953d35047fb89c81417;
    string private _tokenURI;
    bool private minted;

    function mint() public adminRequired {
        require(!minted, 'Already minted');
        minted = true;
        
        address[] memory addressToSend = new address[](1);
        addressToSend[0] = msg.sender;
       
        uint[] memory amounts = new uint[](1);
        amounts[0] = 27;
        
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