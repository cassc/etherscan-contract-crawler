// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../libs/Permission.sol";
import "./interfaces/IAppConf.sol";

contract AppConf is IAppConf, Ownable {

    address burnAddr;
    address coolAddr;

    mapping(address => uint8) blacklistMap;
    mapping(address => uint8) whitelistMap;

    // nfttoken -> status, 1=enabled
    mapping(address => uint8) stakingNftTokenMap; // for staking
    address nftFactoryAddr; //

    address rewardNftToken; // for reward

    // gen -> reward amount
    mapping(uint8 => uint256) rewardAmountMap;

    uint8 rewardNftTokenGen = 1; // nft token gen
    uint8 rewardType = Model.REWARD_TYPE_FIXED; // 1=fixed, 2=cycled

    // gen -> seconds, reward period, 0 is not reward
    mapping(uint8 => uint256) rewardPeriodMap;

    uint256 constant SECONDS_IN_DAY = 86400;

    mapping(address => uint8) private farmAddrMap;

    Model.FarmAddr farmAddr;

    mapping(address => uint8) nftTokenToTypeMap;
    mapping(uint8 => address) nftTypeToTokenMap;

    // claim by contract
    bool private enabledProxyClaim = true;

    constructor() {
        burnAddr = 0x000000000000000000000000000000000000dEaD;
        coolAddr = 0x813071130aB7fFf091F130FbdE356B51FbD33e9B;

        // reward period
        rewardPeriodMap[1] = 2 * SECONDS_IN_DAY;
        rewardPeriodMap[2] = 4 * SECONDS_IN_DAY;

        // reward amount
        rewardAmountMap[1] = 1;
        rewardAmountMap[2] = 1;

        // farm address
        address farmStakingAddr = 0xE369980135e38E043d356a2D1a34A04Ec506D01c;
        address farmRewardAddr = 0xb6719e5ed97c1d0149Af8B25Cb4dBd7A5c8aa5Cc;

        farmAddr = Model.FarmAddr(farmStakingAddr, farmRewardAddr);
        farmAddrMap[farmAddr.farmStakingAddr] = 1;
        farmAddrMap[farmAddr.farmRewardAddr] = 1;

        // nft token
        address damoNft = 0x16BA4669969de40Ac917444Ec27D67ad41E7aFc9;
        address wishDamoNft = 0x1Ef19a4434BCB9f8cf10C9A40F1ecDbA6Bc8bAD1;

        // nft factory
        nftFactoryAddr = 0x963A9Ae4981E27C31e5D3E7e7Be99211f4a0158b;

        // reward nft token
        rewardNftToken = wishDamoNft;   

        // nft token to type
        nftTokenToTypeMap[damoNft] = 1;
        nftTokenToTypeMap[wishDamoNft] = 2;

        // nft type to token
        nftTypeToTokenMap[1] = damoNft;
        nftTypeToTokenMap[2] = wishDamoNft;

        // stake nft token
        stakingNftTokenMap[damoNft] = 1;
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

    function setStakingNftToken(address nftToken, uint8 status) external onlyOwner {
        stakingNftTokenMap[nftToken] = status;
    }

    function validStakingNftToken(address nftToken) external view override returns(bool) {
        return stakingNftTokenMap[nftToken] == 1;
    }

    function setNftFactoryAddr(address _nftFactoryAddr) external onlyOwner {
        nftFactoryAddr = _nftFactoryAddr;
    }

    function getNftFactoryAddr() external view override returns(address) {
        return nftFactoryAddr;
    }

    function setRewardNftToken(address _rewardNftToken) external onlyOwner {
        rewardNftToken = _rewardNftToken;
    }

    function getRewardNftToken() external view override returns(address) {
        return rewardNftToken;
    }

    function setRewardNftTokenGen(uint8 _rewardNftTokenGen) external onlyOwner {
        rewardNftTokenGen = _rewardNftTokenGen;
    }

    function getRewardNftTokenGen() external view returns(uint8) {
        return rewardNftTokenGen;
    }

    function getRewardPeriod(uint8 gen) external view override returns(uint256) {
        return rewardPeriodMap[gen];
    }

    function setRewardPeriod(uint8 gen, uint256 period) external onlyOwner {
        rewardPeriodMap[gen] = period;
    }

    function setRewardAmount(uint8 gen, uint256 rewardAmount) external onlyOwner {
        rewardAmountMap[gen] = rewardAmount;
    }

    function getRewardAmount(uint8 gen) external view override returns(uint256) {
        return rewardAmountMap[gen];
    }

    function setRewardType(uint8 _rewardType) external onlyOwner {
        rewardType = _rewardType;
    }

    function getRewardType() external view returns(uint8) {
        return rewardType;
    }

    function setFarmAddr(Model.FarmAddr calldata _farmAddr) external onlyOwner {
        farmAddr = _farmAddr;
        farmAddrMap[farmAddr.farmStakingAddr] = 1;
        farmAddrMap[farmAddr.farmRewardAddr] = 1;
    }

    function getFarmAddr() external view returns(Model.FarmAddr memory) {
        return farmAddr;
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

    function setFarmAddr(address[] calldata farmAddrs, uint8 status) external onlyOwner {
        for (uint256 index = 0; index < farmAddrs.length; index++) {
            farmAddrMap[farmAddrs[index]] = status;
        }
    }

    function validFarm(address addr) external view override returns (bool) {
        return farmAddrMap[addr] == 1;
    }

    function getEnabledProxyClaim() external view override returns(bool) {
        return enabledProxyClaim;
    }

    function setEnabledProxyClaim(bool _enabledProxyClaim) external onlyOwner {
        enabledProxyClaim = _enabledProxyClaim;
    }
}