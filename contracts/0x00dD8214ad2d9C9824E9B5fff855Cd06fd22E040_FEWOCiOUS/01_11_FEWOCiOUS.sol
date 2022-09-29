// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz
/// @artist: FEWOCiOUS

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                           @@@@*@@@                                          //
//                                                     @@ @@           ,@@                                   @@@   @@                                          //
//                                                   @@      @@         @@ @                                  %@@@@    @@@@@@@@@                               //
//                   @@@@@@@@@@@@&/          @@    @@           @        @@  @@             *@                    @   @@@@@@@@@@@@@.     .&@@@@@@              //
//          @@@                           @@@    @@       #       @@      @@   @@       @@@@  @@           @@@@ *@ @   @@@                @@@@                 //
//          @@                         @@@@#   @@       @@@@@@      /@     @@   @@@ @@@@@@     %@*   @@@@@@@@  @@  @@   @@@           @@@@                     //
//           @%     @/@@@@@@@@@      @@@@@   @@@      @@    @@@@       @@   @@    @@@@@@         @@@@@@@@ #@   @    @   @@@@      &@@@@@@@@@@@@@@@@@@@         //
//            @     @@    @@       @@@@@   @@@@@@     @@      @@@@       @@  @      @,             %@@   @     @@    @   @@@@               @@@@@@@            //
//            @@    #@ @@        @@@@@       @@@@@@     @#  &@@          #@@  @          @@@            @      @@@    @%  @@@          @@@@@@@@                //
//             @     @*            /@@@         @@@@@     @@@         @@@&    @@       @@@@@@@        @@        @@     @@  @@@     *@@@@@@@&                   //
//             @*                       @@@      @@@@@@            &@@@        @@   @@@    @@@@      @@         @@@    @@  @@@@        @@@@                    //
//             @@                           @@@    @@@@@@       [email protected]@@           @@@@@@       @@@@@  @@,          @@@@@@@     @@@            @@@@@               //
//              @@     @@@@@@@@@@@@@         (@@     @@@@@@   @@@               @@@           @@@@@@             @@@@        @@@@@@@@@@@@@@@@@@@@@@@           //
//              @@     @      @        ,@@@@@           @@@@@@                   @              @@@              @@          @@@@@@@@@@@@@*                    //
//               @@     @ @       @@@@@@                                                                                                                       //
//               @@          @@@@@@@                                                                                                                           //
//                @@     @@@@@@                                           @@@@@@@@@@    @@                                                                     //
//                @@@@@@@@                                      @@                     @@@@                                                                    //
//                 @@                                           @                     @@@@@                                                                    //
//                                                             @                     @@@@@@                                                                    //
//                                                            %@                    @@@@@@                                                                     //
//                                                            @                     @@@@@@                                                                     //
//                                                           @@                    @@@@@@                                                                      //
//                                                           @                    @@@@@@@                                                                      //
//                                                          @@                       &@@@@@@@@@@@@@@@@@@                                                       //
//                                                          @                                   @@@@@@@@@@@                                                    //
//                                                         %@                                @@@@@@@@@@@@@                                                     //
//                                                         @/          %@@@@@@,           #@@@@@@@@@@@@                                                        //
//                                                         @ @@@@@@@@@@@@@@@@           @@@@@@@@@@@@                                                           //
//                                                                        @@         @@@@@@@@@@@@                                                              //
//                                                                      %@%        @@@@@@@@@@@                                                                 //
//                                                                     @@       ,@@@@@@@@@@                                                                    //
//                                                                    @@      @@@@@@@@@@                                                                       //
//                                                                   @@     @@@@@@@@@                                                                          //
//                                                                  @@    @@@@@@@@                                                                             //
//                                                                 @@   @@@@@@@                                                                                //
//                                                                @@  @@@@@                                                                                    //
//                                                               @@@@@@                                                                                        //
//                                                              @@@                                                                   @@@@@@@@@                //
//                   (@@@@                                                                             @@@@@@@@@@@                   @@@@@  @@@@               //
//          @@@@@@@@@@@@@@@@                @@               *@                               @@@@    @@@@     @@@@                 @@@@@                      //
//          @@@@@@@@@@@           &@@@      @@       %      @@@@                @@@@@@@@@    @@@@@   @@@@        @@@    @@           @@@@@@@@@@@@@             //
//          @@@@@            @@@@@@@        @@   #@@@@@#   @@@@   @@@@@@@     @@@@@@@            *   @@@@@       @@@  @@@@@      @@@   @@@@@@@@@@@@@@          //
//          @@@@@@@@@@@@@@   @@@           @@@@@@@@@@@@@  @@@@  @@@@@(%@@@@@  @@@@@             @@@    @@@@@@@@@@@@   @@@@      @@@@             @@@@@         //
//          @@@@@@@@@@@@@@@  @@@   @@@@@   @@@@@     @@@@@@@@  @@@       @@@ /@@@@@       /@@@   @@@.                @@@@@     @@@@@@  @@@@      @@@@@         //
//          @@@@@            [email protected]@@@@@                  @@@@@@   @@@@@  @@@@@   @@@@@@@@@@@@@@@     @@@                 @@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@         //
//          @@@@@             @@@    @@@@@             @@@@      @@@@@@@.      ,@@@@@@@@@@@        @@@                 @@@@@@@@@[email protected]@@@    @@@@@@@@@@@           //
//         @@@@@#             @@@@@@@@                  @@@                                                                     [email protected]@@                           //
//         @@@@@              [email protected]@*                                                                                                                             //
//          @@@                                                                                                                                                //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract FEWOCiOUS is AdminControl, ICreatorExtensionTokenURI {

    string private _tokenURI;
    address private constant _creator = 0xFE7d465d8c420Ee4aeAd45D54D32defc4e3CfF2c;
    bool private minted;

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function mint() public adminRequired {
        require(!minted, 'Already minted');
        minted = true;
        
        IERC721CreatorCore(_creator).mintExtension(msg.sender);
    }

    function setTokenURI(string memory newTokenURI) public adminRequired {
        _tokenURI = newTokenURI;
    }

    function tokenURI(address creator, uint256) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return _tokenURI;
    }
}