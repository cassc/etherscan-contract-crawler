// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./ICreatorCore.sol";

/**
 * @dev Core creator implementation
 */
abstract contract CreatorCore is ICreatorCore, ERC165 {
    using Strings for uint256;

    uint256 internal constant CREATOR_SCALE = 1e6;
    uint256 internal constant TEMPLATE_SCALE = 1e4;
    uint256 internal constant MAX_MINT_ID = 9999;
    uint256 internal constant MAX_TEMPLATE_ID = 99;
    uint256 internal constant MAX_TOKEN_ID = 1e10;

    // For tracking bridged tokenids to a creator
    mapping (uint256 => uint256) internal _creatorTokens;

    // For tracking which address mints for a creator
    mapping (uint256 => address) internal _creatorAddresses;

    // Mapping from creator ID to template ID to mint number
    mapping(uint256 => mapping(uint256 => uint256)) internal _creatorTokenCount;

    // Mapping for creator token URIs
    mapping (uint256 => string) internal _creatorURIs;
    
    // Creator royalty configurations
    mapping (uint256 => address payable[]) internal _creatorRoyaltyReceivers;
    mapping (uint256 => uint256[]) internal _creatorRoyaltyBPS;

    // Mapping for individual token URIs
    mapping (uint256 => string) internal _tokenURIs;

    // Token royalty configurations
    mapping (uint256 => address payable[]) internal _tokenRoyaltyReceivers;
    mapping (uint256 => uint256[]) internal _tokenRoyaltyBPS;

    /**
     * External interface identifiers for royalties
     */

    /**
     *  @dev CreatorCore
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;

    /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *  bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     *
     *  => 0xb9c4d9fb ^ 0x0ebd4c7f = 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    /**
     *  @dev Foundation
     *
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_FOUNDATION = 0xd5a06d4c;

    /**
     *  @dev EIP-2981
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256,bytes)")) == 0x6057361d
     *
     * => 0x6057361d = 0x6057361d
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x6057361d;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ICreatorCore).interfaceId || super.supportsInterface(interfaceId)
            || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 
            || interfaceId == _INTERFACE_ID_ROYALTIES_FOUNDATION || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }
    

    /**
     * @dev Set address for creator id
     */
    function _setCreator(uint256 creatorId, address creator) internal {
        _creatorAddresses[creatorId] = creator;
        emit CreatorUpdated(creatorId, creator);
    }
    
    /**
     * @dev Set base token uri for a creator
     */
    function _setBaseTokenURICreator(uint256 creatorId, string calldata uri) internal {
        _creatorURIs[creatorId] = uri;
    }
    
    /**
     * @dev Set base token uri for tokens with no creator
     */
    function _setBaseTokenURI(string calldata uri) internal {
        _creatorURIs[0] = uri;
    }

    /**
     * @dev Set token uri for a token with no creator
     */
    function _setTokenURI(uint256 tokenId, string calldata uri) internal {
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Retrieve a token's URI
     */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            return _tokenURIs[tokenId];
        }

        uint256 creatorId;
        if(tokenId > MAX_TOKEN_ID) {
            creatorId = _creatorTokens[tokenId];
        } else {
            creatorId = tokenId / CREATOR_SCALE;
        } 
        if (bytes(_creatorURIs[creatorId]).length != 0) {
            return string(abi.encodePacked(_creatorURIs[creatorId], tokenId.toString()));
        }
            
        return string(abi.encodePacked(_creatorURIs[0], tokenId.toString()));
    }

    /**
     * Helper to get royalties for a token
     */
    function _getRoyalties(uint256 tokenId) view internal returns (address payable[] storage, uint256[] storage) {
        return (_getRoyaltyReceivers(tokenId), _getRoyaltyBPS(tokenId));
    }

    /**
     * Helper to get royalty receivers for a token
     */
    function _getRoyaltyReceivers(uint256 tokenId) view internal returns (address payable[] storage) {
        uint256 creatorId;
        if(tokenId > MAX_TOKEN_ID) {
            creatorId = _creatorTokens[tokenId];
        } else {
            creatorId = tokenId / CREATOR_SCALE;
        }         

        if (_tokenRoyaltyReceivers[tokenId].length > 0) {
            return _tokenRoyaltyReceivers[tokenId];
        } else if (_creatorRoyaltyReceivers[creatorId].length > 0) {
            return _creatorRoyaltyReceivers[creatorId];
        }
        return _creatorRoyaltyReceivers[0];        
    }

    /**
     * Helper to get royalty basis points for a token
     */
    function _getRoyaltyBPS(uint256 tokenId) view internal returns (uint256[] storage) {
        uint256 creatorId;
        if(tokenId > MAX_TOKEN_ID) {
            creatorId = _creatorTokens[tokenId];
        } else {
            creatorId = tokenId / CREATOR_SCALE;
        }   

        if (_tokenRoyaltyBPS[tokenId].length > 0) {
            return _tokenRoyaltyBPS[tokenId];
        } else if (_creatorRoyaltyBPS[creatorId].length > 0) {
            return _creatorRoyaltyBPS[creatorId];
        }
        return _creatorRoyaltyBPS[0];        
    }

    function _getRoyaltyInfo(uint256 tokenId, uint256 value) view internal returns (address receiver, uint256 amount, bytes memory data){
        address payable[] storage receivers = _getRoyaltyReceivers(tokenId);
        require(receivers.length <= 1, "CreatorCore: Only works if there are at most 1 royalty receivers");
        
        if (receivers.length == 0) {
            return (address(this), 0, data);
        }
        return (receivers[0], _getRoyaltyBPS(tokenId)[0]*value/10000, data);
    }


    /**
     * Helper to shorten royalties arrays if it is too long
     */
    function _shortenRoyalties(address payable[] storage receivers, uint256[] storage basisPoints, uint256 targetLength) internal {
        require(receivers.length == basisPoints.length, "CreatorCore: Invalid input");
        if (targetLength < receivers.length) {
            for (uint i = receivers.length; i > targetLength; i--) {
                receivers.pop();
                basisPoints.pop();
            }
        }
    }

    /**
     * Helper to update royalites
     */
    function _updateRoyalties(address payable[] storage receivers, uint256[] storage basisPoints, address payable[] calldata newReceivers, uint256[] calldata newBPS) internal {
        require(receivers.length == basisPoints.length, "CreatorCore: Invalid input");
        require(newReceivers.length == newBPS.length, "CreatorCore: Invalid input");
        uint256 totalRoyalties;
        for (uint i = 0; i < newReceivers.length; i++) {
            if (i < receivers.length) {
                receivers[i] = newReceivers[i];
                basisPoints[i] = newBPS[i];
            } else {
                receivers.push(newReceivers[i]);
                basisPoints.push(newBPS[i]);
            }
            totalRoyalties += newBPS[i];
        }
        require(totalRoyalties < 10000, "CreatorCore: Invalid total royalties");
    }

    /**
     * Set royalties for a token
     */
    function _setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) internal {
        require(receivers.length == basisPoints.length, "CreatorCore: Invalid input");
        _shortenRoyalties(_tokenRoyaltyReceivers[tokenId], _tokenRoyaltyBPS[tokenId], receivers.length);
        _updateRoyalties(_tokenRoyaltyReceivers[tokenId], _tokenRoyaltyBPS[tokenId], receivers, basisPoints);
        emit RoyaltiesUpdated(tokenId, receivers, basisPoints);
    }

    /**
     * Set royalties for all tokens of an extension
     */
    function _setRoyaltiesCreator(uint256 creatorId, address payable[] calldata receivers, uint256[] calldata basisPoints) internal {
        require(receivers.length == basisPoints.length, "CreatorCore: Invalid input");
        _shortenRoyalties(_creatorRoyaltyReceivers[creatorId], _creatorRoyaltyBPS[creatorId], receivers.length);
        _updateRoyalties(_creatorRoyaltyReceivers[creatorId], _creatorRoyaltyBPS[creatorId], receivers, basisPoints);
        if (creatorId == 0) {
            emit DefaultRoyaltiesUpdated(receivers, basisPoints);
        } else {
            emit CreatorRoyaltiesUpdated(creatorId, receivers, basisPoints);
        }
    }


}