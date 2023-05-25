// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Timpers
/// @title: Chimpers Generative
/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "./ERC721CollectionBase.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                 ...                                              //
//                                                                'ON0,                                             //
//                                                      .::c'  .;cd0X0dc:.                                          //
//                                                     .oXNWd. :XWXOkOXMN:                                          //
//                                                   :OOO000OOOO00OkkOXMN:                                          //
//                                             ';;;;:xXX0Okk0XXKkkkkkkKXKd;;;;;.                                    //
//                                            .kWWWWWKkkkkkkkkkkkkkkkkkkOXWWWWNo                                    //
//                      .oxxxxxxxxxxxxxx;  .oxkO00000OkkkkkkkkkkkkkkkkkkkO00000Oxx:                                 //
//                   ..'lKNNNNNNNNNNNNNNx;'lKNXOkkkkkkkkxdoooooooodxkkkkkkkkxddOXNk;'''''''.                        //
//                   ;KNXOkkkkkkkkkkkkkk0NNKOkkkkkkkkkkxl,,'',,''':dkkkkkkkxc,,lkk0NNNNNNNNK;                       //
//                'lok0K0kkxlccccccccokkOKK0kkkkkkkkxoc:;''''''''',:ccdkxocc;'';:ckNMWKKKKK0kdl'                    //
//              ..lXWKkkxxxd;''''''''cdxxkkkkkkkkkxxd:''...........'',lxd:'''.....l0XKOOOkkOXWXl..                  //
//            .l000OOOkkd:;,''''''''',;;lxkkkkkkkxc;;,''.         ..'',;,,''.     ...cKNX0kkOOO00O:                 //
//            .xMMXkkdol:,'''''''''''''';lloxkkkkx:''...    .;::::,....''...   .;::::codoolodkk0XKxc:,              //
//            .xMMXkkl,'''''''''''''''''''':dkkkkx:'..      cNMWWNx.  .'..     cNMWWNx.  .',lxxkkkKWMk.             //
//            .xMMXkkl,'''''''''''''''''''':dkkkkx:'..      cNMO:'.   .'..     cNMO;'.   .'';;:okkKWMk.             //
//            .xMMXkkl,'''''''''''''''''''':xkkkkx:'..      cNM0:,.   .'..     cNMO:,.   .'''''lkkKWMk.             //
//            .xMMXkkl,'''''''''''''''''''':xkkkkx:'..      :XWWWWx.  .'..     cNWWWWx.  .'''''lkkKWMk.             //
//            .xMMXkkxolc,'''''''''''''';lodxkkkkx:''...    .;;;;;,....''...   .;;;;;cdxo:'''',lxkKWMk.             //
//            .lOOO00Okkd:;;,'''''''',;;lxkkkkkkkx:'''''.         ..''''''''.        ;KMXl'',;:okkKWMk.             //
//               .lNWXOkkxxd:''''''''cdxxkkkkkkkkx:''''''..........''''''''''........lXMXl',lxxxkkKWMk.             //
//                .:cxKX0kkxolllllllldkkkkkkkkkkkx:'''''''''''';oddddo;',cdddddc'''''lXMNxlldkk0KKklc,              //
//                   ;0NKOOOOOOOOOOOOkkkkkkkkkkxxd:''''''''''''cOKKKKOc',d0KKK0o,''''lKNX0OOOOOKXXc                 //
//                    ..cKNNNNNNNNNNNKkkkkkkkkxc;;,'''''''''''',:::::;,'';:::::;''''',::l0NNNNXo'..                 //
//                      .ldddddddxKWWKkkkkkkkkd:''.....................................';OMW0xo'                    //
//                                oNWKOkkkkkkkd:'..                                   .';OMX:                       //
//                                .,;dXXKkkkkkd:'.                                    .':0MX:                       //
//                                   lNMXOkkkkd:'.                                    .':0MX:                       //
//                                   cNMXOkkkkd:'.                                    .':0MX:                       //
//                                   .;:dKXKOkd:''...                              ....':0MX:                       //
//                                      ,k0000ko::,'..                            ..',::lx0k,                       //
//                                        .:KWWNNKl''..............................''lKN0;.                         //
//                                         .coooooddddddddddddddddddddddddddddddddddddooc.                          //
//                                               .dNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNd.                             //
//                                                .''''''''''''''''''''''''''''''''''.                              //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract Chimpers is ERC721CollectionBase, ERC721, AdminControl {

    constructor(address signingAddress) ERC721("Chimpers", "CHIMP") {
        _initialize(
          // Total supply
          5555,
          // Purchase price (0.07 ETH)
          70000000000000000,
          // Purchase limit (0 for no limit)
          0,
          // Transaction limit (0 for no limit)
          0,
          // Presale purchase price (0.07 ETH)
          70000000000000000,
          // Presale purchase limit (0 for no limit)
          0,
          signingAddress,
          // Use dynamic presale purchase limit
          true);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CollectionBase, ERC721, AdminControl) returns (bool) {
        return ERC721CollectionBase.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Collection-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount) external override adminRequired {
        _withdraw(recipient, amount);
    }

    /**
     * @dev See {IERC721Collection-setTransferLocked}.
     */
    function setTransferLocked(bool locked) external override adminRequired {
        _setTransferLocked(locked);
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(uint16 amount) external override adminRequired {
        _premint(amount, owner());
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(address[] calldata addresses) external override adminRequired {
        _premint(addresses);
    }

    /**
     * @dev See {IERC721Collection-activate}.
     */
    function activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_, uint256 claimStartTime_, uint256 claimEndTime_) external override adminRequired {
        _activate(startTime_, duration, presaleInterval_, claimStartTime_, claimEndTime_);
    }

    /**
     * @dev See {IERC721Collection-deactivate}.
     */
    function deactivate() external override adminRequired {
        _deactivate();
    }

    /**
     *  @dev See {IERC721Collection-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _prefixURI;
    }
    
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override (ERC721, ERC721CollectionBase) returns (uint256) {
        return ERC721.balanceOf(owner);
    }

    /**
     * @dev mint implementation
     */
    function _mint(address to, uint256 tokenId) internal override (ERC721, ERC721CollectionBase) {
        ERC721._mint(to, tokenId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTranfser}.
     */
    function _beforeTokenTransfer(address from, address, uint256) internal virtual override {
        _validateTokenTransferability(from);
    }
    
    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
      _updateRoyalties(recipient, bps);
    }

}