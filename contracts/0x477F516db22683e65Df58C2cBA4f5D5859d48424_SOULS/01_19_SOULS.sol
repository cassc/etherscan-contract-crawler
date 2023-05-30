// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/// @artist: SiA & DOR
/// @title: SOULS
/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "./ERC721CollectionBase.sol";

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXXXKKXXXXNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0kxdlc:;;,'''....''',;;:cldxk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxoc;'...                        ...';cox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xl;'..                                      ..':okKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkl;..                                                ..;oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'.                                                        .,lkXWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMWXkc'..                                                             .,o0NMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMW0o,.                                                                    .:kNMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMNOc....                                                                      .;xXMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMNOc.. .                  ......                    ........                      .;kNMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMW0l...                 ..,:cllllc:,..             ..;cloooooc;'.                     .c0WMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWXd,..                 .':oddddddddddo:..          .;oddddddddddoc.                     .'dXWMMMMMMMMMMMMM
// MMMMMMMMMMMMMW0:..                  .;oddddddddddddddo;.        .cddddddddddddddl.                      .cKWWMMMMMMMMMMM
// MMMMMMMMMMWWNx,...                 .:dddddddddddddddddo;.      .;dddddddddddddddd;.                      .;OWWMMMMMMMMMM
// MMMMMMMMMWWXd....                  ,oddddddddddddddddddo'      .cddddddddddddddddc.                       .,kWWMMMMMMMMM
// MMMMMMMMWWXl...                   .:dddddddddddddddddddd:.     'lddddddddddddddddl.                        .,kWWWMMMMMMM
// MMMMMMMWWXl....                   .lddddddddddddddddddddl.     ,oddddddddddddddddl.                         .,OWWWMMMMMM
// MMMMMMWWXo....                    .lddddddddddddddddddddo,     ;dddddddddddddddddl.                          .:0WWWMMMMM
// MMMMMWWNx'....                    'ldddddddddddddddddddddl'.  .cdddddddddddddddddl.                           .lXWWMMMMM
// MMMMWWWO;......                   ,oddddddddddddddddddddddoc::lddddddddddddddddddc.                            'kWWWMMMM
// MMMWWWXl.......                  .:ddddddddddddddddddddddddddddddddddddddddddddddl.                            .cKWWWMMM
// MMMWWNk'.......                 .,oddddddddddddddddddddddddddddddddddddddddddddddo;.                            'kNWWWMM
// MMWWWXc........               ..:odddddddddddddddddddddddddddddddddddddddddddddddddl:'.                         .lXWWWMM
// MMWWWO,........              .:oddddddddddddddddooddddddddddddddddddddddddddddddddddddl:.                       .;0WWWWM
// MWWWNd..........           .,ldddddddddddddddolllllloodddddddddddddoooooodddddddddddddddo:.                      'kNWWWW
// WWWWXl...........         .:oddddddddddddddolllllllllllodddddddddollllllloodddddddddddddddo;.                   ..xNWWWW
// WWWNKc..........         .:ddddddddddddddddollllllllllloodddddddollcllllllloddddddddddddddddc.                  ..dNWWWW
// WWWNKc...........       .;dddddddddddddddddollllllllllloodddddddollclllllllodddddddddddddddddc.                  .oXNWWW
// WWNNKc............     .'odddddddddddddddddolllllllllllodddddddddolllllllloddddddddddddddddddd:.                ..dXNWWW
// WWNNKc............     .:dddddddddddddddddddoollllllloodddddddddddooolloooddddddddddddddddddddo'                .'xNNWWW
// WWNNXo...............  .lddddddddddddddddddddddoooooddddddddddddddddddddddddddddddddddddddddddd:.              ..,kNNWWW
// WWNNXd'............... 'ldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd:.              ..:0NNWWW
// WWNNNO;................'lddddddddddddddddddddddddooolooooddddddoooooooodddddddddddddddddddddddd:.             ...oXNNWWW
// WWNNNKl.................cdddddddddddddddddddddddollllllllloooollllllllllodddddddddddddddddddddd;             ...,kXNNWWW
// WWWNNXk,................;ddddddddddddddddddddddollllclllllllllllllllllllodddddddddddddddddddddl.             ...lKNNNWWW
// WWWNNXKl.................cddddddddddddddddddddddolcllllllllllllllllllllloddddddddddddddddddddo;.            ...;kXNNNWWW
// WWWNNNXO:................'lddddddddddddddddddddddollllllllllllllllllllodddddddddddddddddddddo;.            ....oKXNNWWWW
// WWWWNNXKx,................'ldddddddddddddddddddddddoollllllllllllloooddddddddddddddddddddddo;.            ....c0XXNNWWWM
// MWWWNNNXKo'.................:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddc'             ....:OXXNNWWWWM
// MWWWWNNXX0l'.................,lddddddddddddddddddddddddddddddddddddddddddddddddddddddddoc'.            .....;kXXNNNWWWMM
// MMWWWNNNXX0l'..................,coddddddddddddddddddddddddddddddddddddddddddddddddddol;..             .....;kKXXNNWWWWMM
// MMWWWWNNNXX0o'....................,:lodddxdddddddddddddddddddddddddddddddddddddolc:,..              ......;kKXXNNWWWWMMM
// MMMWWWWNNXXX0o,.......................,;:clllooooooooooooooooooooolllcc:::;;,'...                 .......:kKXXNNNWWWMMMM
// MMMMWWWWNNXXXKx;......................................................                          .......'lOKXXNNNWWWMMMMM
// MMMMMWWWWNNXXXKkc'.............................                                               ........;d0KXXNNNWWWWMMMMM
// MMMMMMWWWWNNXXXK0d;................................                                        .........'lOKKXXNNNWWWWMMMMMM
// MMMMMMMWWWWNNNXXKKOl,..................................                                ............:x0KXXXNNNWWWMMMMMMMM
// MMMMMMMMWWWWNNNXXKK0kc,.....................................                       ..............;oOKKXXNNNWWWWWMMMMMMMM
// MMMMMMMMMWWWWNNNXXXKK0xc,......................................................................;oOKKKXXNNNWWWWMMMMMMMMMM
// MMMMMMMMMMMWWWWNNNXXXKK0kl;.................................................................':dOKKKXXNNNWWWWWMMMMMMMMMMM
// MMMMMMMMMMMMWWWWNNNNXXXKK0Oo:'............................................................,lx0KKKXXXNNNWWWWMMMMMMMMMMMMM
// MMMMMMMMMMMMMWWWWWNNNXXXXKKK0xl;'......................................................,cdO0KKKXXXNNNWWWWWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWWWWNNNNXXXKKK0Oxo:,'..............................................';cdk0KKKKXXXNNNWWWWWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWWWWWNNNNXXXKKKK00kdl:,'......................................',coxO0KKKKKXXXNNNWWWWWWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWWWWWNNNNXXXXKKKKK00kdoc:,'............................,;:loxO00KKKKXXXXNNNNWWWWWMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNXXXXKKKKKKK00Oxdolc:;;,,,'''''''',,,;:ccloxkO000KKKKKXXXXXNNNNWWWWWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNXXXXXKKKKKKK00000OOOkkkxxxxxkkkkOO00000KKKKKKKKXXXXNNNNNWWWWWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNNNNXXXXXXKKKKKKKKKKKKKK0KKKKKKKKKKKKKKKKXXXXXXXNNNNNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWNNNNNNXXXXXXXKKKKKKKKKKKKKKKKKKKKKXXXXXXXXXNNNNNWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
/**
 * ERC721 Collection Drop Contract
 */
contract SOULS is ERC721CollectionBase, ERC721, AdminControl {
    constructor(address signingAddress) ERC721("SOULS", "SOULS") {
        _initialize(
            10000,
            // 0.12345 eth
            123450000000000000,
            2,
            2,
            // 0.12345 eth
            123450000000000000,
            2,
            signingAddress,
            false
        );
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