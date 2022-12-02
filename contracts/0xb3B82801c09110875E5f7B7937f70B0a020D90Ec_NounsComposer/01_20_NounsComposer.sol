// SPDX-License-Identifier: GPL-3.0

/// @title The Nouns composer

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

import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { ERC1155HolderUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol';

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { INounsToken } from '../../interfaces/INounsToken.sol';
import { ISVGRenderer } from '../../interfaces/ISVGRenderer.sol';

import { INounsComposer } from './interfaces/INounsComposer.sol';
import { IComposablePart } from '../items/interfaces/IComposablePart.sol';

contract NounsComposer is INounsComposer, ERC1155HolderUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    // The Nouns ERC721 token contract
    INounsToken public nouns;

	// Composed Child Tokens, token_id, position1
    mapping(uint256 => mapping(uint16 => ChildToken)) public composedChildTokens;    

    // tokenId => array of child contract
    mapping(uint256 => address[]) public childContracts;

    // tokenId => (child address => array of child tokens)
    mapping(uint256 => mapping(address => uint256[])) public childTokens;

    // tokenId => (child address => contract index)
    mapping(uint256 => mapping(address => uint256)) public childContractIndex;

    // tokenId => (child address => (child token => ChildTokenState(index, balance, position1))
    mapping(uint256 => mapping(address => mapping(uint256 => ChildTokenState))) public childTokenState;
        
    /**
     * @notice Initialize the composer and base contracts, and populate configuration values.
     * @dev This function can only be called once.
     */
    function initialize(
        INounsToken _nouns
    ) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        nouns = _nouns;
    }

    function getChildContracts(uint256 _tokenId) external view returns (address[] memory) {
    	return childContracts[_tokenId];
    }

    function getChildTokens(uint256 _tokenId, address _childTokenAddress) external view returns (uint256[] memory) {
    	return childTokens[_tokenId][_childTokenAddress];
    }

    function getChildContractCount(uint256 _tokenId) external view returns (uint256) {
    	return childContracts[_tokenId].length;
    }
    
    function getChildTokenCount(uint256 _tokenId, address _childTokenAddress) external view returns (uint256) {
    	return childTokens[_tokenId][_childTokenAddress].length;
    }

    function getChildTokenState(uint256 _tokenId, address _childTokenAddress, uint256 _childTokenId) external view returns (ChildTokenState memory) {
    	return childTokenState[_tokenId][_childTokenAddress][_childTokenId];
    }

    function getChildTokenStateBatch(uint256 _tokenId, address[] calldata _childTokenAddresses, uint256[] calldata _childTokenIds) external view returns (ChildTokenState[] memory) {
		uint256 len = _childTokenAddresses.length;
        ChildTokenState[] memory batchTokenStates = new ChildTokenState[](len);
		
        for (uint256 i = 0; i < len;) {
            batchTokenStates[i] = childTokenState[_tokenId][_childTokenAddresses[i]][_childTokenIds[i]];

			unchecked {
            	i++;
        	}
        }

    	return batchTokenStates;
    }

    function getComposedChild(uint256 _tokenId, uint16 _position1) external view returns (ChildToken memory) {
    	return composedChildTokens[_tokenId][_position1];
    }

    function getComposedChildBatch(uint256 _tokenId, uint16 _position1Start, uint16 _position1End) external view returns (ChildToken[] memory) {
    	require(_position1End > _position1Start, "NounsComposer: invalid position range");
    	
    	uint16 len = _position1End - _position1Start + 1;
        ChildToken[] memory batchTokens = new ChildToken[](len);

        for (uint16 i = 0; i < len;) {
            batchTokens[i] = composedChildTokens[_tokenId][_position1Start + i];

			unchecked {
            	i++;
        	}
        }

        return batchTokens;
    }

    function childExists(uint256 _tokenId, address _childTokenAddress, uint256 _childTokenId) external view returns (bool) {
    	return _childExists(_tokenId, _childTokenAddress, _childTokenId);
    }

    /*
     * Receive and Transfer Child Tokens
     * 
     */

    function receiveChild(uint256 _tokenId, TokenTransferParams calldata _child) external nonReentrant {    	
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");
				
		_receiveChild(_tokenId, _child.tokenAddress, _child.tokenId, _child.amount);
    }
    
    function receiveChildBatch(uint256 _tokenId, TokenTransferParams[] calldata _children) external nonReentrant {    	
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");		

		_receiveChildBatch(_tokenId, _children);
    }
    
    function receiveAndComposeChild(uint256 _tokenId, TokenFullParams calldata _child) external nonReentrant {    	
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");

		_receiveChild(_tokenId, _child.tokenAddress, _child.tokenId, _child.amount);
    	_composeChild(_tokenId, _child.tokenAddress, _child.tokenId, _child.position1, _child.boundTop1, _child.boundLeft1);
    }
    
    function receiveAndComposeChildBatch(uint256 _tokenId, TokenFullParams[] calldata _children) external nonReentrant {    	
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");

		_receiveChildBatch(_tokenId, _children);
		_composeChildBatch(_tokenId, _children);        
    }    

    function receiveAndComposeChildBatchMixed(uint256 _tokenId, TokenTransferParams[] calldata _childrenReceive, TokenPositionParams[] calldata _childrenCompose) external nonReentrant {    	
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");

		_receiveChildBatch(_tokenId, _childrenReceive);
		_composeChildBatch(_tokenId, _childrenCompose);
    }    


    function _receiveChildBatch(uint256 _tokenId, TokenTransferParams[] calldata _children) internal {    	
		uint256 len = _children.length;
		
        for (uint256 i = 0; i < len;) {
			_receiveChild(_tokenId, _children[i].tokenAddress, _children[i].tokenId, _children[i].amount);
			unchecked {
            	i++;
        	}
        }
    }

    function _receiveChildBatch(uint256 _tokenId, TokenFullParams[] calldata _children) internal {    	
		uint256 len = _children.length;
		
        for (uint256 i = 0; i < len;) {
			_receiveChild(_tokenId, _children[i].tokenAddress, _children[i].tokenId, _children[i].amount);
			unchecked {
            	i++;
        	}
        }
    }
    
    function _receiveChild(uint256 _tokenId, address _childTokenAddress, uint256 _childTokenId, uint256 _childAmount) internal {        
        uint256 childTokensLength = childTokens[_tokenId][_childTokenAddress].length;
        if (childTokensLength == 0) {
            childContractIndex[_tokenId][_childTokenAddress] = childContracts[_tokenId].length;
            childContracts[_tokenId].push(_childTokenAddress);
        }
        
        uint256 childTokenBalance = childTokenState[_tokenId][_childTokenAddress][_childTokenId].balance;
        if (childTokenBalance == 0) {        	
	        childTokenState[_tokenId][_childTokenAddress][_childTokenId] = ChildTokenState(_childAmount, uint64(childTokensLength), 0, 0, 0);
	        childTokens[_tokenId][_childTokenAddress].push(_childTokenId);
        } else {
	        childTokenState[_tokenId][_childTokenAddress][_childTokenId].balance += _childAmount;
	    }

        _callTransferFrom(_msgSender(), address(this), _childTokenAddress, _childTokenId, _childAmount);
    	emit ChildReceived(_tokenId, _msgSender(), _childTokenAddress, _childTokenId, _childAmount);
    }    
    
    function transferChild(uint256 _tokenId, address _to, TokenTransferParams calldata _child) external nonReentrant {
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");
        require(_to != address(0), "NounsComposer: transfer to the zero address");

        _transferChild(_tokenId, _to, _child.tokenAddress, _child.tokenId, _child.amount);
    }

    function transferChildBatch(uint256 _tokenId, address _to, TokenTransferParams[] calldata _children) external nonReentrant {
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");
        require(_to != address(0), "NounsComposer: transfer to the zero address");

		uint256 len = _children.length;
		
        for (uint256 i = 0; i < len;) {
			_transferChild(_tokenId, _to, _children[i].tokenAddress, _children[i].tokenId, _children[i].amount);
			unchecked {
            	i++;
        	}
        }        
    }
    
    function _transferChild(uint256 _tokenId, address _to, address _childTokenAddress, uint256 _childTokenId, uint256 _childAmount) internal {

		ChildTokenState memory childState = childTokenState[_tokenId][_childTokenAddress][_childTokenId];		
        uint256 tokenIndex = childState.index;
        
        require(childState.balance >= _childAmount, "NounsComposer: insufficient balance for transfer");
        
		if (childState.position1 > 0) {
			_removeComposedChild(_tokenId, (childState.position1));
		}

		uint256 newChildBalance;
        unchecked {
        	newChildBalance = childState.balance - _childAmount;
        }

        childTokenState[_tokenId][_childTokenAddress][_childTokenId].balance = newChildBalance;

		if (newChildBalance == 0) {
			// remove token
	        uint256 lastTokenIndex = childTokens[_tokenId][_childTokenAddress].length - 1;
	        uint256 lastToken = childTokens[_tokenId][_childTokenAddress][lastTokenIndex];
	        if (_childTokenId != lastToken) {
	            childTokens[_tokenId][_childTokenAddress][tokenIndex] = lastToken;
	            childTokenState[_tokenId][_childTokenAddress][lastToken].index = uint64(tokenIndex);
	        }

	        childTokens[_tokenId][_childTokenAddress].pop();
	        delete childTokenState[_tokenId][_childTokenAddress][_childTokenId];
	
	        if (lastTokenIndex == 0) {
	        	// remove contract
	            uint256 lastContractIndex = childContracts[_tokenId].length - 1;
	            address lastContract = childContracts[_tokenId][lastContractIndex];
	            if (_childTokenAddress != lastContract) {
	                uint256 contractIndex = childContractIndex[_tokenId][_childTokenAddress];
	                childContracts[_tokenId][contractIndex] = lastContract;
	                childContractIndex[_tokenId][lastContract] = contractIndex;
	            }
	            childContracts[_tokenId].pop();
	            delete childContractIndex[_tokenId][_childTokenAddress];
	        }
		}
				
		_callTransferFrom(address(this), _to, _childTokenAddress, _childTokenId, _childAmount);
    	emit ChildTransferred(_tokenId, _to, _childTokenAddress, _childTokenId, _childAmount);
    }

    function _callTransferFrom(address _from, address _to, address _childTokenAddress, uint256 _childTokenId, uint256 _childAmount) internal {    	
    	IERC165 introContract = IERC165(_childTokenAddress);
    	
        if (introContract.supportsInterface(type(IERC1155).interfaceId)) {
			IERC1155(_childTokenAddress).safeTransferFrom(_from, _to, _childTokenId, _childAmount, "0x0");
		} else if (introContract.supportsInterface(type(IERC20).interfaceId)) {
			IERC20(_childTokenAddress).transferFrom(_from, _to, _childAmount);
		} else if (introContract.supportsInterface(type(IERC721).interfaceId)) {
    		IERC721(_childTokenAddress).transferFrom(_from, _to, _childTokenId);
       	} else {
			revert("NounsComposer: unsupported token type");
       	}    	
    }
    
    /*
     * Child Part Composition
     * 
     */
    
    function composeChild(uint256 _tokenId, TokenPositionParams calldata _child) external {    	
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");
		require(_childExists(_tokenId, _child.tokenAddress, _child.tokenId), "NounsComposer: compose query for nonexistent child");

    	_composeChild(_tokenId, _child.tokenAddress, _child.tokenId, _child.position1, _child.boundTop1, _child.boundLeft1);
    }

    function composeChildBatch(uint256 _tokenId, TokenPositionParams[] calldata _children) external {
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");

		_composeChildBatch(_tokenId, _children);
    }

    function removeComposedChild(uint256 _tokenId, uint16 _position1) external {
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");
		require(composedChildTokens[_tokenId][_position1].tokenAddress != address(0), "NounsComposer: compose query for nonexistent child");		

		_removeComposedChild(_tokenId, _position1);
    }

    function removeComposedChildBatch(uint256 _tokenId, uint16[] calldata _position1s) external {    	
		require(_isApprovedOrOwner(_msgSender(), _tokenId), "NounsComposer: caller is not token owner nor approved");

		uint256 len = _position1s.length;
		
        for (uint256 i = 0; i < len;) {
			require(composedChildTokens[_tokenId][_position1s[i]].tokenAddress != address(0), "NounsComposer: compose query for nonexistent child");		
    		_removeComposedChild(_tokenId, _position1s[i]);
        	
			unchecked {
            	i++;
        	}
        }
    }
    
    function _composeChild(uint256 _tokenId, address _childTokenAddress, uint256 _childTokenId, uint16 _position1, uint8 _boundTop1, uint8 _boundLeft1) internal {
        ChildTokenState memory childState = childTokenState[_tokenId][_childTokenAddress][_childTokenId];

		//first, check if source child token is being moved from an existing position
		if (childState.position1 != 0 && childState.position1 != _position1) {
			_removeComposedChild(_tokenId, childState.position1);
		}

		//this allows for parts to be removed via batch compose calls
    	if (_position1 == 0) {
			return;
    	}
    	
    	//then, check to see if the target position has a child token, if so, clear it
		if (composedChildTokens[_tokenId][_position1].tokenAddress != address(0)) {
			_removeComposedChild(_tokenId, _position1);
		}
		
        composedChildTokens[_tokenId][_position1] = ChildToken(_childTokenAddress, _childTokenId);

		childState.position1 = _position1;
		childState.boundTop1 = _boundTop1;
		childState.boundLeft1 = _boundLeft1;
		
		childTokenState[_tokenId][_childTokenAddress][_childTokenId] = childState;

        emit CompositionAdded(_tokenId, _childTokenAddress, _childTokenId, _position1, _boundTop1, _boundLeft1);
    }

    function _composeChildBatch(uint256 _tokenId, TokenPositionParams[] calldata _children) internal {
		uint256 len = _children.length;
		
        for (uint256 i = 0; i < len;) {
        	require(_childExists(_tokenId, _children[i].tokenAddress, _children[i].tokenId), "NounsComposer: compose query for nonexistent child");
    		_composeChild(_tokenId, _children[i].tokenAddress, _children[i].tokenId, _children[i].position1, _children[i].boundTop1, _children[i].boundLeft1);
        	
			unchecked {
            	i++;
        	}
        }
    }

    function _composeChildBatch(uint256 _tokenId, TokenFullParams[] calldata _children) internal {
		uint256 len = _children.length;
		
        for (uint256 i = 0; i < len;) {
        	require(_childExists(_tokenId, _children[i].tokenAddress, _children[i].tokenId), "NounsComposer: compose query for nonexistent child");
    		_composeChild(_tokenId, _children[i].tokenAddress, _children[i].tokenId, _children[i].position1, _children[i].boundTop1, _children[i].boundLeft1);
        	
			unchecked {
            	i++;
        	}
        }
    }

    function _removeComposedChild(uint256 _tokenId, uint16 _position1) internal {
		ChildToken memory child = composedChildTokens[_tokenId][_position1];
    	
        delete composedChildTokens[_tokenId][_position1];

		ChildTokenState memory childState = childTokenState[_tokenId][child.tokenAddress][child.tokenId];

		childState.position1 = 0;
		childState.boundTop1 = 0;
		childState.boundLeft1 = 0;

		childTokenState[_tokenId][child.tokenAddress][child.tokenId] = childState;

        emit CompositionRemoved(_tokenId, child.tokenAddress, child.tokenId, _position1);
    }

    /*
     * Called by NounsComposableDescriptor
     * 
     */

    function getParts(uint256 _tokenId) external view returns (ISVGRenderer.Part[] memory) {
		//current configuration supports 16 composed items
        uint16 maxParts = 16;
        ISVGRenderer.Part[] memory parts = new ISVGRenderer.Part[](maxParts);

        for (uint16 i = 0; i < maxParts;) {
        	ChildToken memory child = composedChildTokens[_tokenId][i + 1]; //position is a 1-based index
        	
        	if (child.tokenAddress != address(0)) {        	
	        	ISVGRenderer.Part memory part = IComposablePart(child.tokenAddress).getPart(child.tokenId);	        	
	        	ChildTokenState memory childState = childTokenState[_tokenId][child.tokenAddress][child.tokenId];
	        	
	        	if (childState.boundTop1 > 0) {
	        		uint8 boundTop1 = childState.boundTop1 - 1; //top is a 1-based index
	        		
		        	//shift the part's bounding box
		        	uint8 top = uint8(part.image[1]);
	            	uint8 bottom = uint8(part.image[3]);

	            	if (boundTop1 < top) {
	            		top -= (top - boundTop1);
	            		bottom -= (top - boundTop1);
	            	} else if (boundTop1 > top) {
	            		top += (boundTop1 - top);
	            		bottom += (boundTop1 - top);
	            	}

		        	part.image[1] = bytes1(top);
		        	part.image[3] = bytes1(bottom);
		        }

	        	if (childState.boundLeft1 > 0) {
	        		uint8 boundLeft1 = childState.boundLeft1 - 1; //left is a 1-based index

		        	//shift the part's bounding box
	            	uint8 right = uint8(part.image[2]);
	            	uint8 left = uint8(part.image[4]);

	            	if (boundLeft1 < left) {
	            		right -= (left - boundLeft1);
	            		left -= (left - boundLeft1);
	            	} else if (boundLeft1 > left) {
	            		right += (boundLeft1 - left);
	            		left += (boundLeft1 - left);
	            	}
	            	
		        	part.image[2] = bytes1(right);
		        	part.image[4] = bytes1(left);
		        }
		        
	        	parts[i] = part;
	        }

			unchecked {
            	i++;
        	}
        }
        
        return parts;
    }

    function hasParts(uint256 _tokenId) external view returns (bool) {
		//current configuration supports 16 composed items
        uint16 maxParts = 16;

        for (uint16 i = 0; i < maxParts;) {
        	if (composedChildTokens[_tokenId][i + 1].tokenAddress != address(0)) {
        		return true;
	        }

			unchecked {
            	i++;
        	}
        }

        return false;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = nouns.ownerOf(tokenId);
        return (spender == owner || nouns.getApproved(tokenId) == spender || nouns.isApprovedForAll(owner, spender));
    }

    function _childExists(uint256 _tokenId, address _childTokenAddress, uint256 _childTokenId) internal view returns (bool) {        
        return childTokenState[_tokenId][_childTokenAddress][_childTokenId].balance > 0;
    }    
    
}