// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IMunicipality.sol";
import "./interfaces/ISinglePool.sol";
import "./interfaces/IGymNetwork.sol";
import "./interfaces/IMining.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IAlpaca.sol";
import "./interfaces/IGymFarming.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IPancakePair.sol";

contract Aggregator is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct PoolInfo {
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    address public miningAddress;
    address public gymNetworkAddress;
    address public municipalityAddress;
    address public municipalityKBAddress;
    address public singlPoolAddress;
    address public farmingAddress;
    address public factoryAddress;
    address public BUSDAddress;
    address public BNBAddress;

    function initialize(
        address _miningAddress,
        address _gymNetworkAddress,
        address _municipalityAddress,
        address _municipalityKBAddress
        ) external initializer {
        miningAddress = _miningAddress;
        gymNetworkAddress = _gymNetworkAddress;
        municipalityAddress = _municipalityAddress;
        municipalityKBAddress = _municipalityKBAddress;
        __Ownable_init();
    }

    function setContractAddresses(address[5] calldata _contractAddresses) external onlyOwner {
        miningAddress = _contractAddresses[0];
        singlPoolAddress = _contractAddresses[1];
        gymNetworkAddress = _contractAddresses[2];
        municipalityAddress = _contractAddresses[3];
        municipalityKBAddress = _contractAddresses[4];
    }

    function setTokenAddresses(address[4] calldata _tokenAddresses) external onlyOwner {
        BUSDAddress = _tokenAddresses[0];
        BNBAddress = _tokenAddresses[1];
        farmingAddress = _tokenAddresses[2];
        factoryAddress = _tokenAddresses[3];
    }
    
    function getUserMinerRewards(address _user) external view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 userTotalHashpower = IMunicipality(municipalityAddress).minerInf(_user).totalHash + IMunicipality(municipalityKBAddress).minerInf(_user).totalHash;
        uint256 userMiners = userTotalHashpower / 1000;
        uint256 claimedRewards = IMining(miningAddress).userInfo(_user).totalClaims;
        uint256 pendingRewards = IMining(miningAddress).pendingReward(_user);
        uint256 globalTotalHashpower = IMining(miningAddress).totalHashRate();
        uint256 userShares = IMining(miningAddress).userInfo(_user).totalHashRate;
        uint256 gymnetPrice = IGYMNETWORK(gymNetworkAddress).getGYMNETPrice();
        return (userMiners, userTotalHashpower, claimedRewards, pendingRewards, globalTotalHashpower, userShares, gymnetPrice);
    } 

    function getBalances(address[] memory _tokens, address _user) external view returns (uint256, uint256[] memory) {
        uint256[] memory nftBalance = new uint256[](_tokens.length);
        for(uint8 i; i < _tokens.length; ++i) {
            nftBalance[i] = IERC20Upgradeable(_tokens[i]).balanceOf(_user);
        }
        return(_user.balance, nftBalance);
    }

    function getVaultData(address _user) external view 
    returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256,uint256,uint256,uint256,bool,bool, IVault.UserInfo memory, IVault.UserInfo memory) {
        // uint256 gymnetPrice = IVault(0x916ee43Ac5F338364986B9AA86f7962a5779d0a1).getGYMNETPrice();
        uint256 BNBPoolTotalShares = IAlpaca(0x14a5d9b9b9B37A28b1BaD07229FaD4C3b44De8a5).sharesTotal();
        uint256 BUSDPoolTotalShares = IAlpaca(0xD296aeD3644a8e27888d2e645e4B788D20dadC0B).sharesTotal();
        uint256 vaultsRewardPerBlockWEI = IVault(0x916ee43Ac5F338364986B9AA86f7962a5779d0a1).getRewardPerBlock();

        uint256 alpacaRewardsBNB = IAlpaca(0x14a5d9b9b9B37A28b1BaD07229FaD4C3b44De8a5).pendingReward(_user);
        uint256 alpacaRewardsBUSD = IAlpaca(0xD296aeD3644a8e27888d2e645e4B788D20dadC0B).pendingReward(_user);

        uint256 BNBPoolDepositAmountWEI = IVault(0x916ee43Ac5F338364986B9AA86f7962a5779d0a1).userInvestment(0,_user);
        uint256 BUSDPoolDepositAmountWEI = IVault(0x916ee43Ac5F338364986B9AA86f7962a5779d0a1).userInvestment(1,_user);
         
        uint256 BNBPoolPendingRewardsWEI = IVault(0x916ee43Ac5F338364986B9AA86f7962a5779d0a1).pendingReward(0,_user);
        uint256 BUSDPoolPendingRewardsWEI = IVault(0x916ee43Ac5F338364986B9AA86f7962a5779d0a1).pendingReward(1,_user);
         
        uint256 totalDepositUSDInAllVaults = IVault(0x916ee43Ac5F338364986B9AA86f7962a5779d0a1).getUserDepositDollarValue(_user);
        bool isEmailVerified = IVault(0x916ee43Ac5F338364986B9AA86f7962a5779d0a1).isEmailVerified(_user);
        bool hasInvestment = IVault(0x916ee43Ac5F338364986B9AA86f7962a5779d0a1).getUserInvestment(_user);
        IVault.UserInfo memory userInfo0 = IVault(0x916ee43Ac5F338364986B9AA86f7962a5779d0a1).userInfo(0, _user);
        IVault.UserInfo memory userInfo1 = IVault(0x916ee43Ac5F338364986B9AA86f7962a5779d0a1).userInfo(1, _user);

        return (
            BNBPoolTotalShares, 
            BUSDPoolTotalShares,
            vaultsRewardPerBlockWEI,
            alpacaRewardsBNB,
            alpacaRewardsBUSD,
            BNBPoolDepositAmountWEI,
            BUSDPoolDepositAmountWEI,
            BNBPoolPendingRewardsWEI,
            BUSDPoolPendingRewardsWEI,
            totalDepositUSDInAllVaults,
            isEmailVerified,
            hasInvestment,
            userInfo0,
            userInfo1
        );
    } 

    function getSinglePool(address _user) external view returns(PoolInfo memory, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, ISinglePool.UserInfo memory) {
        PoolInfo memory poolInfo = PoolInfo({lastRewardBlock: ISinglePool(singlPoolAddress).poolInfo().lastRewardBlock, accRewardPerShare: ISinglePool(singlPoolAddress).poolInfo().accRewardPerShare});
        uint256 rewardPerBlock = ISinglePool(singlPoolAddress).getRewardPerBlock();
        uint256 totalGymnetLocked = ISinglePool(singlPoolAddress).totalGymnetLocked();
        uint256 totalGGymnetInPoolLocked = ISinglePool(singlPoolAddress).totalGGymnetInPoolLocked();
        uint256 totalGymnetUnlocked = ISinglePool(singlPoolAddress).totalGymnetUnlocked();
        uint256 gymnetPrice = IGYMNETWORK(gymNetworkAddress).getGYMNETPrice();
        uint256 totalClaimtInPool = ISinglePool(singlPoolAddress).totalClaimtInPool();
        uint256 totalLockedTokens = ISinglePool(singlPoolAddress).totalLockedTokens(_user);
        uint256 userTotalGGymnetLocked = ISinglePool(singlPoolAddress).userTotalGGymnetLocked(_user);
        ISinglePool.UserInfo memory userInfo = ISinglePool(singlPoolAddress).userInfo(_user);
        
        return (poolInfo,
        rewardPerBlock,
        totalGymnetLocked,
        totalGGymnetInPoolLocked,
        totalGymnetUnlocked,
        gymnetPrice,
        totalClaimtInPool,
        totalLockedTokens,
        userTotalGGymnetLocked,
        userInfo
        );
    }

    function getFarmingData(address _user) external view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, IGymFarming.UserInfo memory, IGymFarming.UserInfo memory) {
        IPancakePair GymBNBPair = IPancakePair(IPancakeFactory(factoryAddress).getPair(gymNetworkAddress, BNBAddress));
        IPancakePair GymBUSDPair = IPancakePair(IPancakeFactory(factoryAddress).getPair(gymNetworkAddress, BUSDAddress));
        uint256 RewardPerBlock = IGymFarming(farmingAddress).getRewardPerBlock();
        uint256 gBNBLp = GymBNBPair.totalSupply();
        (uint256 reserve0BN, uint256 reserve1BN, ) = GymBNBPair.getReserves();
        uint256 gBNBLpTotal = GymBNBPair.totalSupply();
        uint256 gBUSDLp = GymBUSDPair.totalSupply();
        (uint256 reserve0BD, uint256 reserve1BD, ) = GymBUSDPair.getReserves();
        uint256 gBUSDLpTotal = GymBUSDPair.totalSupply();
        uint256 pendingRewardBNB = IGymFarming(farmingAddress).pendingReward(0, _user);
        uint256 pendingRewardBUSD = IGymFarming(farmingAddress).pendingReward(1, _user);
        IGymFarming.UserInfo memory userInfoBNB = IGymFarming(farmingAddress).userInfo(0,_user);
        IGymFarming.UserInfo memory userInfoBUSD = IGymFarming(farmingAddress).userInfo(1,_user);

        return(RewardPerBlock,
        gBNBLp,
        reserve0BN,
        reserve1BN,
        gBNBLpTotal,
        gBUSDLp,
        reserve0BD,
        reserve1BD,
        gBUSDLpTotal,
        pendingRewardBNB,
        pendingRewardBUSD,
        userInfoBNB,
        userInfoBUSD
        );

    }

}