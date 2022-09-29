// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz
/// @artist: Defaced

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//                             ,╓w∞MMMTT░░░░⌠⌠░░⌠⌠⌠░░░TTMMm∞wµ,                            //
//                     ,▄m$█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░⌠▌B╦▄,                    //
//                ,▄Ñ▒▒▒▒▒▒▐░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▌▒▒▒▒▒▒B▄                //
//              ,▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐▌▒▒▒▒▒▒▒▒▒▓,             //
//             ▄▒╣╣╣╣╣╣╣╣╣╣▒▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐▒╣╣╣╣╣╣╣╣╣╣▒▄            //
//             ▌╢╢╢╢╢╢╢╢╢╢╢╢▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█╢╢╢╢╢╢╢╢╢╢╢╢▓            //
//            ▐▓╢╢╢╢╢╢╢╢╢╢╢╢█╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢█╢╢╢╢╢╢╢╢╢╢╢╢╫U           //
//             ▌▓▓▓▓▓▓▓▓▓▓▓▓█╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢╢█▓▓▓▓▓▓▓▓▓▓▓▓▓            //
//             ▐╣▓▓▓▓▓▓▓▓▓▓▓▓╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌▓▓▓▓▓▓▓▓▓▓▓▓▌            //
//              ▀▓▓▓▓▓▓▓▓▓▓▓▓▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣▓▓▓▓▓▓▓▓▓▓▓▌             //
//               █▓▓▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▀▀▀▀▀▀▀▀▀╙"╙`▀▀▌▀▀▀▀▀▀▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓█              //
//               ▐▓▓▓▓▓▓▓▓▓▀▀█░░▒▒▌               ▐            `"▀▀▓▓▓▓▓▓▓▓▓`              //
//                ▀▓█▀▀      ▓▒▒▒▒█               ▌                    ▀▀█▓▌               //
//                 █▓▌       ▐▒▒█▒▓              ▌           ▌          █▓█                //
//                  ▓▓µ   ▄  ▐▄▄█▄▓, ╒" ▄∞∞∞∞∞∞∞▄▄∞╦▄  'Ç ,,▄█▄,   ▄   ╒▓▓`                //
//                  ▀▓█   ▄███▀▀▀▀▀▀██▄░░░░░░░░░░░░░░░▄▄██▀▀▀▀▀▀███▄   █▓▌                 //
//                   █▓▌▄██▒▒▒▒▒▒▒▒▒▒▒▌░░░░░░░░░░░░░░░█▀▒▒▒▒▒▒▒▒▒▒▒▀█▄▐▓█                  //
//                    ▌██▒╢╢╢╢╢╢╢╢╢╢╢╢▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓╢╢╢╢╢╢╢╢╢╢╢╢╢▒██▓                   //
//                    ▐╣█▀▀▀▀▀▀▀▀▀▀▀▀▀▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐▀▀▀▀▀▀▀▀▀▀▀▀▀▀█╢▌                   //
//                     █▓▄▄▄▄▄▄▄▄▄▄▄▄▄▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐▄▄▄▄▄▄▄▄▄▄▄▄▄▄▌█                    //
//                     ,▌█▓▓▓████████▓▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐▓▓████████▓▓▓█▓ ,                   //
//                 ,▓▒▒╣╢╢█▓▓▓▓▓▓▓▓▓▓▓▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓███▓▓▓▓█▓╣╢▓╢▓▌                //
//                 ▌╢╢╣▓▓▓█▓╢╢╢╢╢╢╢╢╢▒█▄▒▒▒▒▒▒▒▒▒▒▒▒▒▄█▌▒╢╢╢╢╢╢╢╢╢▓▌▓▓▓▓▓▓▓h               //
//                ▐╣╢╢▓▓▓▓▓████▄▄▄▄████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▀███▄▄▄▄████╢▓▓█████                //
//                ▐▓████████░░░█▒▒▒▒█  ▀▓▓▓▓▓▓▓▓▓▓▓▓▓▀▄▀▒░░░░░▀░░▐█████████                //
//                 ██████████▒▒▐▒╣╢╢▐    ,▄▄▓▓▓▓  ░░░▓░▒▒▒▒▒▒▒▒▒▒█████████                 //
//                 █▓▓▓▓▓▓▓▓▓▌▒▒▌╢▒▒▓M▒▒░▒▒█▓▓▓▌░░░,▀▒▒▒▒▒▒▒▒▒▒▒▐▓▓▓▓▓▓▓▓▀                 //
//                  █▓▓▓▓▓▓▓▓█▄▒▀▀░▒▒▒▒▒▒▒▒█▓▓█ ░░▄▀▒▒▒▒▒▒▒▒▒▒▒▄█▓▓▓▓▓▓▓▀                  //
//                   ▀▓▓▓▓▓▓▓▓█▓▒▒▒▒▄▄▒▀▀▀▀▌▓▓▀░░█▀▀▀▀▀Ñ▄▄▒▒▒▒▓█▓▓▓▓▓▓▀                    //
//                     '▐██████▓█▌▒▒▒▒▒▒▒▒▒▌╢▌░ ▓▒▒▒▒▒▒▒▒▒▒▒▓█▓██▓▓▓█µ                     //
//                     ▄▓▓▓█████╢▓▌▒▒▒▒▒▒▒▒▒▓░╓▌▒▒▒▒▒▒▒▒▒▒▒▓▒╢██▓▓▓▓▓▓▄                    //
//                    ▓▓▓▓▓▓▓███▌╣▒▓▒▒▒▒▒▒▐▒▌▄▒▒▒▒▒▒▒▒▒▒▒▒▓╢╣▓▓▓▓▓▓▓▓▓╣▓                   //
//                    ```  -▐█▓██╣▓▓▓▌▒▒▒▒▓█▓▒▒▒▒▒▒▒▒▒▒▒▓▌▓▓╢█▓▓▓ -  ```                   //
//                          █▓▓▓▓█▓▓▓╢█▒╣╣█▀▒╣╣╣╣╣╣╣╣╣▒█╢▓▓▓█▓▓▓▓█                         //
//                          ▓▓▀▀▀▀▓╢▓▓▓▓▌╢▒╢╢╢╢╢╢╢╢╢╢▓▓▓▓▓▓▓▀▀▀▀▓▓                         //
//                                  "▀▀▀▀"""""""""""╙▀▀▀▀"                                 //
//                                                                                         //
//                                                                                         //
//                                     ▐▌                                                  //
//      ▄                              ▐▌           ,▌▀▀N▄                                 //
//      ▌                              ▐▌   ▄▄▄▄   ,▌     █                ▄▄▄  ▀█▄▄▄      //
//    ▄▄█mA▄▄  ,                 ▄AMP4▄▐▌  ▐M      █       ▄▄▄     ▄▀▀    █▄▄,`   █  ▀▄    //
//      █    █ █  j▌             █     ▀▌  ▐▄▄▄   ▄█▄▄▄  ▐▀   ▐█  ▐▌     ╙█`     █   █     //
//     ▄█▄▄▄▀  ╙▄▄▄█             ▀▄    █▌  █▄▄▄    █     ▀▄▄▀▀ ▌  ▌▄▄▄▄▀ ▀▀▀▀  ▄█▄▄▄▀      //
//                 █               ▀▀▀"             █                                      //
//          ▀,    █'                                                                       //
//           "▀▀▀▀                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////

contract Defaced is AdminControl, ICreatorExtensionTokenURI {

    string[] private assetURIs = new string[](7);
    uint private startingTokenID;
    address private constant _creator = 0xFE7d465d8c420Ee4aeAd45D54D32defc4e3CfF2c;
    
    bool private minted;

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function mint() public adminRequired {
        require(!minted, 'Already minted');
        minted = true;     
        
        uint256[] memory mintedTokenIDs = IERC721CreatorCore(_creator).mintExtensionBatch(msg.sender,7); 
        startingTokenID = mintedTokenIDs[0];
    }

    function setTokenURIs(string memory asset1, string memory asset2, string memory asset3, string memory asset4, string memory asset5, string memory asset6, string memory asset7) public adminRequired {
        assetURIs[0] = asset1;
        assetURIs[1] = asset2;
        assetURIs[2] = asset3;
        assetURIs[3] = asset4;
        assetURIs[4] = asset5;
        assetURIs[5] = asset6;
        assetURIs[6] = asset7;
    }

    function tokenURI(address creator, uint256 tokenID) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        require(tokenID >= startingTokenID && tokenID <= startingTokenID + 6, "Invalid token");
        return assetURIs[tokenID - startingTokenID];
    }
}