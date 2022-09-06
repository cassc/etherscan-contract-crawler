// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../market/pausable/PausableImplementation.sol";
import "./IAddressProvider.sol";

contract AddressProvider is PausableImplementation, IAddressProvider {
    
    address public adminRegistry;
    address public protocolRegistry;
    address public priceConsumer;
    address public claimTokenContract;
    address public gTokenFactory;
    address public liquidator;
    address public tokenMarketRegistry;
    address public tokenMarket;
    address public nftMarket;
    address public networkMarket;
    address public govToken;
    address public govTier;
    address public govGovToken;
    address public govNFTTier;
    address public govVCTier;
    address public userTier;

    function initialize() external initializer {
        __Ownable_init();
    }

    /// @dev function to set the admin registry contract
    /// @param _adminRegistry admin registry contract

    function setAdminRegistry(address _adminRegistry) external onlyOwner {
        require(_adminRegistry != address(0), "zero address");
        adminRegistry = _adminRegistry;
    }

    /// @dev function to set the prootocol registry contract
    /// @param _protocolRegistry protocol registry contract

    function setProtocolRegistry(address _protocolRegistry) external onlyOwner {
        require(_protocolRegistry != address(0), "zero address");
        protocolRegistry = _protocolRegistry;
    }

    /// @dev function to set the tier level contract
    /// @param _tierLevel tier level contract

    function setUserTier(address _tierLevel) external onlyOwner {
        require(_tierLevel != address(0), "zero address");
        userTier = _tierLevel;
    }

    /// @dev function to set the price consumer contract
    /// @param _priceConsumer price consumer contract

    function setPriceConsumer(address _priceConsumer) external onlyOwner {
        require(_priceConsumer != address(0), "zero address");
        priceConsumer = _priceConsumer;
    }

    /// @dev function to set the claim token contract
    /// @param _claimToken claim token contract
    function setClaimToken(address _claimToken) external onlyOwner {
        require(_claimToken != address(0), "zero address");
        claimTokenContract = _claimToken;
    }

    /// @dev function to set gov synthetic token factory contract
    /// @param _gTokenFactory contract address of gToken factory
    function setGTokenFacotry(address _gTokenFactory) external onlyOwner {
        require(_gTokenFactory != address(0), "zero address");
        gTokenFactory = _gTokenFactory;
    }

    /// @dev function to set liquidator contract
    /// @param _liquidator contract address of liquidator
    function setLiquidator(address _liquidator) external onlyOwner {
        require(_liquidator != address(0), "zero address");
        liquidator = _liquidator;
    }

    /// @dev function to set token market registry contract
    /// @param _marketRegistry contract address of liquidator
    function setTokenMarketRegistry(address _marketRegistry)
        external
        onlyOwner
    {
        require(_marketRegistry != address(0), "zero address");
        tokenMarketRegistry = _marketRegistry;
    }

    /// @dev function to set token market contract
    /// @param _tokenMarket contract address of token market
    function setTokenMarket(address _tokenMarket) external onlyOwner {
        require(_tokenMarket != address(0), "zero address");
        tokenMarket = _tokenMarket;
    }

    /// @dev function to set nft market contract
    /// @param _nftMarket contract address of token market
    function setNftMarket(address _nftMarket) external onlyOwner {
        require(_nftMarket != address(0), "zero address");
        nftMarket = _nftMarket;
    }

    /// @dev function to set network market contract
    /// @param _networkMarket contract address of the network loan market
    function setNetworkMarket(address _networkMarket) external onlyOwner {
        require(_networkMarket != address(0), "zero address");
        networkMarket = _networkMarket;
    }

    /// @dev function to set gov token address
    /// @param _govToken contract address of the gov token
    function setGovToken(address _govToken) external onlyOwner {
        require(_govToken != address(0), "zero address");
        govToken = _govToken;
    }

    /// @dev function to set gov tier address
    /// @param _govTier contract address of the gov tier
    function setGovtier(address _govTier) external onlyOwner {
        require(_govTier != address(0), "zero address");
        govTier = _govTier;
    }

    /// @dev function to set govGovToken address
    /// @param _govGovToken gov synthetic token address
    function setgovGovToken(address _govGovToken) external onlyOwner {
        require(_govGovToken != address(0), "zero address");
        govGovToken = _govGovToken;
    }

    /// @dev function to set the gov nft tier address
    /// @param _govNftTier gov nft tier contract address
    function setGovNFTTier(address _govNftTier) external onlyOwner {
        require(_govNftTier != address(0), "zero address");
        govNFTTier = _govNftTier;
    }

    /// @dev function to set the gov vc nft tier address
    /// @param _govVCTier gov vc nft tier contract address
    function setVCNFTTier(address _govVCTier) external onlyOwner {
        require(_govVCTier != address(0), "zero address");
        govVCTier = _govVCTier;
    }

    /**
    @dev getter functions to get all the GOV Protocol Contracts
    */

    /// @dev get the gov admin registry contract address
    /// @return address returns the contract address
    function getAdminRegistry() external view override returns (address) {
        return adminRegistry;
    }

    /// @dev get the gov protocol contract address
    /// @return address returns the contract address
    function getProtocolRegistry() external view override returns (address) {
        return protocolRegistry;
    }

    /// @dev get the gov tier level contract address
    /// @return address returns the contract address
    function getUserTier() external view override returns (address) {
        return userTier;
    }

    /// @dev get the gov price consumer contract address
    /// @return address return the contract address
    function getPriceConsumer() external view override returns (address) {
        return priceConsumer;
    }

    /// @dev get the claim token contract address
    /// @return address return the contract address
    function getClaimTokenContract() external view override returns (address) {
        return claimTokenContract;
    }

    /// @dev get the gtokenfactory contract address
    /// @return address return the contract address
    function getGTokenFactory() external view override returns (address) {
        return gTokenFactory;
    }

    /// @dev get the gov liquidator contract address
    /// @return address returns the contract address
    function getLiquidator() external view override returns (address) {
        return liquidator;
    }

    /// @dev get the token market registry contract address
    /// @return address returns the contract address
    function getTokenMarketRegistry() external view override returns (address) {
        return tokenMarketRegistry;
    }

    /// @dev get the token market contract address
    /// @return address returns the contract address
    function getTokenMarket() external view override returns (address) {
        return tokenMarket;
    }

    /// @dev get the nft market contract address
    /// @return address returns the contract address
    function getNftMarket() external view override returns (address) {
        return nftMarket;
    }

    /// @dev get the network market contract address
    /// @return address returns the contract address

    function getNetworkMarket() external view override returns (address) {
        return networkMarket;
    }

    /// @dev get the gov token contract address
    /// @return address returns the contract address

    function govTokenAddress() external view override returns (address) {
        return govToken;
    }

    /// @dev get the gov tier contract address
    /// @return address returns the contract address
    function getGovTier() external view override returns (address) {
        return govTier;
    }

    /// @dev get the gov synthetic token
    /// @return address returns the contract address
    function getgovGovToken() external view override returns (address) {
        return govGovToken;
    }

    /// @dev get the gov nft tier address;
    /// @return address returns the contract address
    function getGovNFTTier() external view override returns (address) {
        return govNFTTier;
    }

    /// @dev get the gov nc nft tier address
    function getVCTier() external view override returns (address) {
        return govVCTier;
    }
}