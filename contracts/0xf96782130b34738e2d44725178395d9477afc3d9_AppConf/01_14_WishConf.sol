// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../libs/Permission.sol";
import "./interfaces/IAppConf.sol";

contract AppConf is IAppConf, Ownable {

    address burnAddr;
    address coolAddr;
    address donateAddr;
    address incenseAddr;

    mapping(address => uint8) blacklistMap;
    mapping(address => uint8) whitelistMap;

    address nftFactoryAddr;
    address redeemNftToken;

    address granNftToken;
    uint8 grantNftGen = 2;

    // token -> status, 1=enabled, 0=disabled
    mapping(address => uint8) redeemTokenMap;

    mapping(address => uint8) nftTokenToTypeMap;
    mapping(uint8 => address) nftTypeToTokenMap;

    uint256 incenseMinAmount = 1000000000000000;
    uint256 incenseMaxAmount = 20000000000000000000;

    constructor() {
        burnAddr = 0x000000000000000000000000000000000000dEaD;
        coolAddr = 0x813071130aB7fFf091F130FbdE356B51FbD33e9B;
        donateAddr = 0x813071130aB7fFf091F130FbdE356B51FbD33e9B;
        incenseAddr = 0x813071130aB7fFf091F130FbdE356B51FbD33e9B;

        // incense & donate token
        redeemTokenMap[address(0)] = 1;

         // nft token
        address damoNft = 0x17595Dad3a25a1CBE98FdA8EDf63606d248cC1Df;
        address wishDamoNft = 0xb3d8C2b03555E312B54645b33b4fFCB82e268188;

        // nft factory
        nftFactoryAddr = 0xbDE1b7619071F5782abaE9CdA9E4420Fa5dD9Ecb;

        // redeem & grant nft token
        redeemNftToken = wishDamoNft;
        granNftToken = wishDamoNft;

        // nft token to type
        nftTokenToTypeMap[damoNft] = 1;
        nftTokenToTypeMap[wishDamoNft] = 2;

        // nft type to token
        nftTypeToTokenMap[1] = damoNft;
        nftTypeToTokenMap[2] = wishDamoNft;
    }

    function validBlacklist(address addr) external view override returns(bool) {
        return blacklistMap[addr] == 1;
    }

    function validWhitelist(address addr) external view override returns(bool) {
        return whitelistMap[addr] == 1;
    }

    function setBlacklist(address[] calldata addrs, uint8 status) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            blacklistMap[addrs[i]] = status;
        }
    }

    function setWhitelist(address[] calldata addrs, uint8 status) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelistMap[addrs[i]] = status;
        }
    }

    function setBurnAddr(address _burnAddr) external onlyOwner {
        burnAddr = _burnAddr;
    }

    function getBurnAddr() external view override returns(address) {
        return burnAddr;
    }

    function setCoolAddr(address _coolAddr) external onlyOwner {
        coolAddr = _coolAddr;
    }

    function getCoolAddr() external view override returns (address) {
        return coolAddr;
    }

    function setDonateAddr(address _donateAddr) external onlyOwner {
        donateAddr = _donateAddr;
    }

    function getDonateAddr() external view override returns(address) {
        return donateAddr;
    }

    function getIncenseAddr() external view override returns(address) {
        return incenseAddr;
    }

    function setIncenseAddr(address _incenseAddr) external onlyOwner {
        incenseAddr = _incenseAddr;
    }

    function setRedeemNftToken(address _redeemNftToken) external onlyOwner {
        redeemNftToken = _redeemNftToken;
    }

    function getRedeemNftToken() external view override returns(address) {
        return redeemNftToken;
    }

    function setGrantNftGen(uint8 gen) external onlyOwner {
        grantNftGen = gen;
    }

    function getGrantNftGen() external view override returns(uint8) {
        return grantNftGen;
    }

    function setRedeemToken(address redeemToken, uint8 status) external onlyOwner {
        redeemTokenMap[redeemToken] = status;
    }

    function validRedeemToken(address redeemToken) external view override returns(bool) {
        return redeemTokenMap[redeemToken] == 1;
    }

    function setNftFactoryAddr(address _nftFactoryAddr) external onlyOwner {
        nftFactoryAddr = _nftFactoryAddr;
    }

    function getNftFactoryAddr() external view override returns(address) {
        return nftFactoryAddr;
    }

    function setGrantNftToken(address _granNftToken) external onlyOwner {
        granNftToken = _granNftToken;
    }

    function getGrantNftToken() external view override returns(address) {
        return granNftToken;
    }

    function setNftTokenType(address nftToken, uint8 nftType) external onlyOwner {
        nftTokenToTypeMap[nftToken] = nftType;
        nftTypeToTokenMap[nftType] = nftToken;
    }

    function getNftTokenType(address nftToken) external view override returns(uint8) {
        return nftTokenToTypeMap[nftToken];
    }

    function getNftTypeToken(uint8 nftType) external view override returns(address) {
        return nftTypeToTokenMap[nftType];
    }

    function setIncenseMinAmount(uint256 _incenseMinAmount) external onlyOwner {
        incenseMinAmount = _incenseMinAmount;
    }

    function getIncenseMinAmount() external view override returns(uint256) {
        return incenseMinAmount;
    }

    function setIncenseMaxAmount(uint256 _incenseMaxAmount) external onlyOwner {
        incenseMaxAmount = _incenseMaxAmount;
    }

    function getIncenseMaxAmount() external view override returns(uint256) {
        return incenseMaxAmount;
    }
}