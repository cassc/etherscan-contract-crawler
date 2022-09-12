// The official MaxTrax Token
// Version 1.0.1
// See website: https://MaxTrax.me
// SPDX-License-Identifier: MIT

// Proudly developed by CPI Technologies GmbH
// https://cpitech.io

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IMaxTrax.sol";

contract MaxTrax is ERC721, Ownable, IMaxTrax {

    using Strings for uint;
    using Address for address;
    using Address for address payable;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    struct MaxTraxNFT {
        address minter;
        string ipfsPath;
        bool invalidated;
        address emergencyInvalidator;
        string username;
        address profilePictureERC721Address;
        address profilePictureERC1155Address;
        uint256 profilePictureTokenId;
    }

    struct MaxTraxChallengeProvider {
        string name;
        string url;
        string configUrl;
        uint256 registrationTimestamp;
        uint256 invalidationTimestamp;
    }

    // Token data
    mapping(address => uint) private _mintings;
    mapping(uint => MaxTraxNFT) _MaxTraxNFTs;

    // Challenge Provider data
    address[] _registeredChallengeProviders;
    mapping(address => MaxTraxChallengeProvider) private _challengeProviders;

    bool private _mintingEnabled = true;
    string private constant _metaPath = "ipfs://";

    constructor() ERC721("MaxTrax 1.1.0", "MaxTrax") {
    }


    modifier requireCanSign(address signer) {
        require(this.canSign(signer), "MaxTrax: This signer is not valid! Please repeat the process!");
        _;
    }

    modifier requireSenderHasMinted() {
        require(this.hasMinted(msg.sender), "MaxTrax: You don't have minted yet an MaxTrax token!");
        _;
    }

    modifier requireSignatureValid(address signer, string memory hash, uint8 v, bytes32 r, bytes32 s) {
        require(recoverSigner(hash, v, r, s) == signer, "MaxTrax: Wrong signature");
        _;
    }

    // User functions
    /*
        Mints a NFT token. Only possible with a signature of a registered signer
    */
    function mintAuthNFT(address signer, string memory username, string memory ipfsPath, uint8 v, bytes32 r, bytes32 s) public override
    requireCanSign(signer)
    requireSignatureValid(signer, ipfsPath, v, r, s)
    returns(uint) {
        // Prevent double minting
        require(!hasMinted(msg.sender), "MaxTrax: You have already minted a MaxTrax token. To do changes, please update your MaxTrax token!");
        require(_mintingEnabled, "MaxTrax: Minting is currently disabled. Please try again later");

        // Mint token
        _tokenIds.increment();
        uint newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _mintings[msg.sender] = newTokenId;

        MaxTraxNFT storage MaxTraxNFT = _MaxTraxNFTs[newTokenId];

        _MaxTraxNFTs[newTokenId].ipfsPath = ipfsPath;
        _MaxTraxNFTs[newTokenId].username = username;
        _MaxTraxNFTs[newTokenId].invalidated = false;
        _MaxTraxNFTs[newTokenId].minter = msg.sender;
        _MaxTraxNFTs[newTokenId].profilePictureERC721Address = address(this);
        _MaxTraxNFTs[newTokenId].profilePictureTokenId = newTokenId;

        // Emit Event
        emit AuthNFTMinted(msg.sender, signer, newTokenId);

        return newTokenId;
    }

    /*
        Updates the own NFT. A Signature is required to do so.
    */
    function updateAuthNFT(address signer, string memory ipfsPath, uint tokenId, uint8 v, bytes32 r, bytes32 s) public override
    requireSignatureValid(signer, ipfsPath, v, r, s)
    requireSenderHasMinted
    requireCanSign(signer)
    {
        require(msg.sender == this.ownerOf(tokenId), "MaxTrax: You are not the owner of this token!");
        require(!this.checkInvalidated(tokenId), "MaxTrax: This token was invalidated!");

        // Set updated IPFS Path
        _MaxTraxNFTs[tokenId].ipfsPath = ipfsPath;

        // Emit Event
        emit AuthNFTUpdated(msg.sender, signer, ipfsPath);
    }

    /**
        This will set a ERC721 or ERC1155 token as your profile picture
    */
    function setProfilePicture(address erc721, address erc1155, uint256 tokenId) public override {
        require(hasMinted(msg.sender), "MaxTrax: You don't have minted yet an MaxTrax token!");
        require(erc721 == address(0) || erc1155 == address(0), "MaxTrax: Please provide only ERC721 or ERC1151 contract for profile picture");
        uint id = this.mintedBy(msg.sender);

        _MaxTraxNFTs[id].profilePictureTokenId = tokenId;
        _MaxTraxNFTs[id].profilePictureERC721Address = erc721;
        _MaxTraxNFTs[id].profilePictureERC1155Address = erc1155;
    }

    /**
        This will update your username
    */
    function changeUsername(string memory username) public override requireSenderHasMinted {
        uint id = this.mintedBy(msg.sender);
        _MaxTraxNFTs[id].username = username;
    }

    // Invalidation and emergency addresses
    /**
        Warning: This can not be reverted!
    */
    function invalidateMyNFT() public override requireSenderHasMinted {
        // Get current tokenID
        uint tokenID = this.mintedBy(msg.sender);

        // Do invalidation
        invalidateNFT(tokenID, "Self-invalidation");
    }

    /*
        For each MaxTrax NFT it is possible to set an emergency address. In case you can't access your address anymore, e.g.
        your device was stolen and you want to avoid your identity to be used by the thief, the emergency address can
        invalidate your NFT for you with this function.
    */
    function emergencyInvalidateNFT(address ownerToInvalidate) public override {
        // Get current tokenID
        uint tokenID = this.mintedBy(ownerToInvalidate);

        // Check if the current sender is allowed to invalidate the NFT of the given address
        require(_MaxTraxNFTs[tokenID].emergencyInvalidator == msg.sender, "MaxTrax: You are not the emergency address for this owner!");

        // Do invalidation
        invalidateNFT(tokenID, "Emergency invalidation");
    }

    /*
    For each MaxTrax NFT it is possible to set an emergency address. In case you can't access your address anymore, e.g.
        your device was stolen and you want to avoid your identity to be used by the thief, the emergency address can
        invalidate your NFT for you. With this function you can set this address. Warning: This can be done only once!
    */
    function setEmergencyAddressForever(address emergencyAddress) public override requireSenderHasMinted {
        require(emergencyAddress != msg.sender, "MaxTrax: You can't chose your own address!");

        // Get current tokenID
        uint tokenID = this.mintedBy(msg.sender);

        // Can only be set once!
        require(_MaxTraxNFTs[tokenID].emergencyInvalidator == address(0), "MaxTrax: You already have set your emergency address. This can be done only once. Please check our FAQs!");

        // Set emergency address
        _MaxTraxNFTs[tokenID].emergencyInvalidator = emergencyAddress;

        // Emit event
        emit EmergencyInvalidatorSet(msg.sender, emergencyAddress);
    }

    // DAO functions
    function toggleMintingEnabled(bool enabled) external onlyOwner override {
       _mintingEnabled = enabled;
    }

    function addChallengeProvider(address signer, string memory name, string memory configUrl, string memory url) external onlyOwner override {
        require(_challengeProviders[signer].registrationTimestamp == 0, "MaxTrax: Signer already exists");

        MaxTraxChallengeProvider storage challengeProvider = _challengeProviders[signer];

        _challengeProviders[signer].name = name;
        _challengeProviders[signer].registrationTimestamp = block.timestamp;
        _challengeProviders[signer].configUrl = configUrl;
        _challengeProviders[signer].url = url;

        _registeredChallengeProviders.push(signer);

        emit AuthNFTSignerAdded(signer, name);
    }

    /**
        Invalidated signers can't mint new NFTs or update them
    */
    function invalidateChallengeProvider(address signer) external onlyOwner override {
        require(_challengeProviders[signer].registrationTimestamp > 0, "MaxTrax: Signer does not exist");
        require(_challengeProviders[signer].invalidationTimestamp == 0, "MaxTrax: Signer already invalidated");
        _challengeProviders[signer].invalidationTimestamp = block.timestamp;

        emit AuthNFTSignerInvalidated(signer, _challengeProviders[signer].name, block.timestamp);
    }

    /**
        Owner only: Invalidate NFTs in case of identity theft (emergency use only)
    */
    function ownerInvalidateNFTs(uint[] calldata tokenIDs, string memory reason) external onlyOwner override {
        for (uint i = 0; i < tokenIDs.length; i++) {
            invalidateNFT(tokenIDs[i], "Self-invalidation");
        }
    }

    // View functions
    function mintingEnabled() external view override returns(bool) {
        return _mintingEnabled;
    }

    function mintedBy(address addr) public view override returns(uint) {
        return _mintings[addr];
    }

    function hasMinted(address addr) public view override returns(bool) {
        return _exists(_mintings[addr]);
    }

    function getProfilePictureToken(uint tokenID) public view override returns(string memory) {
        if(_MaxTraxNFTs[tokenID].profilePictureERC721Address != address(0)) {
            return IERC721Metadata(_MaxTraxNFTs[tokenID].profilePictureERC721Address).tokenURI(_MaxTraxNFTs[tokenID].profilePictureTokenId);
        } else if(_MaxTraxNFTs[tokenID].profilePictureERC1155Address != address(0)) {
            return IERC1155MetadataURI(_MaxTraxNFTs[tokenID].profilePictureERC1155Address).uri(_MaxTraxNFTs[tokenID].profilePictureTokenId);
        } else {
            return "";
        }
    }

    function addressHasValidNFT(address addr) public view override returns(bool) {
        return hasMinted(addr) && !checkInvalidated(mintedBy(addr));
    }

    function hasEmergencyAddress(uint tokenID) public view override returns(bool) {
        return _MaxTraxNFTs[tokenID].emergencyInvalidator != address(0);
    }

    function getEmergencyAddress(uint tokenID) public view override returns(address) {
        return _MaxTraxNFTs[tokenID].emergencyInvalidator;
    }

    function checkInvalidated(uint tokenID) public view override returns (bool) {
        return _MaxTraxNFTs[tokenID].invalidated;
    }

    function getUsername(uint tokenID) public view override returns (string memory) {
        return _MaxTraxNFTs[tokenID].username;
    }

    function canSign(address signer) public view override returns (bool) {
        return _challengeProviders[signer].registrationTimestamp > 0
            && _challengeProviders[signer].invalidationTimestamp == 0;
    }

    function canSignAt(address signer, uint256 timestamp) public view override returns (bool) {
        return _challengeProviders[signer].registrationTimestamp > 0
            && (_challengeProviders[signer].invalidationTimestamp == 0
                || _challengeProviders[signer].invalidationTimestamp > timestamp)
            && _challengeProviders[signer].registrationTimestamp < timestamp;
    }

    function getChallengeProviders() public view override returns(address[] memory) {
        return _registeredChallengeProviders;
    }

    function getChallengeProviderName(address signer) public view override returns (string memory) {
        return _challengeProviders[signer].name;
    }

    function getChallengeProviderUrl(address signer) public view override returns (string memory) {
        return _challengeProviders[signer].url;
    }

    function getChallengeProviderConfigUrl(address signer) public view override returns (string memory) {
        return _challengeProviders[signer].configUrl;
    }

    function signatureValid(address signer, string memory hash, uint8 v, bytes32 r, bytes32 s) external view override returns (bool) {
        return recoverSigner(hash, v, r, s) == signer;
    }

    /**
        Get the URL of the Metadata on ipfs
    */
    function tokenURI(uint tokenID) public view virtual override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");
        require(!this.checkInvalidated(tokenID), "MaxTrax: This token is invalidated!");

        return string(abi.encodePacked(_metaPath, _MaxTraxNFTs[tokenID].ipfsPath));
    }

    function withdrawEthers(uint amount, address payable to) public virtual onlyOwner {
        to.sendValue(amount);
        emit EthersWithdrawn(_msgSender(), to, amount);
    }

    function recoverSigner(string memory message, uint8 v, bytes32 r, bytes32 s) public pure returns (address signer) {
        string memory header = "\x19Ethereum Signed Message:\n000000";

        uint256 lengthOffset;
        uint256 length;
        assembly {
            length := mload(message)
            lengthOffset := add(header, 57)
        }

        require(length <= 999999);
        uint256 lengthLength = 0;
        uint256 divisor = 100000;
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }

            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;

            assembly {
                mstore8(lengthOffset, digit)
            }
        }

        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }

        assembly {
            mstore(header, lengthLength)
        }

        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    // Internal functions
    function invalidateNFT(uint tokenID, string memory reason) internal {
        require(_exists(tokenID), "MaxTrax: Invalidate request for non-existent token");
        _MaxTraxNFTs[tokenID].invalidated = true;
        emit AuthNFTInvalidated(tokenID, reason);
    }

    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function strcmp(string memory a, string memory b) internal pure returns(bool){
        return memcmp(bytes(a), bytes(b));
    }

    // Override default functions to disable transfer feature
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(false, "MaxTrax: Transfering Auth-NFTs is not possible! Please check our FAQs");
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(false, "MaxTrax: Transfering Auth-NFTs is not possible! Please check our FAQs");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(false, "MaxTrax: Transfering Auth-NFTs is not possible! Please check our FAQs");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(false, "MaxTrax: Transfering Auth-NFTs is not possible! Please check our FAQs");
    }

    function approve(address to, uint256 tokenId) public virtual override {
        require(false, "MaxTrax: Transfering Auth-NFTs is not possible! Please check our FAQs");
    }
}