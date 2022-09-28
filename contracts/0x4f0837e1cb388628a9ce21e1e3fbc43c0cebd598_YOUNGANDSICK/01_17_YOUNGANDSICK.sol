// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//                                                          .                      //
//                                                      `<rt                       //
//                                                 ."_n$$$r                        //
//                                             .,}*$$$$$$v.                        //
//                                            .`"I}8$$$$W.                         //
//                                            ."-v$$$$$8'                          //
//                                        ':}*$$$$$$$$%`       ...                 //
//                                    `l/8$$$$$$$$$$$$c|txv#&@B|,                  //
//                                `>fB$$$$$$$$$$$$$$$$$$$$$B|,                     //
//                                '^,l-(x#@[email protected]\"                        //
//                                         `[@[email protected]\,.                          //
//                                     ."]*$$$$$$$B(".                             //
//                                  '[email protected]$$$$$$$$$$Muxjt\(1}]-+:.                   //
//                              ."[M$$$$$$$$$$$$$$$$$$$$$$$B{`                     //
//                           'lr$$$$$$$$$$$$$$$$$$$$$$$$$r,                        //
//                       ."}M$$$$$$$$$$$$$$$$$$$$$$$$$*>'                          //
//                    .:(cuxrf/|)1}}W$$$$$$$$$$$$$$%[`                             //
//                               '_W$$$$$$$$$$$$$t,                                //
//                            .;n$$$$$$$$$$$$$#<.                                  //
//                          `{B$$$$$$$$$$$$$B{,,,,,,,,,,,,,,`                      //
//                       '~M$$$$$$$$$$$$$$$$$$$$$$$$$$$$$n!'                       //
//                    .;u$$$$$$$$$$$$$$$$$$$$$$$$$$$$$rI.                          //
//                  ^(@$$$$$$$$$$$$$$$$$$$$$$$$$$$$f;.                             //
//               '~M$$$$$$$$$$$$$$$$$$$$$$$$$$$$t,.                                //
//             .l}?_<!;:,"^}$$$$$$$$$$$$$$$$%(,.                                   //
//                       :*$$$$$$$$$$$$$$8}^                                       //
//                     :#$$$$$$$$$$$$$$$B({}[]?-_+~<>l'                            //
//                   ;M$$$$$$$$$$$$$$$$$$$$$$$$$$$n~`                              //
//                 ;M$$$$$$$$$$$$$$$$$$$$$$$$$W{,.                                 //
//              .lW$$$$$$$$$$$$$$$$$$$$$$$8|;'                                     //
//             .;iiiiiiiz$$$$$$$$$$$$$$ri`                                         //
//                     i$$$$$$$$$$$#]".                                            //
//                    [email protected]\?!,`                                          //
//                   _$$$$$$$$$$$$$$#);'                                           //
//                  ]$$$$$$$$$$$n-".                                               //
//                 {$$$$$$$Bf<`                                                    //
//                ($$$$$$$$z;.                                                     //
//               /$$$$$$$$$$c}.                                                    //
//             .r$$$$$z(>"'                                                        //
//            .uWt_,'                                                              //
//            ..                                                                   //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////

contract YOUNGANDSICK is AdminControl, ICreatorExtensionTokenURI {
    address private constant _creator = 0x2438A0eeFfA36Cb738727953d35047fb89c81417;
    string private _tokenURI;
    bool private minted;

    function mint() public adminRequired {
        require(!minted, 'Already minted');
        minted = true;
        
        address[] memory addressToSend = new address[](1);
        addressToSend[0] = msg.sender;
       
        uint[] memory amounts = new uint[](1);
        amounts[0] = 50; 
        
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