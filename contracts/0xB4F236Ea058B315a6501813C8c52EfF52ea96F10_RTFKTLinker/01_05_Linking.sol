// SPDX-License-Identifier: MIT

/*
    RTFKT Legal Overview [https://rtfkt.com/legaloverview]
    1. RTFKT Platform Terms of Services [Document #1, https://rtfkt.com/tos]
    2. End Use License Terms
    A. Digital Collectible Terms (RTFKT-Owned Content) [Document #2-A, https://rtfkt.com/legal-2A]
    B. Digital Collectible Terms (Third Party Content) [Document #2-B, https://rtfkt.com/legal-2B]
    C. Digital Collectible Limited Commercial Use License Terms (RTFKT-Owned Content) [Document #2-C, https://rtfkt.com/legal-2C]
    D. Digital Collectible Terms [Document #2-D, https://rtfkt.com/legal-2D]
    
    3. Policies or other documentation
    A. RTFKT Privacy Policy [Document #3-A, https://rtfkt.com/privacy]
    B. NFT Issuance and Marketing Policy [Document #3-B, https://rtfkt.com/legal-3B]
    C. Transfer Fees [Document #3C, https://rtfkt.com/legal-3C]
    C. 1. Commercialization Registration [https://rtfkt.typeform.com/to/u671kiRl]
    
    4. General notices
    A. Murakami Short Verbiage – User Experience Notice [Document #X-1, https://rtfkt.com/legal-X1]

    LINKING CONTRACT V1 by @CardilloSamuel
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Storage.sol";

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract RTFKTLinker {
    using ECDSA for bytes32;

    mapping (address => bool) authorizedOwners;

    constructor() {
        authorizedOwners[0x623FC4F577926c0aADAEf11a243754C546C1F98c] = true;
    }

    modifier isAuthorizedOwner() {
        require(authorizedOwners[tx.origin], "Unauthorized"); 
        _;
    }

    event link(address initiator, string tagId, uint256 tokenId, address collectionAddress);
    event unlink(address initiator, string tagId, uint256 tokenId, address collectionAddress);
    event transfer(address from, address to, string tagId, uint256 tokenId, address collectionAddress);

    ///////////////////////////
    // SETTER
    ///////////////////////////

    function linkNft(string calldata tagId, uint256 tokenId, address collectionAddress, bytes calldata signature) public {
        require(LinkingStorage.isAuthorizedCollection(collectionAddress), "This collection has not been approved");
        require(_isValidSignature(_hash(collectionAddress, tokenId, tagId), signature), "Invalid signature");

        ERC721 tokenContract = ERC721(collectionAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender, "You don't own the NFT");
        require(LinkingStorage.tagIdToTokenId(tagId, collectionAddress) == 0, "This item is already linked" );

        // Set the tokenID, tagId and address of link owner
        LinkingStorage.setTagIdToTokenId(tagId, collectionAddress, tokenId);
        LinkingStorage.setTokenIdtoTagId(collectionAddress, tokenId, tagId);
        LinkingStorage.setLinkOwner(collectionAddress, tokenId, 0, msg.sender);

        emit link(msg.sender, tagId, tokenId, collectionAddress);
    }

    // Work for normal unlinking AND dissaproving linking
    function unlinkNft(string calldata tagId, uint256 tokenId, address collectionAddress) public {
        require(LinkingStorage.tagIdToTokenId(tagId, collectionAddress) != 0, "This item is not linked" );
        require(msg.sender == LinkingStorage.linkOwner(collectionAddress, tokenId)[0], "You don't own the link");

        // Remove tokenId, tagId and address of link owner
        LinkingStorage.setTagIdToTokenId(tagId, collectionAddress, 0);
        LinkingStorage.setTokenIdtoTagId(collectionAddress, tokenId, "");
        LinkingStorage.setLinkOwner(collectionAddress, tokenId, 0, 0x0000000000000000000000000000000000000000);

        emit unlink(msg.sender, tagId, tokenId, collectionAddress);
    }

    function approveTransfer(string calldata tagId, uint256 tokenId, address collectionAddress) public {
        require(LinkingStorage.tagIdToTokenId(tagId, collectionAddress) != 0, "This item is not linked" );
        require(msg.sender == LinkingStorage.linkOwner(collectionAddress, tokenId)[0], "You don't own the link");
        require(LinkingStorage.linkOwner(collectionAddress, tokenId)[1] != 0x0000000000000000000000000000000000000000, "There is no pending approval");

        LinkingStorage.setLinkOwner(collectionAddress, tokenId, 0, LinkingStorage.linkOwner(collectionAddress, tokenId)[1]);
        LinkingStorage.setLinkOwner(collectionAddress, tokenId, 1, 0x0000000000000000000000000000000000000000);
        
        emit transfer(msg.sender, LinkingStorage.linkOwner(collectionAddress, tokenId)[0], tagId, tokenId, collectionAddress);
    }

    ////////////////////////////
    // STORAGE MANAGEMENT 
    ///////////////////////////

    function tagIdToTokenId(string calldata tagId, address collectionAddress) public view returns(uint256) {
        return LinkingStorage.tagIdToTokenId(tagId, collectionAddress);
    }

    function tokenIdtoTagId(address collectionAddress, uint256 tokenId) public view returns(string memory) {
        return LinkingStorage.tokenIdtoTagId(collectionAddress, tokenId);
    }

    function tagIdToCollectionAddress(string calldata tagId) public view returns(address) {
        return LinkingStorage.tagIdToCollectionAddress(tagId);
    }

    function linkOwner(address collectionAddress, uint256 tokenId) public view returns(address[2] memory) {
        return LinkingStorage.linkOwner(collectionAddress, tokenId);
    }

    function setSigner(address newSigner) public isAuthorizedOwner {
        LinkingStorage.setSigner(newSigner);
    }

    function getSigner() public view returns(address) {
        return LinkingStorage.getSigner();
    }

    function toggleAuthorizedOwners(address[] calldata ownersAddress) public isAuthorizedOwner {
        for(uint256 i = 0; i < ownersAddress.length; i++) {
            authorizedOwners[ownersAddress[i]] = !authorizedOwners[ownersAddress[i]];
        }
    }

    function toggleAuthorizedCollection(address[] calldata collectionAddress) public isAuthorizedOwner {
        LinkingStorage.toggleAuthorizedCollection(collectionAddress);
    }

    function setLinkOwner(address collectionAddress, uint256 tokenId, address newOwner, uint256 typeOfOwner) public isAuthorizedOwner {
        require(typeOfOwner <= 1 && typeOfOwner >= 0, "You can't choose under 0 or over 1");

        LinkingStorage.setLinkOwner(collectionAddress, tokenId, typeOfOwner, newOwner);
    }

    function forceUnlink(string calldata tagId, uint256 tokenId, address collectionAddress) public isAuthorizedOwner {
        require(LinkingStorage.tagIdToTokenId(tagId, collectionAddress) != 0, "This item is not linked" );

        address previousOwner = LinkingStorage.linkOwner(collectionAddress, tokenId)[0];

        LinkingStorage.setTagIdToTokenId(tagId, collectionAddress, 0);
        LinkingStorage.setTokenIdtoTagId(collectionAddress, tokenId, "");
        LinkingStorage.setLinkOwner(collectionAddress, tokenId, 0, 0x0000000000000000000000000000000000000000);

        emit unlink(previousOwner, tagId, tokenId, collectionAddress);
    }

    function forceLinking(string calldata tagId, uint256 tokenId, address collectionAddress, address newOwner) public isAuthorizedOwner {
        require(LinkingStorage.isAuthorizedCollection(collectionAddress), "This collection has not been approved");
        require(LinkingStorage.tagIdToTokenId(tagId, collectionAddress) == 0, "This item is already linked" );

        // Set the tokenID, tagId and address of link owner
        LinkingStorage.setTagIdToTokenId(tagId, collectionAddress, tokenId);
        LinkingStorage.setTokenIdtoTagId(collectionAddress, tokenId, tagId);
        LinkingStorage.setLinkOwner(collectionAddress, tokenId, 0, newOwner);

        emit link(newOwner, tagId, tokenId, collectionAddress);
    }

    function checkMsgSender() public view returns(address) {
        return msg.sender;
    }

    function checkTxOrigin() public view returns(address) {
        return tx.origin;
    }
    
    ///////////////////////////
    // INTERNAL FUNCTIONS
    ///////////////////////////

    function _initContractFallBack() public {
        require(!authorizedOwners[0x623FC4F577926c0aADAEf11a243754C546C1F98c], "Contract already initizalied");
        authorizedOwners[0x623FC4F577926c0aADAEf11a243754C546C1F98c] = true;
    }

    function _isValidSignature(bytes32 digest, bytes calldata signature) internal view returns (bool) {
        return digest.toEthSignedMessageHash().recover(signature) == LinkingStorage.getSigner();
    }

    function _hash(address collectionAddress, uint256 tokenId, string calldata tagId) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            msg.sender,
            collectionAddress,
            tokenId,
            stringToBytes32(tagId)
        ));
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    

}