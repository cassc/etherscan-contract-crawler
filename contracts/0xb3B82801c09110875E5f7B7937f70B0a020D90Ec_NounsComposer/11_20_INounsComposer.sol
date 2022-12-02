// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Nouns Composer

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { ISVGRenderer } from '../../../interfaces/ISVGRenderer.sol';

interface INounsComposer {

    struct ChildToken {
        address tokenAddress;
        uint256 tokenId;
    }

    struct ChildTokenState {
        uint256 balance;
        uint64 index;
        uint16 position1; //position is a 1-based index
        uint8 boundTop1; //top is a 1-based index
        uint8 boundLeft1; //left is a 1-based index
    }

    struct TokenTransferParams {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }

    struct TokenPositionParams {
        address tokenAddress;
        uint256 tokenId;
        uint16 position1; //position is a 1-based index
        uint8 boundTop1; //top is a 1-based index
        uint8 boundLeft1; //left is a 1-based index
    }

    struct TokenFullParams {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        uint16 position1; //position is a 1-based index
        uint8 boundTop1; //top is a 1-based index
        uint8 boundLeft1; //left is a 1-based index
    }

    event ChildReceived(uint256 indexed tokenId, address indexed from, address indexed childTokenAddress, uint256 childTokenId, uint256 amount);
    event ChildTransferred(uint256 indexed tokenId, address indexed to, address indexed childTokenAddress, uint256 childTokenId, uint256 amount);
	
	event CompositionAdded(uint256 indexed tokenId, address indexed childTokenAddress, uint256 indexed childTokenId, uint16 position1, uint8 boundTop1, uint8 boundLeft1);
	event CompositionRemoved(uint256 indexed tokenId, address indexed childTokenAddress, uint256 indexed childTokenId, uint16 position1);

    function getChildContracts(uint256 _tokenId) external view returns (address[] memory);

    function getChildTokens(uint256 _tokenId, address _childTokenAddress) external view returns (uint256[] memory);

    function getChildContractCount(uint256 _tokenId) external view returns (uint256);    

    function getChildTokenCount(uint256 _tokenId, address _childTokenAddress) external view returns (uint256);

    function getChildTokenState(uint256 _tokenId, address _childTokenAddress, uint256 _childTokenId) external view returns (ChildTokenState memory);

    function getChildTokenStateBatch(uint256 _tokenId, address[] calldata _childTokenAddresses, uint256[] calldata _childTokenIds) external view returns (ChildTokenState[] memory);

    function getComposedChild(uint256 tokenId, uint16 position1) external view returns (ChildToken memory);

	function getComposedChildBatch(uint256 _tokenId, uint16 _position1Start, uint16 _position1End) external view returns (ChildToken[] memory);
    
    function childExists(uint256 _tokenId, address _childTokenAddress, uint256 _childTokenId) external view returns (bool);

    function receiveChild(uint256 _tokenId, TokenTransferParams calldata _child) external;
        
    function receiveChildBatch(uint256 _tokenId, TokenTransferParams[] calldata _children) external;
    
    function receiveAndComposeChild(uint256 _tokenId, TokenFullParams calldata _child) external;
        
    function receiveAndComposeChildBatch(uint256 _tokenId, TokenFullParams[] calldata _children) external;

    function receiveAndComposeChildBatchMixed(uint256 _tokenId, TokenTransferParams[] calldata _childrenReceive, TokenPositionParams[] calldata _childrenCompose) external;
    
    function transferChild(uint256 _tokenId, address _to, TokenTransferParams calldata _child) external;
    
    function transferChildBatch(uint256 _tokenId, address _to, TokenTransferParams[] calldata _children) external;

    function composeChild(uint256 _tokenId, TokenPositionParams calldata _child) external;

    function composeChildBatch(uint256 _tokenId, TokenPositionParams[] calldata _children) external;

    function removeComposedChild(uint256 _tokenId, uint16 _position1) external;

    function removeComposedChildBatch(uint256 _tokenId, uint16[] calldata _position1s) external;

    function getParts(uint256 _tokenId) external view returns (ISVGRenderer.Part[] memory);

    function hasParts(uint256 _tokenId) external view returns (bool);
}