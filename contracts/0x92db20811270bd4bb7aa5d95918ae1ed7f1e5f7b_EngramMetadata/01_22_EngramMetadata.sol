// SPDX-License-Identifier: MIT
// bali.xyz
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./Base64.sol";
import "./Errors.sol";

contract EngramMetadata is OwnableUpgradeable, UUPSUpgradeable
{
    using StringsUpgradeable for uint256;
    
    string public baseImageURL;    
    mapping(address => VersionedEncryptedPrivateIdentifier) public addressToEncryptedPrivateIdentifier;
    mapping(address => bool) contractAddressIsAdmin;
    mapping(bytes => bool) public encryptedEncryptedPrivateIdentifierExists;

    mapping(string => address) public usernameToAddress;
    mapping(uint256 => address) public tokenIdToAddress;
    mapping(uint256 => string) public tokenIdToUsername;
    mapping(address => string) public addressToUsername;

    event UsernameClaimed(string username, uint256 tokenId, address);
    event UsernameDropped(string username, uint256 tokenId, address);

    struct VersionedEncryptedPrivateIdentifier {
        bytes encryptedEncryptedPrivateIdentifier;
        uint256 nonce;
        string version;
    }

    bool private initialized;

    function initialize() public initializer {
        if(initialized) revert ContractAlreadyInitialized();

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    modifier callerIsAllowed() {
        if(!contractAddressIsAdmin[msg.sender] && msg.sender != owner()) revert CallerNotAdmin();
        _;
    }

    function setUsername(address _address, uint256 _tokenId, string memory _username) 
        external 
        callerIsAllowed()
    {
        if(bytes(tokenIdToUsername[_tokenId]).length != 0) {
            string memory usernameToDrop = tokenIdToUsername[_tokenId];
            delete usernameToAddress[usernameToDrop];
            emit UsernameDropped(usernameToDrop, _tokenId, _address);
        }
        if(usernameToAddress[_username] != address(0)) revert NameNotUnique();

        tokenIdToUsername[_tokenId] = _username;
        usernameToAddress[_username] = _address;
        addressToUsername[_address] = _username;

        emit UsernameClaimed(_username, _tokenId, _address);
    }

    function setTokenIdToEncryptedPrivateIdentifier(address _tokenOwner, uint256 _tokenId, bytes memory _encryptedEncryptedPrivateIdentifier) 
        public 
        callerIsAllowed()
    {
        if(addressToEncryptedPrivateIdentifier[_tokenOwner].encryptedEncryptedPrivateIdentifier.length != 0) revert HashAlreadySet();
        if(tokenIdToAddress[_tokenId] != address(0)) revert TokenIdAlreadySet();
        if(encryptedEncryptedPrivateIdentifierExists[_encryptedEncryptedPrivateIdentifier]) revert IdentifierNotUnique();
        
        addressToEncryptedPrivateIdentifier[_tokenOwner] = VersionedEncryptedPrivateIdentifier( _encryptedEncryptedPrivateIdentifier, 0, "1.0");
        tokenIdToAddress[_tokenId] = _tokenOwner;
        encryptedEncryptedPrivateIdentifierExists[_encryptedEncryptedPrivateIdentifier] = true;
    }

    function updateEncryptedPrivateIdentifier(address _tokenOwner, bytes memory _encryptedEncryptedPrivateIdentifier, uint256 _newNonce, string memory _version) public callerIsAllowed(){
        if(addressToEncryptedPrivateIdentifier[_tokenOwner].nonce >= _newNonce) revert NewNonceNeedsToBeLargerThanPreviousNonce();

        addressToEncryptedPrivateIdentifier[_tokenOwner].nonce = _newNonce;
        addressToEncryptedPrivateIdentifier[_tokenOwner].encryptedEncryptedPrivateIdentifier = _encryptedEncryptedPrivateIdentifier;
        addressToEncryptedPrivateIdentifier[_tokenOwner].version = _version;
    }

    function getEncryptedPrivateIdentifierFromTokenId(uint256 _tokenId) public view returns(VersionedEncryptedPrivateIdentifier memory) {
        return addressToEncryptedPrivateIdentifier[tokenIdToAddress[_tokenId]];
    }

    function setBaseImageURL(string memory _url) public onlyOwner {
        baseImageURL = _url;
    }

    function getMetadata(uint256 _tokenId) public view returns (string memory) {
       
        bytes memory metadata = abi.encodePacked(
                        '{"name":"Engram #',
                        _tokenId.toString(),
                        '","description":"This soulbound token stores your decentralized user profile","attributes":[{"trait_type":"Username","value":"',
                        tokenIdToUsername[_tokenId],
                        '"}], "image": "',
                        baseImageURL,
                        //_tokenId.toString(), ".json"
                        '"}'
        );
        
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(metadata)));
    }

    function addAddressToAdmin(address _address) public onlyOwner {
        contractAddressIsAdmin[_address] = true;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}