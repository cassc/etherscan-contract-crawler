// SPDX-License-Identifier: MIT
// base64.tech
pragma solidity ^0.8.13;

import "./solmate/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./Base64.sol";

/*

██▄   █▄▄▄▄ ▄███▄   ██   █▀▄▀█   ▄███▄      ▄  ▄███▄   
█  █  █  ▄▀ █▀   ▀  █ █  █ █ █   █▀   ▀ ▀▄   █ █▀   ▀  
█   █ █▀▀▌  ██▄▄    █▄▄█ █ ▄ █   ██▄▄     █ ▀  ██▄▄    
█  █  █  █  █▄   ▄▀ █  █ █   █   █▄   ▄▀ ▄ █   █▄   ▄▀ 
███▀    █   ▀███▀      █    █  █ ▀███▀  █   ▀▄ ▀███▀   
▀                     █    ▀             ▀             
                     ▀        
*/
contract DreamExe is  DefaultOperatorFilterer, ERC721, Ownable, Pausable
{
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 200;
    uint256 public constant TOKEN_PRICE = .035 ether;
    uint256 public constant MAX_PER_WALLET = 2;

    bytes32 public provenanceHash;
    IDreamsExeMetadata public metadataAddress;
    address signatureVerifier;
    uint256 public totalSupply;

    struct Ordinal {
        uint256 inscriptionNum;
        string inscriptionId;
    }

    mapping(uint256 => address) public allowList;
    mapping(uint256 => uint256) public tokenIdToInscriptionNum;
    mapping(uint256 => string) public tokenIdToInscriptionId;
    mapping(uint256 => bool) public inscriptionNumMinted;
    mapping(string => bool) public inscriptionIdMinted;
    mapping(address => uint256) public addressToNumMinted;
    
    constructor() 
    {   
        __ERC721_init("DreamExe", "DREAMEXE");
        _pause();
    }

    modifier hasValidSignature(bytes memory _signature, bytes memory message) {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(message));
        if(messageHash.recover(_signature) != signatureVerifier) revert UnrecognizableHash();
       
        _;
    }

    function mint(bytes memory _signature, Ordinal memory _ordinal) 
        public
        whenNotPaused 
        payable
        hasValidSignature(_signature, abi.encodePacked(msg.sender, _ordinal.inscriptionNum, _ordinal.inscriptionId))
    {
        if(msg.value < TOKEN_PRICE) revert NotEnoughEthSent(); 
        if(inscriptionNumMinted[_ordinal.inscriptionNum]) revert InscriptionNumAlreadyMinted();
        if(inscriptionIdMinted[_ordinal.inscriptionId]) revert InscriptionIdAlreadyMinted();
        if(addressToNumMinted[msg.sender] + 1 > MAX_PER_WALLET) revert MaxTokensPerWalletAlreadyMinted();
        if(totalSupply + 1 > MAX_SUPPLY ) revert ExceedsMaxSupply();

        tokenIdToInscriptionNum[totalSupply] = _ordinal.inscriptionNum;
        tokenIdToInscriptionId[totalSupply] = _ordinal.inscriptionId;
        inscriptionNumMinted[_ordinal.inscriptionNum] = true;
        inscriptionIdMinted[_ordinal.inscriptionId] = true;

        _mint(msg.sender, totalSupply);
        addressToNumMinted[msg.sender]++;

        totalSupply++;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (_tokenId >= totalSupply) revert ("URIQueryForNonexistentToken");

        return metadataAddress.getMetadata(_tokenId, tokenIdToInscriptionNum[_tokenId], tokenIdToInscriptionId[_tokenId]);
    }

    function getAllInscriptionNumMinted() public view returns(uint256[] memory) {
        uint256[] memory allInscriptionNumMinted = new uint256[](totalSupply);

        for (uint256 i; i < totalSupply; i++) {
            allInscriptionNumMinted[i] = tokenIdToInscriptionNum[i];
        }

        return allInscriptionNumMinted;
    }

    function getAllInscriptionIdMinted() public view returns(string[] memory) {
        string[] memory allInscriptionIdMinted = new string[](totalSupply);

        for (uint256 i; i < totalSupply; i++) {
            allInscriptionIdMinted[i] = tokenIdToInscriptionId[i];
        }

        return allInscriptionIdMinted;
    }

    /** Override for operator filter registy */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from,
        address to,
        uint256 id,
        bytes calldata data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, id, data);
    }

    /*** Owner functions ***/
    function ownerMintToAddress(address _recipient, uint256 _numTokens)
        external
        onlyOwner
    {
        if(totalSupply + _numTokens > MAX_SUPPLY ) revert ExceedsMaxSupply();
        
        for(uint256 i; i < _numTokens; i++) {
            _mint(_recipient, totalSupply);
            totalSupply++;
        }
    }

    function setInscriptionNumToTokenId(uint256 _inscriptionNum, uint256 _tokenId) 
        external
        onlyOwner
    {
        if(tokenIdToInscriptionNum[_tokenId] != 0) revert CantSetIfMappingAlreadyExists();

        tokenIdToInscriptionNum[_tokenId] = _inscriptionNum;
    }

    function setInscriptionIdToTokenId(string memory _inscriptionId, uint256 _tokenId) 
        external
        onlyOwner
    {
        if(bytes(tokenIdToInscriptionId[_tokenId]).length != 0) revert CantSetIfMappingAlreadyExists();

        tokenIdToInscriptionId[_tokenId] = _inscriptionId;
    }

    function setMetadataAddress(address _address) external onlyOwner
    {
        metadataAddress = IDreamsExeMetadata(_address);
    }

    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        signatureVerifier = _signatureVerifier;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function setProvenanceHash(bytes32 _provenanceHash) external onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}

interface IDreamsExeMetadata{ 
    function getMetadata(uint256 _tokenId, uint256 inscriptionNum, string memory _inscriptionId) external view returns (string memory);
}

error ExceedsMaxSupply();
error UnrecognizableHash();
error InscriptionNumAlreadyMinted();
error CantSetIfMappingAlreadyExists();
error InscriptionIdAlreadyMinted();
error NotEnoughEthSent();
error MaxTokensPerWalletAlreadyMinted();