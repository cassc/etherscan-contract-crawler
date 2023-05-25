// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: FVCKRENDER
/// @title: FVCK_AVATAR//
/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                .::^^~~!!!!!!^:.                                            //
//                                         .^!?YPGB##&&&&&@@@@@@&#B5J7^.                                      //
//                                     :!JPB&@@&#BPYJ?7!!!!7?YPGB&@@@@&BY~.                                   //
//                                  :?P#@@&#GY?!^:.           ..^7P&@@@@@@B7.                                 //
//                                !5&@@@B5J7~:.       .::^^^^:^^75#@@@@@@@@@G7.                               //
//                              [email protected]@@@#GYJ7!~^^:::::^~7?YPGGPPGGB&@@@@@@@#GGB#P^                              //
//                            :J#@@@@&#BGGP569YJ????JYPG#&@@@@@&B#&@@@@@&P7~!YBG^                             //
//                           ^P&@@@@@@@@@@&#&#B#BGBBBB#@@@@@@#G5YYP#@@@@&5~  :J#G^                            //
//                          ^G&@@@@@@@@@@&@@@@@@@@@@@@@@@@@@&G5J??YG&@@@@B7.  .J#P:                           //
//                         .5B&@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@GY7~!JP&@@@@&P7:   ?#5.                          //
//                         !PJP&@@@@@@@@@@@@@@@@@@@@@@@@@@@&5~:^[email protected]@@#B&&B57^.^P&J                          //
//                        .57^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@GJ!~^^!P~                         //
//                        .Y: [email protected]@@@@@@@@@@@@@@@@@&&&@@&@@BPJ?55G&@&BP?!B&&Y5GG#5J^?P                         //
//                        .J  ~P&@@@@@@@@@@@@@@@@#[email protected]@#G5##Y?!!!?P&[email protected]@&G?!~7?:                        //
//                        .Y. ^5&@@@@@@@@@@@@@@@[email protected]@&??#@B~      YGB&@G#G&@@P:     ~~                       //
//                        .5: .5&&#@@@@@@@@@@@@#[email protected]@&&[email protected]@@#:      ~&@&##BP##@P      .!                       //
//                         [email protected]@@@@@@@@@@@&#@@@@@@@@@@@?.    .5&&G5YJ77PB#!     ~^                       //
//                         Y#[email protected]#BBP#@@@@@@@@@@@@FVCKRENDER5&&PJ77Y#@@###B57.^YG#G?~7G?                        //
//                        .G&#@@&&#[email protected]@@@@@@@@@@@@##@@@@@@G?7?JP5JJYP#@@@Y:^~!7BGG!^?&5                        //
//                        .B#&&#G#@@@@@@@@@@@@@@&5Y#@@@@@@G!  .:::.:[email protected]~?G&@B5PJ~!P##:                       //
//                         PG#GB##&@@@@@@@@@@@@@@&[email protected]@@##@&Y!^:^^[email protected]&&##&@5GGP?JPGB:                       //
//                         7B&##&&&@#&@@@@@@@@@@@@@@@@@&B#@&BPJ77??!:7 G#BBB##?JJ7GP                          //
//                          ?#&&&#B##&[email protected]@@@@@@@@@@@@@@@@@&@@@@GJ7~..~JB###[email protected]#BG?B?                        //
//                           :JP&@@#GG#&@@@@@@@@@@@@@@@@@@@&&@@BY7!!YG&@@#GPP&55&@&GB:                        //
//                             .~Y#&&#&G#&&@@@@@@@@@@@@@@@@@##@@@#BGBG5P#&&&BP#&@@@&J                         //
//                                .^[email protected]@@@@@@@@@@@@@@@@@&@@BBP5PGB7#@&[email protected]&~                            //
//                                   ~5JJ5P&@@@@@@@@@@@@@@@@@@@&YPGP&@@[email protected]                         //
//                                    ~55PPP#@@@@[email protected]@@@@@@@@@@@@#[email protected]@@#P5BPGG55PP#@&!                          //
//                                     ~55GGYJP&@@@@&&&&&@&@@@@&@&@@@&BY7!J#@Y:7P&Y                           //
//                                      [email protected]&P?7JG#&BGB#&&##G#&@@&@&&&#P?^!G#B77BG:                           //
//                                      [email protected]@@@#BB#@@@@&@@@@&#BBB#&&&#&BPGP?Y#G5#!                            //
//                                      !7:&@@@##@@@@@@@@@@@@@&&&#&&@&G7~Y7&B~                                //
//                                      [email protected]@@#P#@@@&&&@@@@@@@&##&@@@&##BPP5J?^.                              //
//                                      Y:[email protected]@@&@@@@@&###@@@BPGB&@@@&#&&#J.                                    //
//                                     ^?!#@@@#&@@@@@@@@@@@BYYGBP69PGGGY                                      //
//                                     [email protected]@@@#[email protected]@@@@@@&&&&@@B7^~G#[email protected]!                                      //
//                                    ~B&@@@@@@#@@@@@@&GPGB&#[email protected]@GG^                                      //
//                                   :[email protected]@@@@@@@@@@@@@#5JY5B#5^:[email protected]?BGP:                                      //
//                                  ^G&BPGB&@@@@@@@@#J^^7YBB?^7P#&7.^?P~                                      //
//                                .?GG?!!?YG#@@@@@@@B7^~?5G5?75#@&Y. ^5?                                      //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * FVCK_AVATAR//
 */
