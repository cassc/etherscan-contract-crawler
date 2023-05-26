// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "../roles/AdminRole.sol";
import "../interfaces/ITokenManager.sol";
import "../interfaces/IRoyalty.sol";
import "../libs/NftTokenLibrary.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract NftTokenManager is ITokenManager, AdminRole {
    struct NftToken {
        string name;
        bool created;
        bool active;
        NftTokenLibrary.TokenType tokenType;
    }

    /// @notice ERC1155 or ERC721 Token address -> active boolean
    mapping(address => NftToken) public tokens;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    modifier exist(address _token) {
        require(tokens[_token].created != false, "NftTokenManager: Token is not added");
        _;
    }
    // TODO: Add Token By Batch
    function addToken(address _token, string calldata _name, bool _active, NftTokenLibrary.TokenType _tokenType) onlyAdmin external {
        require(_token != address(0), "NftTokenManager: Cannot be zero address");
        require(tokens[_token].created == false, "NftTokenManager: Token already exist");
        // TODO: Add Royalty type and link royalty to erc token
        if (_tokenType != NftTokenLibrary.TokenType.REFINABLE_ROYALTY_ERC721_CONTRACT && _tokenType != NftTokenLibrary.TokenType.REFINABLE_ROYALTY_ERC1155_CONTRACT) {
            require(
                IERC721(_token).supportsInterface(_INTERFACE_ID_ERC721) || IERC1155(_token).supportsInterface(_INTERFACE_ID_ERC1155),
                "NftTokenManager: Token is not ERC1155 or ERC721 standard"
            );
        } else {
            require(
                IERC165(_token).supportsInterface(type(IRoyalty).interfaceId),
                "NftTokenManager: Token is not IRoyalty standard"
            );
        }
        tokens[_token] = NftToken({
        name : _name,
        created : true,
        active : _active,
        tokenType : _tokenType
        });
    }

    function setToken(address _token, bool _active) onlyAdmin exist(_token) external override {
        tokens[_token].active = _active;
    }

    function removeToken(address _token) onlyAdmin exist(_token) external override {
        delete tokens[_token];
    }

    function supportToken(address _token) exist(_token) external view override returns (bool) {
        return tokens[_token].active;
    }

    function getTokenType(address _token) exist(_token) external view returns (NftTokenLibrary.TokenType) {
        return tokens[_token].tokenType;
    }
}