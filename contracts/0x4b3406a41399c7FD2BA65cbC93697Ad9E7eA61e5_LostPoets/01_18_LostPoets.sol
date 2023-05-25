// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: Pak
/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ILostPoets.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//  `7MMF'        .g8""8q.    .M"""bgd MMP""MM""YMM `7MM"""Mq.   .g8""8q. `7MM"""YMM MMP""MM""YMM  .M"""bgd  //
//    MM        .dP'    `YM. ,MI    "Y P'   MM   `7   MM   `MM..dP'    `YM. MM    `7 P'   MM   `7 ,MI    "Y  //
//    MM        dM'      `MM `MMb.          MM        MM   ,M9 dM'      `MM MM   d        MM      `MMb.      //
//    MM        MM        MM   `YMMNq.      MM        MMmmdM9  MM        MM MMmmMM        MM        `YMMNq.  //
//    MM      , MM.      ,MP .     `MM      MM        MM       MM.      ,MP MM   Y  ,     MM      .     `MM  //
//    MM     ,M `Mb.    ,dP' Mb     dM      MM        MM       `Mb.    ,dP' MM     ,M     MM      Mb     dM  //
//  .JMMmmmmMMM   `"bmmd"'   P"Ybmmd"     .JMML.    .JMML.       `"bmmd"' .JMMmmmmMMM   .JMML.    P"Ybmmd"   //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract LostPoets is ReentrancyGuard, AdminControl, ERC721, ILostPoets {

    using Strings for uint256;

    address private _erc1155BurnAddress;
    address private _erc721BurnAddress;

    uint256 private _redemptionCount = 1024;
    bool public redemptionEnabled;
    uint256 public redemptionEnd;

    /**
     * Word configuration
     */
    bool public wordsLocked;
    mapping (uint256 => bool) public finalized;
    mapping (uint256 => uint256) private _addWordsLastBlock;
    mapping (uint256 => uint8) private _addWordsLastCount;
    mapping (uint256 => uint8) _wordCount;
    uint256 private _wordNonce;

    string private _prefixURI;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor(address lostPoetPagesAddress) ERC721("Lost Poets", "POETS") {
        _erc1155BurnAddress = lostPoetPagesAddress;
        wordsLocked = true;
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
     * @dev See {ILostPoets-mintOrigins}.
     */
    function mintOrigins(address[] calldata recipients, uint256[] calldata tokenIds) external override adminRequired {
        require(recipients.length == tokenIds.length, "Invalid input");
        for (uint i = 0; i < recipients.length; i++) {
            require(tokenIds[i] <= 1024, "Invalid token id");
            _mint(recipients[i], tokenIds[i]);
        }
    }

    /**
     * @dev Mint a token
     */
    function _mintPoet(address recipient) private {
        _redemptionCount++;
        _mint(recipient, _redemptionCount);
        emit Unveil(_redemptionCount);
    }

    /**
     * @dev See {ILostPoets-enableRedemption}.
     */
    function enableRedemption(uint256 end) external override adminRequired {
        redemptionEnabled = true;
        redemptionEnd = end;
        emit Activate();
    }

    /**
     * @dev See {ILostPoets-disableRedemption}.
     */
    function disableRedemption() external override adminRequired {
        redemptionEnabled = false;
        redemptionEnd = 0;
        emit Deactivate();
    }

    /**
     * @dev See {ILostPoets-lockWords}.
     */
    function lockWords(bool locked) external override adminRequired {
        wordsLocked = locked;
        emit WordsLocked(locked);
    }

    /**
     * @dev See {ILostPoets-setPrefixURI}.
     */
    function setPrefixURI(string calldata uri) external override adminRequired {
        _prefixURI = uri;
    }
    
    /**
     * @dev See {ILostPoets-finalizePoets}.
     */
    function finalizePoets(bool value, uint256[] memory tokenIds) external override adminRequired {
        for (uint i = 0; i < tokenIds.length; i++) {
            finalized[tokenIds[i]] = value;
        }
    }
    /**
     * @dev Add words to a poet
     */
    function _addWords(uint256 tokenId) private {
        _wordNonce++;
        uint8 count = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _wordNonce, tokenId)))%3)+2;

        // Track the added word count of the current block
        if (_addWordsLastBlock[tokenId] == block.number) {
           _addWordsLastCount[tokenId] += count;
        } else {
           _addWordsLastBlock[tokenId] = block.number;
           _addWordsLastCount[tokenId] = count;
        }
        _wordCount[tokenId] += count;

        emit AddWords(tokenId, count);
    }

    /**
     * @dev Shuffle words of a poet
     */
    function _shuffleWords(uint256 tokenId) private {
        emit ShuffleWords(tokenId);
    }

    /**
     * @dev See {ILostPoets-getWordCount}.
     */
    function getWordCount(uint256 tokenId) external view override returns(uint8) {
        require(_exists(tokenId), "ERC721: word count query for nonexistent token");
        if (_addWordsLastBlock[tokenId] == block.number) {
            return _wordCount[tokenId]-_addWordsLastCount[tokenId];
        }
        return _wordCount[tokenId];
    }

    /**
     * @dev See {ILostPoets-recoverERC721}.
     */
    function recoverERC721(address tokenAddress, uint256 tokenId, address destination) external override adminRequired {
        IERC721(tokenAddress).transferFrom(address(this), destination, tokenId);
    }

    /**
     * @dev See {ILostPoets-updateERC1155BurnAddress}.
     */
    function updateERC1155BurnAddress(address erc1155BurnAddress) external override adminRequired {
        _erc1155BurnAddress = erc1155BurnAddress;
    }

    /**
     * @dev See {ILostPoets-updateERC721BurnAddress}.
     */
    function updateERC721BurnAddress(address erc721BurnAddress) external override adminRequired {
        _erc721BurnAddress = erc721BurnAddress;
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
        require(msg.sender == _erc1155BurnAddress && id == 1, "Invalid NFT");
        
        uint256 action;
        uint256 tokenId;
        if (data.length == 32) {
            (action) = abi.decode(data, (uint256));
        } else if (data.length == 64) {
            (action, tokenId) = abi.decode(data, (uint256, uint256));
        } else {
            revert("Invalid data");
        }

        if (action == 0) {
            require(redemptionEnabled && block.timestamp <= redemptionEnd, "Redemption inactive");
        } else if (action == 1 || action == 2) {
            require(value == 1, "Invalid data");
            require(!wordsLocked, "Modifying words disabled");
            require(!finalized[tokenId], "Cannot modify words of finalized poet");
            require(tokenId > 1024, "Cannot modify words");
            require(from == ownerOf(tokenId), "Must be token owner");
        } else {
            revert("Invalid data");
        }

        // Burn it
        try IERC1155(msg.sender).safeTransferFrom(address(this), address(0xdEaD), id, value, data) {
        } catch (bytes memory) {
            revert("Burn failure");
        }

        if (action == 0) {
            for (uint i = 0; i < value; i++) {
                _mintPoet(from);
            }
        } else if (action == 1) {
            _addWords(tokenId);
        } else if (action == 2) {
            _shuffleWords(tokenId);
        }
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address from,
        uint256 receivedTokenId,
        bytes calldata data
    ) external override nonReentrant returns (bytes4) {
        require(msg.sender == _erc721BurnAddress, "Invalid NFT");
        
        if (data.length != 64) revert("Invalid data");
        (uint256 action, uint256 tokenId) = abi.decode(data, (uint256, uint256));
        if (action != 1 && action != 2) revert("Invalid data");

        require(!wordsLocked, "Modifying words disabled");
        require(!finalized[tokenId], "Cannot modify words of finalized poet");
        require(tokenId > 1024, "Cannot modify words");
        require(from == ownerOf(tokenId), "Must be token owner");

        // Burn it
        try IERC721(msg.sender).transferFrom(address(this), address(0xdEaD), receivedTokenId) {
        } catch (bytes memory) {
            revert("Burn failure");
        }

        if (action == 1) {
            _addWords(tokenId);
        } else if (action == 2) {
            _shuffleWords(tokenId);
        }
        return this.onERC721Received.selector;
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return string(abi.encodePacked(_prefixURI, tokenId.toString()));
    }

    /**
     * @dev See {ILostPoets-updateRoyalties}.
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