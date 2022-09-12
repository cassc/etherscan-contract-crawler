// The official MaxTrax Token
// Version 1.0.1
// See website: https://MaxTrax.app
// SPDX-License-Identifier: MIT

// Proudly created by CPI Technologies GmbH
// https://cpitech.io

pragma solidity ^0.8.0;

interface IMaxTrax {

    event EthersWithdrawn(address indexed operator, address indexed to, uint amount);

    event AuthNFTMinted(address indexed receiver, address indexed signer, uint id);
    event AuthNFTUpdated(address indexed owner, address indexed signer, string ipfsPath);
    event EmergencyInvalidatorSet(address indexed owner, address invalidator);
    event AuthNFTInvalidated(uint id, string reason);
    event AuthNFTSignerAdded(address indexed signer, string name);
    event AuthNFTSignerInvalidated(address indexed signer, string name, uint256 timestamp);
    event AuthNFTTransfered(address indexed operator, address indexed receiver, address indexed twoFAsigner, uint id);


    // User functions
    /*
        Mints a NFT token. Only possible with a signature of a registered signer
    */
    function mintAuthNFT(address signer, string memory username, string memory ipfsPath, uint8 v, bytes32 r, bytes32 s) external returns(uint);

    /*
        Updates the own NFT. A Signature is required to do so.
    */
    function updateAuthNFT(address signer, string memory ipfsPath, uint tokenId, uint8 v, bytes32 r, bytes32 s) external;

    /**
        This will set a ERC721 or ERC1155 token as your profile picture
    */
    function setProfilePicture(address erc721, address erc1155, uint256 tokenId) external;

    /**
        This will update your username
    */
    function changeUsername(string memory username) external;

    // Invalidation and emergency addresses
    /**
        Warning: This can not be reverted!
    */
    function invalidateMyNFT() external;

    /*
        For each MaxTrax NFT it is possible to set an emergency address. In case you can't access your address anymore, e.g.
        your device was stolen and you want to avoid your identity to be used by the thief, the emergency address can
        invalidate your NFT for you with this function.
    */
    function emergencyInvalidateNFT(address ownerToInvalidate) external;

    /*
    For each MaxTrax NFT it is possible to set an emergency address. In case you can't access your address anymore, e.g.
        your device was stolen and you want to avoid your identity to be used by the thief, the emergency address can
        invalidate your NFT for you. With this function you can set this address. Warning: This can be done only once!
    */
    function setEmergencyAddressForever(address emergencyAddress) external;

    // DAO functions
    function toggleMintingEnabled(bool enabled) external;

    function addChallengeProvider(address signer, string memory name, string memory configUrl, string memory url) external;

    /**
        Invalidated signers can't mint new NFTs or update them
    */
    function invalidateChallengeProvider(address signer) external;

    /**
        Owner only: Invalidate NFTs in case of identity theft (emergency use only)
    */
    function ownerInvalidateNFTs(uint[] calldata tokenIDs, string memory reason) external;

    // View functions
    function mintingEnabled() external view returns(bool);

    function mintedBy(address addr) external view returns(uint);

    function hasMinted(address addr) external view returns(bool);

    function getProfilePictureToken(uint tokenID) external view returns(string memory);

    function addressHasValidNFT(address addr) external view returns(bool);

    function hasEmergencyAddress(uint tokenID) external view returns(bool);

    function getEmergencyAddress(uint tokenID) external view returns(address);

    function checkInvalidated(uint tokenID) external view returns (bool);

    function getUsername(uint tokenID) external view returns (string memory);

    function canSign(address signer) external view returns (bool);

    function canSignAt(address signer, uint256 timestamp) external view returns (bool);

    function getChallengeProviders() external view returns(address[] memory);

    function getChallengeProviderName(address signer) external view returns (string memory);

    function getChallengeProviderUrl(address signer) external view returns (string memory);

    function getChallengeProviderConfigUrl(address signer) external view returns (string memory);

    function signatureValid(address signer, string memory hash, uint8 v, bytes32 r, bytes32 s) external view returns (bool);
}