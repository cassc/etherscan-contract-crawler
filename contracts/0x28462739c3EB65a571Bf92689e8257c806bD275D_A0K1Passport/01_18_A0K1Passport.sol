// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Steve Aoki
/// @title: A0K1 Passport
/// @author: manifold.xyz

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMMW0ddxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMM0'   lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;cKMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMNc    .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.  '0MMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMWx. ,c. ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.     '0MMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMK, .kXc  oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.        ,KMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMNl  cNMO' .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.          ;OWMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMO. '0WWNo. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.           'xNMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMX: .dNkoXK; .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.            .oXMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMWd. :XK;.oNk. ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:.             .:0WMWOkXMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMM0' .kNo  'ONl  lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.               ,kNMW0c.,0MMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMNc  lNO.   cX0' .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.                .dXMW0c.  '0MMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMWx. ,0X:    .xNd. ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:.                 .cKWW0l.    cXMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMK, .xNd. ..  ,KX:  oWMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:.                   ;OWWKl.   .;kXMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMNl  :X0'  lk'  lNO. .OMMMMMMMMMMMMMMMMMMMMMMMMWKd;.                    'xNWKo.   .cONNXWMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMk. .ONc  ,KWd. .kNl  :XMMMMMMMMMMMMMMMMMMMMWKd:.                     .lKWKo.   'o0NXx;:KMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMX:  oWKl;:kWMXo;:xWK, .dWMMMMMMMMMMMMMMMWKdl;.                      .:0WXd'   ,dXNOl.  '0MMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMO. .OMWNNNWMMMWNNNMWl  :NMMMMMMMMMMMMMMMK;                         ,xNXd'  .:kXKd;.   .cXMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMX:  lNKc',xWMXl',xW0, .xWMMMMMMMMMMMMMMM0'                       .oXXx'  .cOXOc.   .,o0NMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMO. .kNl  '0Wo  .ONl  cXMMMMMMMMMMMMMMMM0'                     .c0Xx,  'o00d,.  .,o0NMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMWo  :XK,  cx'  oNk. 'OMMMMMMMMMMMMMMMMM0'                    ,kKx,  ,x0kc.  .,oONMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMK; .dNx.  .  ;KX; .dWMMMMMMMMMMMMMMMMM0'                  .d0k;..:xOd,. .,oONMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMk. '0Xc    .kNo. ;XMMMMMMMMMMMMMMMMMM0'                .lOk;..lkxc. .,o0NMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMNl  cN0'   lNO' .kMMMMMMMMMMMMMMMMMMM0'               ;kx:.'oxo,..,lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMM0, .kNd. ,0Xc  lNMMMMMMMMMMMMMMMMMMM0'             'dx:.;odc..,lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMWx. ;KX:.dWx. ,KMMMMMMMMMMMMMMMMMMMM0'           .ld:,:ol,.,lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMX:  oNOxXK, .xWMMMMMMMMMMMMMMMMMMMM0'         .;oc;:c:',lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMO. 'OWWNo  cXMMMMMMMMMMMMMMMMMMMMM0'        'cc:::;:lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMWo  cXMO. '0MMMMMMMMMMMMMMMMMMMMMM0'      .;c:;:coONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMK; .xX: .dWMMMMMMMMMMMMMMMMMMMMMM0'    .,:::ldONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMWk. ':. ;XMMMMMMMMMMMMMMMMMMMMMMM0'   .;clx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMNl    .kMMMMMMMMMMMMMMMMMMMMMMMM0'..,ok0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMM0,   lNMMMMMMMMMMMMMMMMMMMMMMMMKdx0KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMMWKxxkXMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   //
//                                                                                                                              //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IA0K1Passport.sol";

