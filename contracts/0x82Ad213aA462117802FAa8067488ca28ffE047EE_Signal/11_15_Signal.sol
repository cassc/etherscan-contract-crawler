// SPDX-License-Identifier: MIT
// base64.tech
pragma solidity ^0.8.13;

import "./erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./BTC721.sol";
import "./Base64.sol";

/*
*/
contract Signal is BTC721, ERC721A("Signal","SIGNAL"), DefaultOperatorFilterer,  Ownable, Pausable
{
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant TOKEN_PRICE = .05 ether;
    uint256 public constant PHASE_1_MAX_PER_WALLET = 1;
    uint256 public constant PHASE_2_MAX_PER_WALLET = 2;

    ISignalMetadata public metadataContract;
    IDreamExeContract public dreamExeContract;
    MintPhase public mintPhase;

    bool public traitsLocked;
    mapping(bytes => bool) public signatureUsed;
    mapping(uint256 => bool) public dreamTokenClaimed;

    address signatureVerifier;

    enum MintPhase {
        PHASE_1,
        PHASE_2
    }

    constructor(IDreamExeContract _address) 
    {
        _pause();
        dreamExeContract = _address;
    }

    modifier hasValidSignature(bytes memory _signature, bytes memory _message) {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(_message));
        if(messageHash.recover(_signature) != signatureVerifier) revert UnrecognizableHash();
        if(signatureUsed[_signature]) revert SignatureAlreadyUsed();

        signatureUsed[_signature] = true;
        _;
    }

    modifier callerIsUser() {
        if(tx.origin != msg.sender) revert CallerIsAnotherContract();
        _;
    }

    function claim(address _mintTo, uint256[] memory _dreamTokenIds) 
        public
        whenNotPaused 
        callerIsUser()
     {
        uint256 totalToClaim = _dreamTokenIds.length;
        if(totalSupply() + totalToClaim > MAX_SUPPLY) revert ExceedsMaxSupply();

        for(uint256 i; i < _dreamTokenIds.length; i++) {
            uint256 dreamTokenId = _dreamTokenIds[i];
            if(dreamTokenClaimed[dreamTokenId]) revert DreamTokenAlreadyClaimed();
            if(dreamExeContract.ownerOf(dreamTokenId) != _mintTo) revert MsgSenderDoesNotOwnThisDreamToken();

            dreamTokenClaimed[dreamTokenId] = true;
        }

        _mint(_mintTo, totalToClaim);
    }

    function mint(bytes memory _signature, address _mintTo, uint256 _nonce) 
        public
        whenNotPaused 
        payable
        callerIsUser()
        hasValidSignature(_signature, abi.encodePacked(_mintTo, _nonce))
    {
        if(msg.value < TOKEN_PRICE) revert NotEnoughEthSent(); 
        
        uint64 numberMinted = _getAux(_mintTo);
        if(mintPhase == MintPhase.PHASE_1 && numberMinted + 1 > PHASE_1_MAX_PER_WALLET) 
            revert MaxTokensPerWalletAlreadyMintedForCurrentPhase();
        else if(mintPhase == MintPhase.PHASE_2 && numberMinted + 1 > PHASE_2_MAX_PER_WALLET) 
            revert MaxTokensPerWalletAlreadyMintedForCurrentPhase();
        
        if(totalSupply() + 1 > MAX_SUPPLY) revert ExceedsMaxSupply();

        _mint(_mintTo, 1);
        _setAux(_mintTo, ++numberMinted);
    }

    function setTokenIdToOrdinalAndTraits(bytes memory _signature, uint256 _tokenId, Ordinal memory _ordinal, uint32[8] memory _traits) 
        external
        hasValidSignature(_signature, abi.encodePacked(msg.sender, _ordinal.inscriptionId, _tokenId))
    {
        if(ownerOf(_tokenId) != msg.sender) revert UserIsNotOwnerOfToken();

        _setTokenIdToOrdinal(_tokenId, _ordinal);
        _setTokenIdToTraits(_tokenId, _traits);
    }

    function getAllInscriptionIdMinted() public view returns(string[] memory) {
        string[] memory allInscriptionIdMinted = new string[](totalSupply());

        for (uint256 i; i < totalSupply(); i++) {
            allInscriptionIdMinted[i] = tokenIdToOrdinal[i].inscriptionId;
        }

        return allInscriptionIdMinted;
    }

    function getNumAllowListMinted(address _address) public view returns(uint64) {
        return _getAux(_address);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        return metadataContract.getMetadata(_tokenId, getOrdinal(_tokenId), getTraits(_tokenId));
    }

    /** Override for operator filter registy */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    )   public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to,tokenId, _data);
    }

    /*** Owner functions ***/

    function setMintPhase(MintPhase _phase) external onlyOwner {
        if(_phase > MintPhase.PHASE_2) revert InvalidPhase();

        mintPhase = _phase;
    }

    function lockTraits() external onlyOwner {
        traitsLocked = true;
    }

    function ownerMintToAddress(address _recipient, uint256 _numTokens)
        external
        onlyOwner
    {
        if(totalSupply() + _numTokens > MAX_SUPPLY ) revert ExceedsMaxSupply();
        
        _mint(_recipient, _numTokens);
    }

    function ownerSetTokenIdToOrdinalAndTraits(uint256 _tokenId, Ordinal memory _ordinal, uint32[8] memory _traits) 
        external
        onlyOwner
    {
        _setTokenIdToOrdinal(_tokenId, _ordinal);
        _setTokenIdToTraits(_tokenId, _traits);
    }

    function updateTraits(uint256 _tokenId, uint32[8] memory _traits) 
        external
        onlyOwner
    {
        if(traitsLocked) revert TraitsAreLocked();

        _setTokenIdToTraits(_tokenId, _traits);
    }

    function setMetadataContract(address _address) external onlyOwner
    {
        metadataContract = ISignalMetadata(_address);
    }

    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        signatureVerifier = _signatureVerifier;
    }

    function setFilteringEnabled(bool _value) public onlyOwner {
        _setFilteringEnabled(_value);
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}

interface ISignalMetadata{ 
    function getMetadata(uint256 _tokenId, Ordinal memory _ordinal, uint32[8] memory _traits) external view returns (string memory);
}

interface IDreamExeContract{ 
    function ownerOf(uint256 tokenId) external view returns (address);
}


error ExceedsMaxSupply();
error UnrecognizableHash();
error CantSetIfMappingAlreadyExists();
error NotEnoughEthSent();
error MaxTokensPerWalletAlreadyMintedForCurrentPhase();
error SignatureAlreadyUsed();
error UserIsNotOwnerOfToken();
error DreamTokenAlreadyClaimed();
error CallerIsAnotherContract();
error MsgSenderDoesNotOwnThisDreamToken();
error InvalidPhase();
error TraitsAreLocked();