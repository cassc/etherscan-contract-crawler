// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TerraformsAdmin.sol";

/// @author xaltgeist
/// @title Tokens can be transformed to painter apps or terraformed
abstract contract TerraformsDreaming is TerraformsAdmin {
    
    /// Tokens can have one of five statuses:
    /// 0. Terrain:       The default visual presentation
    /// 1. Daydream:      A blank token that users can paint on
    /// 2. Terraformed:   A terraformed token with user-supplied visuals
    /// 3. OriginDaydream:    A daydream token that was dreaming on mint
    /// 4. OriginTerraformed: A terraformed OriginDaydream token
    enum Status {
        Terrain, 
        Daydream, 
        Terraformed, 
        OriginDaydream, 
        OriginTerraformed
    }
    
    uint public dreamers; // Number of dreaming tokens

    mapping(uint => uint) public tokenToDreamBlock;
    mapping(uint => Status) public tokenToStatus;
    mapping(uint => uint[]) public tokenToCanvasData;
    mapping(uint => address) public tokenToDreamer;
    mapping(uint => address) public tokenToAuthorizedDreamer;

    event Daydreaming(uint tokenId);
    event Terraformed(uint tokenId, address terraformer);

    /// @notice *PERMANENTLY* sets a token to dreaming, changing its attributes
    /// @dev A minimum amount must be dreaming to prevent collapse
    /// @param tokenId The tokenId, from 1 to tokenCounter (max MAX_SUPPLY)
    function enterDream(uint tokenId) public {
        require(msg.sender == ownerOf(tokenId));
        tokenToDreamBlock[tokenId] = block.number;
        if (tokenToStatus[tokenId] == Status.Terrain){
            dreamers += 1;
        }
        if (uint(tokenToStatus[tokenId]) > 2){
            tokenToStatus[tokenId] = Status.OriginDaydream;
        } else {
            tokenToStatus[tokenId] = Status.Daydream;   
        }
        emit Daydreaming(tokenId);
    }

    /// @notice Authorizes an address to commit canvas data to a dreaming token
    /// @dev To revoke, call authorizeDreamer with address(0).
    /// NOTE Authorization is automatically revoked on transfer.
    /// @param tokenId The tokenId, from 1 to tokenCounter (max MAX_SUPPLY)
    /// @param authorizedDreamer The address authorized to commit canvas data
    function authorizeDreamer(uint tokenId, address authorizedDreamer) public {
        require(msg.sender == ownerOf(tokenId));
        tokenToAuthorizedDreamer[tokenId] = authorizedDreamer;
    }

    /// @notice Sets a dreaming token's canvas to a user-supplied drawing
    /// @dev The drawing data is encoded as 16 uints. The 64 least significant
    ///      digits of each uint represent values from 0-9 at successive x,y
    ///      positions on the token, beginning in the top left corner. Each 
    ///      value will be obtained from left to right by taking the current 
    ///      uint mod 10, and then advancing to the next digit until all uints 
    ///      are exhausted. 
    /// @param tokenId The tokenId, from 1 to tokenCounter (max MAX_SUPPLY)
    /// @param dream An array of 16 uints, each representing the heightmap 
    ///              indices of two rows
    function commitDreamToCanvas(uint tokenId, uint[16] memory dream) public {
        require(
            (
                msg.sender == ownerOf(tokenId) ||
                msg.sender == tokenToAuthorizedDreamer[tokenId]
            ) &&
            uint(tokenToStatus[tokenId]) % 2 == 1
        );
        tokenToDreamer[tokenId] = msg.sender;
        tokenToStatus[tokenId] = Status(uint(tokenToStatus[tokenId]) + 1);
        tokenToCanvasData[tokenId] = dream;
        emit Terraformed(tokenId, msg.sender);
    }

    /// @notice On transfer, revokes authorization to commit dreaming token
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal 
        virtual 
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
        tokenToAuthorizedDreamer[tokenId] = address(0);
    }
}