contract FVCK_AVATAR is ReentrancyGuard, AdminControl, ERC721, IERC1155Receiver {
    using Strings for uint256;

    event Activate();
    event Deactivate();
    event Unveil(uint256 collectibleId, address tokenAddress, uint256 tokenId);

    // Immutable constructor arguments
    address private immutable _essenceAddress;

    // Contract state
    bool public isRedemptionEnabled;	
    string private _tokenURIPrefix;
    uint256 private _mintCount;

    // Royalty
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor(address essenceAddress) ERC721("FVCK_AVATAR//", "FVCK_AVATAR//") {
      _essenceAddress = essenceAddress;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external override nonReentrant returns(bytes4) {
        _onERC1155Received(from, id, value);
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) external override nonReentrant returns(bytes4) {
        require(ids.length == 1 && ids.length == values.length, "Invalid input");
        _onERC1155Received(from, ids[0], values[0]);
        return this.onERC1155BatchReceived.selector;
    }

    // /**
    //  * @dev See {IERC165-supportsInterface}.
    //  */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || ERC721.supportsInterface(interfaceId) 
            || AdminControl.supportsInterface(interfaceId)
            || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE
            || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 
            || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    /**
     * @dev Enable token redemption period
     */
    function enableRedemption() external adminRequired {
        isRedemptionEnabled = true;
        emit Activate();
    }

    /**
     * @dev Disable token redemption period
     */
    function disableRedemption() external adminRequired {
        isRedemptionEnabled = false;
        emit Deactivate();
    }

    /**
    *  @dev Set the tokenURI prefix
    */
    function setTokenURIPrefix(string calldata uri) external adminRequired {
        _tokenURIPrefix = uri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString()));
    }

    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }

    /**
     * @dev Mint an avatar
     */
    function _mintAvatar(address to) internal returns(uint256) {
        _mintCount++;
        _mint(to, _mintCount);
        emit Unveil(_mintCount, address(this), _mintCount);
        return 0;
    }


    function _onERC1155Received(address from, uint256 id, uint256 value) private {
        require(isRedemptionEnabled || isAdmin(from), "Redemption inactive");
        require(msg.sender == _essenceAddress && id == 1, "Invalid NFT");

        // Burn it
        try IEssence(msg.sender).burn(address(this), uint16(value)) {
        } catch (bytes memory) {
            revert("Burn failure");
        }

        for (uint i = 0; i < value; i++) {
            _mintAvatar(from);
        }
    }
}

interface IEssence {
    function burn(address from, uint16 amount) external;
}