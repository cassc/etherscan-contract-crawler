// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC721.sol";
import "../interfaces/IERC721DefaultOwnerCloneable.sol";

abstract contract ERC721Omnibus is ERC721, IERC721DefaultOwnerCloneable {
    
    struct TokenOwner {
        bool transferred;
        address ownerAddress;
    }

    struct CollectionStatus {
        bool isContractFinalized; // 1 byte
        uint88 amountCreated; // 11 bytes
        address defaultOwner; // 20 bytes
    }    

    // Only allow Nifty Entity to be initialized once
    bool internal initializedDefaultOwner;
    CollectionStatus internal collectionStatus;

    // Mapping from token ID to owner address    
    mapping(uint256 => TokenOwner) internal ownersOptimized;    

    function initializeDefaultOwner(address defaultOwner_) public {
        require(!initializedDefaultOwner, ERROR_REINITIALIZATION_NOT_PERMITTED);
        collectionStatus.defaultOwner = defaultOwner_;
        initializedDefaultOwner = true;
    }       

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return         
        interfaceId == type(IERC721DefaultOwnerCloneable).interfaceId ||
        super.supportsInterface(interfaceId);
    }    

    function getCollectionStatus() public view virtual returns (CollectionStatus memory) {
        return collectionStatus;
    }
 
    function ownerOf(uint256 tokenId) public view virtual override returns (address owner) {
        require(_isValidTokenId(tokenId), ERROR_QUERY_FOR_NONEXISTENT_TOKEN);
        owner = ownersOptimized[tokenId].transferred ? ownersOptimized[tokenId].ownerAddress : collectionStatus.defaultOwner;
        require(owner != address(0), ERROR_QUERY_FOR_NONEXISTENT_TOKEN);
    }        
    
    function _exists(uint256 tokenId) internal view virtual override returns (bool) {
        if(_isValidTokenId(tokenId)) {            
            return ownersOptimized[tokenId].ownerAddress != address(0) || !ownersOptimized[tokenId].transferred;
        }
        return false;   
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (address owner, bool isApprovedOrOwner) {
        owner = ownerOf(tokenId);
        isApprovedOrOwner = (spender == owner || tokenApprovals[tokenId] == spender || isApprovedForAll(owner, spender));
    }       

    function _clearOwnership(uint256 tokenId) internal virtual override {
        ownersOptimized[tokenId].transferred = true;
        ownersOptimized[tokenId].ownerAddress = address(0);
    }

    function _setOwnership(address to, uint256 tokenId) internal virtual override {
        ownersOptimized[tokenId].transferred = true;
        ownersOptimized[tokenId].ownerAddress = to;
    }               

    function _isValidTokenId(uint256 /*tokenId*/) internal virtual view returns (bool);    
}