// SPDX-License-Identifier: MIT
// bali.xyz
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./ERC721NonTransferrableUpgradeable.sol";
import "./Errors.sol";


contract Engram is ERC721NonTransferrableUpgradeable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using ECDSAUpgradeable for bytes32;
    
    IMetadataContract metadataContract;
    address signatureVerifier;
    uint256 tokenCount;
    mapping(address => bool) public addressHasMinted;
    mapping(address => uint256) public addressToTokenId;

    bool private initialized;
    

    function initialize() public initializer {
        if(initialized) revert ContractAlreadyInitialized();
        __ERC721_init("Engram", "ENGRAM");
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        _pause();
    }

    modifier hasValidSignature(bytes memory _signature, bytes memory message) {
        bytes32 messageHash = ECDSAUpgradeable.toEthSignedMessageHash(keccak256(message));
        if(messageHash.recover(_signature) != signatureVerifier) revert UnrecognizableHash();
       
        _;
    }

    // _username is an optional parameter
    function mint(bytes memory _signature, bytes memory _encryptedEncryptedPrivateIdentifier, string memory _username) 
        public
        whenNotPaused 
        hasValidSignature(_signature, abi.encodePacked(msg.sender))
    {
        if(addressHasMinted[msg.sender]) revert TokenAlreadyMinted();

        addressHasMinted[msg.sender] = true;
        addressToTokenId[msg.sender] = tokenCount;
        metadataContract.setTokenIdToEncryptedPrivateIdentifier(msg.sender, tokenCount, _encryptedEncryptedPrivateIdentifier);
        if(bytes(_username).length > 0) {
            metadataContract.setUsername(msg.sender, tokenCount, _username);
        }

        _mint(msg.sender, tokenCount);
        
        tokenCount++;
    }

    function claimUsername(bytes memory _signature,  uint256 _tokenId, string memory _username)
        public
        whenNotPaused
        hasValidSignature(_signature, abi.encodePacked(msg.sender, _tokenId, _username))
    {
        if(msg.sender != ownerOf(_tokenId)) revert SenderDoesNotOwnToken();
        metadataContract.setUsername(msg.sender, _tokenId, _username);
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        if (id >= tokenCount) revert ("URIQueryForNonexistentToken");

        return metadataContract.getMetadata(id);
    }

    function setMetdataContract(address _address) 
        external
        onlyOwner
    {
        metadataContract = IMetadataContract(_address);
    }

    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        signatureVerifier = _signatureVerifier;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

interface IMetadataContract {
    function setTokenIdToEncryptedPrivateIdentifier(address _address, uint256 _tokenId, bytes memory _encryptedEncryptedPrivateIdentifier) external;
    function setUsername(address _address, uint256 _tokenId, string memory _name) external;
    function getMetadata(uint256 _tokenId)  external view returns(string memory);
}