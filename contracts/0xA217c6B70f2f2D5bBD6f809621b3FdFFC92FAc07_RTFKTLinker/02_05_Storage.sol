// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

library LinkingStorage {
    bytes32 internal constant NAMESPACE = keccak256("rtfkt.linking.storage");

    struct Storage {
        address signer;
        mapping (address => bool) authorizedCollections;
        mapping (string => mapping (address => uint256) ) tagIdToTokenId; // Tag ID => Contract address => Token ID (0 = no token ID)
        mapping (address => mapping (uint256 => string) ) tokenIdtoTagId; // Contract address => Token ID => Tag ID (null = no tag ID)
        mapping (address => mapping (uint256 => address[2])) linkOwner; // Array of 2 | 0 : current owner, 1 : potential new owner (when pending) | 0x0000000000000000000000000000000000000000 = null
        mapping (string => address) tagIdToCollectionAddress; // Tag ID => Contract address 
    }
    
    function getStorage() internal pure returns(Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    ///////////////////////////
    // GETTER
    ///////////////////////////

    function getSigner() internal view returns(address) {
        Storage storage s = getStorage(); 
        return s.signer;
    }

    function isAuthorizedCollection(address collectionAddress) internal view returns(bool) {
        return getStorage().authorizedCollections[collectionAddress];
    }

    function tagIdToTokenId(string calldata tagId, address collectionAddress) internal view returns(uint256) {
        return getStorage().tagIdToTokenId[tagId][collectionAddress];
    }

    function tokenIdtoTagId(address collectionAddress, uint256 tokenId) internal view returns(string memory) {
        return getStorage().tokenIdtoTagId[collectionAddress][tokenId];
    }

    function tagIdToCollectionAddress(string calldata tagId) internal view returns(address) {
        return getStorage().tagIdToCollectionAddress[tagId];
    }

    function linkOwner(address collectionAddress, uint256 tokenId) internal view returns(address[2] memory) {
        return getStorage().linkOwner[collectionAddress][tokenId];
    }
    
    ///////////////////////////
    // SETTER
    ///////////////////////////

    function setSigner(address _newSigner) internal {
        getStorage().signer = _newSigner;
    }

    function toggleAuthorizedCollection(address[] calldata collectionAddress) internal {
        Storage storage s = getStorage();
        for(uint256 i = 0; i < collectionAddress.length; i++) {
            s.authorizedCollections[collectionAddress[i]] = !s.authorizedCollections[collectionAddress[i]];
        }
    }

    function setTagIdToTokenId(string calldata tagId, address collectionAddress, uint256 tokenId) internal {
        getStorage().tagIdToTokenId[tagId][collectionAddress] = tokenId;

        // Managing the tagIdToCollectionAddress[tagId]
        getStorage().tagIdToCollectionAddress[tagId] = (tokenId == 0) ? 0x0000000000000000000000000000000000000000 : collectionAddress;
    }

    function setTokenIdtoTagId(address collectionAddress, uint256 tokenId, string memory tagId) internal {
        getStorage().tokenIdtoTagId[collectionAddress][tokenId] = tagId;
    }

    function setLinkOwner(address collectionAddress, uint256 tokenId, uint256 typeOfOwner, address ownerAddress) internal {
        getStorage().linkOwner[collectionAddress][tokenId][typeOfOwner] = ownerAddress;
    }

    
}