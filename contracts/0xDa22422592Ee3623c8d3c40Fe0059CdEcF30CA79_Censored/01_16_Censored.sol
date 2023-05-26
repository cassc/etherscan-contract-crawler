// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: Pak
/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//       ,ad8888ba,   88888888888  888b      88   ad88888ba     ,ad8888ba,    88888888ba   88888888888  88888888ba,       //
//      d8"'    `"8b  88           8888b     88  d8"     "8b   d8"'    `"8b   88      "8b  88           88      `"8b      //
//  ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████████████████████████████████████████  //
//      Y8a.    .a8P  88           88     `8888  Y8a     a8P   Y8a.    .a8P   88     `8b   88           88      .a8P      //
//       `"Y8888Y"'   88888888888  88      `888   "Y88888P"     `"Y8888Y"'    88      `8b  88888888888  88888888Y"'       //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IClock {
    function metadata() view external returns(string memory);
}

interface ICensor {
    function metadata(uint256 tokenId, string memory message, uint256 value) view external returns(string memory);
}

contract Censored is ReentrancyGuard, AdminControl, ERC721 {

    uint256 private _tokenIndex;
    mapping (uint256 => string) private _tokenMessages;
    mapping (uint256 => uint256) private _tokenValues;
    mapping (bytes32 => bool) private _messageHashes;

    uint256 public messageStartTime;
    uint256 public messageEndTime;
    
    bool private _freedom;
    address _clockAddress;
    address _censorAddress;
    mapping (uint256 => bool) private _tokenFreedom;
    mapping (uint256 => address) private _tokenCensorAddress;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor() ERC721("Censored", unicode"████████") {}

    /**
     * @dev Activate this contract
     */
    function activate(uint256 messageStartTime_, uint256 messageEndTime_, address clockAddress, address censorAddress) external adminRequired {
        require(_tokenIndex == 0, "Already activated");
        _tokenIndex++;
        messageStartTime = messageStartTime_;
        messageEndTime = messageEndTime_;
        _clockAddress = clockAddress;
        _censorAddress = censorAddress;
        _mint(msg.sender, _tokenIndex);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC721) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || AdminControl.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId) || interfaceId == type(IERC721Metadata).interfaceId || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || 
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    function withdraw(address payable recipient, uint256 amount) external adminRequired {
        (bool success,) = recipient.call{value:amount}("");
        require(success);
    }

    function withdraw(address recipient, address erc20, uint256 amount) external adminRequired {
        IERC20(erc20).transfer(recipient, amount);
    }

    /**
     * Set the freedom state
     */
    function setFreedom(uint256[] calldata tokenIds, bool freedom) public adminRequired {
        if (tokenIds.length == 0) {
            _freedom = freedom;
        } else {
            for (uint i = 0; i < tokenIds.length; i++) {
                _tokenFreedom[tokenIds[i]] = freedom;
            }
        }
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (tokenId == 1) {
            return IClock(_clockAddress).metadata();
        } else {
            if (_tokenCensorAddress[tokenId] != address(0)) {
                return ICensor(_tokenCensorAddress[tokenId]).metadata(tokenId, _tokenMessages[tokenId], _tokenValues[tokenId]);
            } else {
                return ICensor(_censorAddress).metadata(tokenId, _tokenMessages[tokenId], _tokenValues[tokenId]);
            }
        }
    }

    /**
     * @dev See {ERC721-_beforeTokenTranfser}.
     */
    function _beforeTokenTransfer(address from, address, uint256 tokenId) internal view override {
        require(from == address(0) || tokenId == 1 || _tokenFreedom[tokenId] || _freedom, "ERC721: transfer not permitted");
    }

    /**
     * @dev Validate that a message can be written
     */
    function validateMessage(string memory message_) public view returns(bool) {
        // Max length 72, a-z only
        bytes memory messageBytes = bytes(message_);
        require(messageBytes.length > 0 && messageBytes[0] != 0x20 && messageBytes[messageBytes.length-1] != 0x20, "Invalid characters");
        require(messageBytes.length <= 72, "Message too long");
        bytes32 messageHash = keccak256(messageBytes);
        require(!_messageHashes[messageHash], "Message already exists");

        for (uint i = 0; i < messageBytes.length; i++) {
            bytes1 char = messageBytes[i];
            if (!(char >= 0x61 && char <= 0x7A) && char != 0x20) {
                revert("Invalid character");
            } else if (i >= 1 && char == 0x20 && messageBytes[i-1] == 0x20) {
                revert("Cannot have multiple sequential spaces");
            }
        }
        return true;
    }
    
    /**
     * @dev Write a message and get an NFT.
     */
    function message(string memory message_) external nonReentrant payable {
        require((block.timestamp >= messageStartTime && block.timestamp <= messageEndTime && _tokenIndex >= 2) || (msg.sender == owner() && _tokenIndex > 0), "Cannot message");
        require(balanceOf(msg.sender) == 0, "You have already sent a message");
        validateMessage(message_);
        _tokenIndex++;
        _tokenMessages[_tokenIndex] = message_;
        _tokenValues[_tokenIndex] = msg.value;
        _messageHashes[keccak256(bytes(message_))] = true;
        _mint(msg.sender, _tokenIndex);
    }

    /**
     * @dev Update metadata
     */
    function updateMetadata(address clockAddress, address censorAddress) external adminRequired {
        _clockAddress = clockAddress;
        _censorAddress = censorAddress;
    }

    /**
     * @dev Update metadata for specific tokens
     */
    function updateTokenMetadata(uint256[] calldata tokenIds, address censorAddress) external adminRequired {
        for (uint i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 1 && tokenIds[i] <= _tokenIndex, "Invalid token id");
            _tokenCensorAddress[tokenIds[i]] = censorAddress;
        }
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

}