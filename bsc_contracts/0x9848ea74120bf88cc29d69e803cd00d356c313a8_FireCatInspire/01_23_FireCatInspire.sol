// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {IFireCatRegistryProxy} from "../src/interfaces/IFireCatRegistryProxy.sol";
import {IFireCatYieldBoots} from "../src/interfaces/IFireCatYieldBoots.sol";
import {IFireCatNFT} from "../src/interfaces/IFireCatNFT.sol";
import {IFireCatNFTStake} from "../src/interfaces/IFireCatNFTStake.sol";
import {IFireCatReserves} from "../src/interfaces/IFireCatReserves.sol";
import {IFireCatInspire} from "../src/interfaces/IFireCatInspire.sol";
import {FireCatTransfer} from "../src/utils/FireCatTransfer.sol";
import {ModifyControl} from "../src/utils/ModifyControl.sol";


/**
 * @title FireCat's FireCatInspire contract
 * @notice main: claim
 * @author FireCat Finance
 */
contract FireCatInspire is IFireCatInspire, ModifyControl, FireCatTransfer {
    IFireCatNFT fireCatNFT;
    IFireCatNFTStake fireCatNFTStake;
    IFireCatRegistryProxy fireCatRegistryProxy;
    IFireCatReserves fireCatReserves;
    IFireCatYieldBoots fireCatYieldBoots;
    using SafeMath for uint256;

    event Claimed(address user_, uint256 actualClaimedAmount_, uint256 claimed_);
    event SetInviterRate(uint256 inviterRate_);
    event SetSuperiorRate(uint256 superiorRate_);
    event SetRewardToken(address rewardToken_);
    event SetFireCatNFT(address fireCatNFTAddress_);
    event SetFireCatNFTStake(address fireCatNFTStakeAddress_);
    event SetFireCatReserves(address fireCatReservesAddress_);
    event SetFireCatRegistryProxy(address fireCatRegistryProxyAddress_);
    event SetFireCatYieldBoots(address fireCatYieldBootsAddress_);
    event YieldBootsShare(uint256 restAmount, uint256 actualInviterReward, uint256 actualSuperiorReward);
    event NftLevelUpShare(uint256 restAmount, uint256 actualInviterReward, uint256 actualSuperiorReward);

    address public rewardToken;
    address public fireCatNFTAddress;
    address public fireCatNFTStakeAddress;
    address public fireCatReservesAddress;
    address public fireCatRegistryProxyAddress;
    address public fireCatYieldBootsAddress;
    
    uint256 public inviterRate;
    uint256 public superiorRate;  // inviter's inviter
    uint256 public totalClaimed;

    mapping(address => uint256) public claimed;

    mapping(address => uint256) private _yieldReward;
    mapping(address => uint256) private _yieldRewardClaimed;
    mapping(address => uint256) private _nftLevelUpReward;
    mapping(address => uint256) private _nftLevelUpRewardClaimed;

    function initialize() initializer public {
        __AccessControl_init();
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @inheritdoc IFireCatInspire
    function yieldRewardOf(address user_) public view returns (uint256, uint256, uint256) {
        uint256 totalReward = _yieldReward[user_];
        uint256 userClaimed = _yieldRewardClaimed[user_];
        return (
            totalReward.sub(userClaimed),
            userClaimed,
            totalReward
        );
    }

    /// @inheritdoc IFireCatInspire
    function nftLevelUpRewardOf(address user_) public view returns (uint256, uint256, uint256) {
        uint256 totalReward = _nftLevelUpReward[user_];
        uint256 userClaimed = _nftLevelUpRewardClaimed[user_];
        return (
            totalReward.sub(userClaimed),
            userClaimed,
            totalReward
        );
    }

    function getReward(uint256 rate_, uint256 amount_) internal returns (uint256) {
        return amount_.mul(rate_).div(1e9);
    }

    /// @inheritdoc IFireCatInspire
    function setInviterRate(uint256 inviterRate_) external onlyRole(DATA_ADMIN) {
        inviterRate = inviterRate_;
        emit SetInviterRate(inviterRate_);
    }

    /// @inheritdoc IFireCatInspire
    function setSuperiorRate(uint256 superiorRate_) external onlyRole(DATA_ADMIN) {
        superiorRate = superiorRate_;
        emit SetSuperiorRate(superiorRate_);
    }

    /// @inheritdoc IFireCatInspire
    function setRewardToken(address rewardToken_) external onlyRole(DATA_ADMIN) {
        rewardToken = rewardToken_;
        emit SetRewardToken(rewardToken_);
    }

    /// @inheritdoc IFireCatInspire
    function setFireCatNFT(address fireCatNFTAddress_) external onlyRole(DATA_ADMIN) {
        fireCatNFTAddress = fireCatNFTAddress_;
        fireCatNFT = IFireCatNFT(fireCatNFTAddress_);
        emit SetFireCatNFT(fireCatNFTAddress_);
    }

    /// @inheritdoc IFireCatInspire
    function setFireCatNFTStake(address fireCatNFTStakeAddress_) external onlyRole(DATA_ADMIN) {
        fireCatNFTStakeAddress = fireCatNFTStakeAddress_;
        fireCatNFTStake = IFireCatNFTStake(fireCatNFTStakeAddress_);
        emit SetFireCatNFTStake(fireCatNFTStakeAddress_);
    }

    /// @inheritdoc IFireCatInspire
    function setFireCatReserves(address fireCatReservesAddress_) external onlyRole(DATA_ADMIN) {
        fireCatReservesAddress = fireCatReservesAddress_;
        fireCatReserves = IFireCatReserves(fireCatReservesAddress_);
        emit SetFireCatReserves(fireCatReservesAddress_);
    }

    /// @inheritdoc IFireCatInspire
    function setFireCatRegistryProxy(address fireCatRegistryProxyAddress_) external onlyRole(DATA_ADMIN) {
        fireCatRegistryProxyAddress = fireCatRegistryProxyAddress_;
        fireCatRegistryProxy = IFireCatRegistryProxy(fireCatRegistryProxyAddress_);
        emit SetFireCatRegistryProxy(fireCatRegistryProxyAddress_);
    }

    /// @inheritdoc IFireCatInspire
    function setFireCatYieldBoots(address fireCatYieldBootsAddress_) external onlyRole(DATA_ADMIN) {
        fireCatYieldBootsAddress = fireCatYieldBootsAddress_;
        fireCatYieldBoots = IFireCatYieldBoots(fireCatYieldBootsAddress_);
        emit SetFireCatYieldBoots(fireCatYieldBootsAddress_);
    }

    /// @inheritdoc IFireCatInspire
    function withdrawRemaining(address token, address to, uint256 amount) external nonReentrant onlyRole(SAFE_ADMIN) returns (uint256) {
        return withdraw(token, to, amount);
    }

    /// @inheritdoc IFireCatInspire
    function yieldBootsShare(address user_, uint256 amount_) external onlyRole(FIRECAT_GATE) returns (uint256) {
        uint256 actualInviterReward;
        uint256 actualSuperiorReward;

        uint256 userStaked = fireCatYieldBoots.stakedOf(user_);

        // share with inviter
        address inviter = fireCatRegistryProxy.getInviter(user_);
        if (fireCatYieldBoots.stakedOf(inviter) > userStaked) {
            actualInviterReward = doTransferIn(rewardToken, msg.sender, getReward(inviterRate, amount_));
            _yieldReward[inviter] = _yieldReward[inviter].add(actualInviterReward);
        }
        
        // share with superior
        address superior = fireCatRegistryProxy.getInviter(inviter);
        uint256 superiorReward = getReward(superiorRate, amount_);
        if (superior != address(0) && fireCatYieldBoots.stakedOf(superior) > userStaked) {
            actualSuperiorReward = doTransferIn(rewardToken, msg.sender, superiorReward);
            _yieldReward[superior] = _yieldReward[superior].add(actualSuperiorReward);
        }

        uint256 restAmount = amount_.sub(actualInviterReward).sub(actualSuperiorReward);
        emit YieldBootsShare(restAmount, actualInviterReward, actualSuperiorReward);
        return restAmount;
    }

    /// @inheritdoc IFireCatInspire
    function nftLevelUpShare(address user_, uint256 tokenId_, uint256 amount_) external onlyRole(FIRECAT_GATE) returns (uint256) {
        uint256 actualInviterReward;
        uint256 actualSuperiorReward;

        uint256 userTokenLevel = fireCatNFT.tokenLevelOf(tokenId_);

        // share with inviter
        address inviter = fireCatRegistryProxy.getInviter(user_);
        if (fireCatNFTStake.isStaked(inviter)) {
            // nft must be staked
            uint256 inviterTokenId = fireCatNFTStake.stakedOf(inviter);
            uint256 inviterTokenLevel = fireCatNFT.tokenLevelOf(inviterTokenId);

            if (inviterTokenLevel >= userTokenLevel) {
                actualInviterReward = doTransferIn(rewardToken, msg.sender, getReward(inviterRate, amount_));
                _nftLevelUpReward[inviter] = _nftLevelUpReward[inviter].add(actualInviterReward);
            }
        }

        // share with superior
        address superior = fireCatRegistryProxy.getInviter(inviter);
        uint256 superiorReward = getReward(superiorRate, amount_);
        if (superior != address(0)) {
            // nft must be staked
            if (fireCatNFTStake.isStaked(superior)) {
                uint256 superiorTokenId = fireCatNFTStake.stakedOf(superior);
                uint256 superiorTokenLevel = fireCatNFT.tokenLevelOf(superiorTokenId);

                if (superiorTokenLevel >= userTokenLevel) {
                    actualSuperiorReward = doTransferIn(rewardToken, msg.sender, superiorReward);
                    _nftLevelUpReward[superior] = _nftLevelUpReward[superior].add(actualSuperiorReward);
                }
            }
        }
    
        uint256 restAmount = amount_.sub(actualInviterReward).sub(actualSuperiorReward);
        emit NftLevelUpShare(restAmount, actualInviterReward, actualSuperiorReward);
        return restAmount;
    }

    /// @inheritdoc IFireCatInspire
    function claim() external beforeClaim nonReentrant returns (uint256) {
        (uint256 availableYieldReward,,) = yieldRewardOf(msg.sender);
        (uint256 availableNftLevelUpReward,,) = nftLevelUpRewardOf(msg.sender);
        uint256 availableClaim = availableYieldReward.add(availableNftLevelUpReward);
        require(availableClaim > 0, "no reward to claim");

        IERC20(rewardToken).approve(msg.sender, availableClaim);
        uint256 actualYieldClaimed = doTransferOut(rewardToken, msg.sender, availableYieldReward);
        uint256 actualNftLevelUpRewardClaimed = doTransferOut(rewardToken, msg.sender, availableNftLevelUpReward);
        uint256 actualClaimedAmount = actualYieldClaimed.add(actualNftLevelUpRewardClaimed);

        _yieldRewardClaimed[msg.sender] = _yieldRewardClaimed[msg.sender].add(actualYieldClaimed);
        _nftLevelUpRewardClaimed[msg.sender] = _nftLevelUpRewardClaimed[msg.sender].add(actualNftLevelUpRewardClaimed);
        claimed[msg.sender] = claimed[msg.sender].add(actualClaimedAmount);

        totalClaimed = totalClaimed.add(actualClaimedAmount);
        emit Claimed(msg.sender, actualClaimedAmount, totalClaimed);
        return actualClaimedAmount;
    }

}