contract A0K1Passport is ReentrancyGuard, AdminControl, ERC721, IA0K1Passport {

    using Strings for uint256;

    address private immutable _creditsAddress;

    // Supplementary metadata contract locations
    MetadataContract[] private _metadataContracts;

    // Pass count
    uint256 private _passCount;
    // Array of number of credits required per level (0 indexed, so 0 = level 1)
    uint16[] private _levelCredits;

    // Mapping of token to current level
    mapping(uint256 => uint8) private _tokenLevel;

    bool public redemptionEnabled;

    string private _prefixURI;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor(address creditsAddress) ERC721("A0K1", "A0K1") {
        _creditsAddress = creditsAddress;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId || ERC721.supportsInterface(interfaceId)
            || AdminControl.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981
            || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    /**
     * @dev Mint a pass
     */
    function _mintPass(address recipient, uint8 level) private {
        _passCount++;
        _mint(recipient, _passCount);
        _tokenLevel[_passCount] = level;
        emit TokenLevel(_passCount, level);
    }

    /**
     * @dev Upgrade a pass
     */
    function _upgradePass(uint256 tokenId, uint8 level) private {
        _tokenLevel[tokenId] = level;
        emit TokenLevel(tokenId, level);
    }

    /**
     * @dev See {IA0K1Passport-enableRedemption}.
     */
    function enableRedemption() external override adminRequired {
        redemptionEnabled = true;
        emit Activate();
    }

    /**
     * @dev See {IA0K1Passport-disableRedemption}.
     */
    function disableRedemption() external override adminRequired {
        redemptionEnabled = false;
        emit Deactivate();
    }

    /**
     * @dev See {IA0K1Passport-getLevelCredits}.
     */
    function getLevelCredits() external view override returns(uint16[] memory) {
        return _levelCredits;
    }

    /**
     * @dev See {IA0K1Passport-setLevels}.
     */
    function setLevelCredits(uint16[] memory levelCredits) external override adminRequired {
        _levelCredits = levelCredits;
    }

    /**
     * @dev See {IA0K1Passport-getMetadataContracts}.
     */
    function getMetadataContracts() external view override returns(MetadataContract[] memory) {
        return _metadataContracts;
    }

    /**
     * @dev See {IA0K1Passport-setMetadataContracts}.
     */
    function setMetadataContracts(MetadataContract[] calldata metadataContracts) external override adminRequired {
        // Shrink array if necessary
        if (metadataContracts.length < _metadataContracts.length) {
           for (uint i = 0; i < _metadataContracts.length-metadataContracts.length; i++) {
               _metadataContracts.pop();
           }
        }

        for (uint i = 0; i < metadataContracts.length; i++) {
            MetadataContract memory metadataContract = metadataContracts[i];
            if (i < _metadataContracts.length) {
                MetadataContract storage _metadataContract = _metadataContracts[i];
                _metadataContract.category = metadataContract.category;
                _metadataContract.chainId = metadataContract.chainId;
                _metadataContract.contractAddress = metadataContract.contractAddress;
            } else {
                _metadataContracts.push(metadataContract);
            }
        }
    }

    /**
     * @dev See {IA0K1Passport-recoverERC721}.
     */
    function recoverERC721(address tokenAddress, uint256 tokenId, address destination) external override adminRequired {
        IERC721(tokenAddress).transferFrom(address(this), destination, tokenId);
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override nonReentrant returns(bytes4) {

        _onERC1155Received(from, id, value, data);
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
        bytes calldata data
    ) external override nonReentrant returns(bytes4) {
        require(ids.length == 1 && ids.length == values.length, "Invalid input");
        _onERC1155Received(from, ids[0], values[0], data);
        return this.onERC1155BatchReceived.selector;
    }

    function _onERC1155Received(address from, uint256 id, uint256 value, bytes calldata data) private {
        require(redemptionEnabled, "Redemption inactive");
        require(msg.sender == _creditsAddress && id == 1, "Invalid NFT");

        uint8 action;
        uint8 level;
        uint256 tokenId;
        if (data.length == 64) {
            (action, level) = abi.decode(data, (uint8, uint8));
            require(level > 0 && _levelCredits.length >= level, "Invalid request");
            uint8 levelIndex = level-1;
            require(_levelCredits[levelIndex] > 0 && _levelCredits[levelIndex] == value, "Invalid request");
        } else if (data.length == 96) {
            (action, level, tokenId) = abi.decode(data, (uint8, uint8, uint256));
            require(ownerOf(tokenId) == from, "Must be owner of token");
            uint8 currentLevel = _tokenLevel[tokenId];
            require(level > 0 && _levelCredits.length >= level && currentLevel > 0 && level > currentLevel, "Invalid request");
            uint16 creditsRequired = _levelCredits[level - 1] - _levelCredits[currentLevel - 1];
            require(creditsRequired > 0 && creditsRequired == value, "Invalid request");
        } else {
            revert("Invalid data");
        }

        // Burn it
        try IA0K1Credits(msg.sender).burn(address(this), uint16(value)) {
        } catch (bytes memory) {
            revert("Burn failure");
        }

        if (action == 0) {
            _mintPass(from, level);
        } else if (action == 1) {
            _upgradePass(tokenId, level);
        }
    }

    /**
     * @dev See {IA0K1Passport-mergePasses}.
     */
    function mergePasses(uint256 tokenId, uint8 newLevel, uint256[] calldata mergeTokenIds) external override {
        require(msg.sender == ownerOf(tokenId), "Must be token owner");
        require(newLevel <= _levelCredits.length, "Invalid level");
        require(_tokenLevel[tokenId]+1 == newLevel, "Can only upgrade one level at a time");
        uint16 mergeCredits = 0;
        uint8 newLevelIndex = newLevel-1;
        for (uint i = 0; i < mergeTokenIds.length; i++) {
            uint256 mergeTokenId = mergeTokenIds[i];
            require(mergeTokenId != tokenId, "Cannot have duplicate tokens");
            for (uint j = 0; j < mergeTokenIds.length; j++) {
                require(i == j || mergeTokenId != mergeTokenIds[j], "Cannot have duplicate tokens");
            }
            require(msg.sender == ownerOf(mergeTokenId), "Must be token owner");
            mergeCredits += _levelCredits[_tokenLevel[mergeTokenId]-1];
        }
        require(_levelCredits[newLevelIndex]-_levelCredits[newLevelIndex-1] == mergeCredits, "Invalid merge request");

        for (uint i = 0; i < mergeTokenIds.length; i++) {
            _burn(mergeTokenIds[i]);
        }

        _upgradePass(tokenId, _tokenLevel[tokenId]+1);
    }

    /**
     * @dev See {IA0K1Passport-tokenLevel}.
     */
    function tokenLevel(uint256 tokenId) public view override returns(uint8) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return _tokenLevel[tokenId];
    }

    /**
     * @dev See {IA0K1Passport-setPrefixURI}.
     */
    function setPrefixURI(string calldata uri) external override adminRequired {
        _prefixURI = uri;
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return string(abi.encodePacked(_prefixURI, tokenId.toString()));
    }

    /**
     * @dev See {IA0K1Passport-updateRoyalties}.
     */
    function updateRoyalties(address payable recipient, uint256 bps) external override adminRequired {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256) external view override returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view override returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view override returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view override returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }

}