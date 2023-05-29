// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

///  ##     ###### ######        ###### ##  ## ###### #####  ######        #####  ######        ##     ######  ####  ##  ## ######
///  ##     ##       ##            ##   ##  ## ##     ##  ## ##            ##  ## ##            ##       ##   ##     ##  ##   ##
///  ##     ####     ##            ##   ###### ####   #####  ####          #####  ####          ##       ##   ## ### ######   ##
///  ##     ##       ##            ##   ##  ## ##     ##  ## ##            ##  ## ##            ##       ##   ##  ## ##  ##   ##
///  ###### ######   ##            ##   ##  ## ###### ##  ## ######        #####  ######        ###### ######  ####  ##  ##   ##

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { ERC721, IERC721, IERC165 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Burnable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";

import { strings } from "./strings.sol";
import { IERC4906 } from "./IERC4906.sol";

/// @title CodexLight
/// @author akuti.eth
/// @notice Lights by Codex Library (https://codexlibrary.org). CodexLight is minted by burning a matchbook.
contract CodexLight is IERC4906, ERC721, ERC721Burnable, IERC721Receiver, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using strings for *;

    struct AttributeCategory {
        // trait names within category
        string[] names;
        // commulative thresholds per trait within this category
        uint16[] thresholds;
    }

    struct UserData {
        uint8 reservedTokenId;
        bool hasMinted;
    }

    // constants
    address public constant MATCHBOOKS = 0xd1466d7A2e13A47677608F68093c5eA9fE910611;
    uint256 internal constant MAX_SUPPLY = 3001;
    uint256 internal constant NR_ATTRIBUTES = 6;
    uint256 internal constant NR_RESERVED = 10;

    // token and minting related data
    Counters.Counter internal _tokenIdCounter;
    Counters.Counter internal _reservedTokenIdCounter;
    Counters.Counter internal _burnCounter;
    mapping(address user => UserData data) internal _userData;

    // metadata
    string internal _imageBaseURI;
    string internal _externalBaseURI = "https://codexlibrary.org/light/";
    string internal _description = "May light show us the way.";
    string[NR_ATTRIBUTES] internal _attributeNames;
    uint64[MAX_SUPPLY] internal _seeds;
    mapping(string name => AttributeCategory traits) internal _attributes;

    // errors
    error InvalidToken();
    error AlreadyMinted();
    error OutOfStock();

    constructor(
        string[] memory categoryNames,
        AttributeCategory[] memory categories,
        address[] memory reserved_
    ) ERC721("CodexLight", "LIGHT") {
        require(categoryNames.length == categories.length);
        require(reserved_.length == NR_RESERVED);
        _setAttributes(categoryNames, categories);
        _setReserved(reserved_);
    }

    // external admin functions

    /**
     * @dev Sets the external token URI description to `externalBaseURI_`. The URI should end in a `/`.
     *
     * Emits a {BatchMetadataUpdate} event.
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _imageBaseURI = baseURI_;
        emit BatchMetadataUpdate(1, MAX_SUPPLY);
    }

    /**
     * @dev Sets the external token URI description to `externalBaseURI_`.
     *
     * Emits a {BatchMetadataUpdate} event.
     */
    function setExternalBaseURI(string calldata externalBaseURI_) external onlyOwner {
        _externalBaseURI = externalBaseURI_;
        emit BatchMetadataUpdate(1, MAX_SUPPLY);
    }

    /**
     * @dev Sets the token description to `description_`.
     *
     * Emits a {BatchMetadataUpdate} event.
     */
    function setDescription(string calldata description_) external onlyOwner {
        _description = description_;
        emit BatchMetadataUpdate(1, MAX_SUPPLY);
    }

    // external/public functions

    /**
     * @dev See {ERC721Burnable-burn}.
     */
    function burn(uint256 tokenId) public override {
        super.burn(tokenId);
        _burnCounter.increment();
    }

    // external/public functions

    /**
     * @notice Mint a Candle when receiving a Matchbook. Limited to one per address.
     * @dev Hook for `saveTransferFrom` of ERC721 tokens to this contract
     * @param from The address which previously owned the token
     * @param tokenId The ID of the token being transferred
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        if (msg.sender != MATCHBOOKS) revert InvalidToken();
        UserData memory user = _userData[from];
        if (user.hasMinted) revert AlreadyMinted();

        uint256 newTokenId;
        if (user.reservedTokenId > 0) {
            _reservedTokenIdCounter.increment();
            newTokenId = user.reservedTokenId;
        } else if (_tokenIdCounter.current() + NR_RESERVED == MAX_SUPPLY) {
            revert OutOfStock();
        } else {
            _tokenIdCounter.increment();
            newTokenId = _tokenIdCounter.current() + NR_RESERVED;
        }

        // light up
        user.hasMinted = true;
        _userData[from] = user;
        ERC721Burnable(MATCHBOOKS).burn(tokenId);

        // get pseudo-random seed
        // -1 since tokens are 1 based
        _seeds[newTokenId - 1] = uint64(
            uint256(keccak256(abi.encodePacked(newTokenId, block.coinbase, block.prevrandao, block.basefee)))
        );
        _mint(from, newTokenId);

        return IERC721Receiver.onERC721Received.selector;
    }

    // external/public view functions

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory tokenIdStr = tokenId.toString();
        string memory tokenURI_ = string.concat(
            '{"name":"Light #',
            tokenIdStr,
            '","description":"',
            _description,
            '","image":"',
            _imageBaseURI,
            uint256(_seeds[tokenId - 1]).toString(),
            '.png","external_url":"',
            _externalBaseURI,
            tokenIdStr,
            '","attributes":',
            _attributeJson(tokenId),
            "}"
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(tokenURI_)));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        // adds interface for IERC4906
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current() + _reservedTokenIdCounter.current() - _burnCounter.current();
    }

    // internal functions

    function _setAttributes(string[] memory categoryNames, AttributeCategory[] memory categories) internal {
        uint256 length = categoryNames.length;
        for (uint256 i = 0; i < length; ) {
            _attributeNames[i] = categoryNames[i];
            _attributes[categoryNames[i]] = categories[i];
            unchecked {
                i++;
            }
        }
    }

    function _setReserved(address[] memory reserved_) internal {
        uint256 length = reserved_.length;
        for (uint256 i = 0; i < length; ) {
            _userData[reserved_[i]].reservedTokenId = uint8(i + 1);
            unchecked {
                i++;
            }
        }
    }

    // internal view functions

    function _getLight(uint256 tokenId) internal view returns (string[NR_ATTRIBUTES] memory attributes) {
        uint256 seed = _seeds[tokenId - 1]; // -1 since tokens are 1 based
        for (uint256 i = 0; i < NR_ATTRIBUTES; i++) {
            uint256 current = seed % 256;
            AttributeCategory memory category = _attributes[_attributeNames[i]];
            for (uint256 j = 0; j < category.names.length; j++) {
                if (current > category.thresholds[j]) {
                    continue;
                }
                attributes[i] = category.names[j];
                break;
            }
            seed >>= 8;
        }
    }

    function _attributeJson(uint256 tokenId) internal view returns (string memory out) {
        string[NR_ATTRIBUTES] memory attributes = _getLight(tokenId);
        out = "[";
        strings.slice memory delim = "_".toSlice();
        for (uint256 traitIdx = 0; traitIdx < NR_ATTRIBUTES; traitIdx++) {
            strings.slice memory name_ = attributes[traitIdx].toSlice();
            strings.slice[] memory parts = new strings.slice[](name_.count(delim) + 1);
            for (uint i = 0; i < parts.length; i++) {
                parts[i] = name_.split(delim);
            }
            out = string.concat(
                out,
                '{"trait_type":"',
                _attributeNames[traitIdx],
                '","value":"',
                " ".toSlice().join(parts),
                '"}'
            );
            if (traitIdx < NR_ATTRIBUTES - 1) out = string.concat(out, ",");
        }
        out = string.concat(out, "]");
    }
}