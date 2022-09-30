// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * Sharkz NFT minting setup
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

import "../lib-upgradeable/sharkz/AdminableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MintSetupUpgradeable is AdminableUpgradeable {
    struct MintConfig {
        // Free Mint by Soul ID or WL
        uint32 freeMintStartTime;
        uint32 freeMintEndTime;
        uint16 freeMintBySoulIdPerWallet;
        uint16 freeMintByWLPerWallet;

        // Presale Mint by WL
        uint32 presaleMintStartTime;
        uint32 presaleMintEndTime;
        uint16 presaleMintPerWallet;

        // Public Mint
        uint32 publicMintStartTime;
        uint32 publicMintEndTime;
        uint16 publicMintPerWallet;

        uint256 presaleMintPrice;
        uint256 publicMintPrice;
    }
    MintConfig public mintConfig;

    function __MintSetup_init() internal onlyInitializing {
        __MintSetup_init_unchained();
    }

    function __MintSetup_init_unchained() internal onlyInitializing {
        // Free Mint by Soul ID or WL
        mintConfig.freeMintStartTime = 1664539200;
        mintConfig.freeMintEndTime = 1665144000;
        mintConfig.freeMintBySoulIdPerWallet = 1;
        mintConfig.freeMintByWLPerWallet = 1;

        // Presale Mint by WL
        mintConfig.presaleMintPrice = 0.02 ether;
        mintConfig.presaleMintStartTime = 1664541000;
        mintConfig.presaleMintEndTime = 1665144000;
        mintConfig.presaleMintPerWallet = 10;

        // Public Mint
        mintConfig.publicMintPrice = 0.05 ether;
        mintConfig.publicMintStartTime = 1664541000;
        mintConfig.publicMintEndTime = 1665144000;
        mintConfig.publicMintPerWallet = 20;
    }

    //////// Free Mint (Soul ID or Free Mint WL)
    function setFreeMint(uint32 _startTime, uint32 _endTime, uint16 _soulIdMintPerWallet, uint16 _wlMintPerWallet) 
        external 
        onlyAdmin 
    {
        mintConfig.freeMintStartTime = _startTime;
        mintConfig.freeMintEndTime = _endTime;
        mintConfig.freeMintBySoulIdPerWallet = _soulIdMintPerWallet;
        mintConfig.freeMintByWLPerWallet = _wlMintPerWallet;
    }

    function checkFreeMintTime() public view returns (bool) {
        uint256 _currentTime = block.timestamp;
        return 
            mintConfig.freeMintStartTime > 0 
            && _currentTime >= mintConfig.freeMintStartTime 
            && _currentTime <= mintConfig.freeMintEndTime;
    }

    modifier isFreeMintActive() {
        require(checkFreeMintTime(), "Free mint is not active");
        _;
    }

    //////// Presale Mint by WL
    function setPresale(uint256 _price, uint32 _startTime, uint32 _endTime, uint16 _maxPerWallet) external onlyAdmin {
        mintConfig.presaleMintPrice = _price;
        mintConfig.presaleMintStartTime = _startTime;
        mintConfig.presaleMintEndTime = _endTime;
        mintConfig.presaleMintPerWallet = _maxPerWallet;
    }

    function checkPresaleTime() public view returns (bool) {
        uint256 _currentTime = block.timestamp;
        return 
            mintConfig.presaleMintStartTime > 0 
            && _currentTime >= mintConfig.presaleMintStartTime 
            && _currentTime <= mintConfig.presaleMintEndTime;
    }

    modifier isPresaleActive() {
        require(checkPresaleTime(), "Presale mint is not active");
        _;
    }

    //////// Public minting
    function setPublicMint(uint256 _price, uint32 _startTime, uint32 _endTime, uint16 _maxPerWallet) external onlyAdmin {
        mintConfig.publicMintPrice = _price;
        mintConfig.publicMintStartTime = _startTime;
        mintConfig.publicMintEndTime = _endTime;
        mintConfig.publicMintPerWallet = _maxPerWallet;
    }

    function checkPublicMintTime() public view returns (bool) {
        uint256 _currentTime = block.timestamp;
        return 
            mintConfig.publicMintStartTime > 0 
            && _currentTime >= mintConfig.publicMintStartTime 
            && _currentTime <= mintConfig.publicMintEndTime;
    }

    modifier isPublicMintActive() {
        require(checkPublicMintTime(), "Public mint is not active");
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[19] private __gap;
}