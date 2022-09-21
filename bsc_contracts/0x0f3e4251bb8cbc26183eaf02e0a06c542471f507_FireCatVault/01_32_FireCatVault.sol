// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import {IFireCatNFT} from "../src/interfaces/IFireCatNFT.sol";
import {IFireCatGate} from "../src/interfaces/IFireCatGate.sol";
import {IFireCatVault} from "../src/interfaces/IFireCatVault.sol";
import {IFireCatIssuePool} from "../src/interfaces/IFireCatIssuePool.sol";
import {FireCatTrigger} from "./FireCatTrigger.sol";
import {ModifyControl} from "../src/utils/ModifyControl.sol";

/**
 * @title FireCat's FireCatVault contract
 * @notice main: stake, claim, exitFunds
 * @author FireCat Finance
 */
contract FireCatVault is IFireCatVault, FireCatTrigger, ModifyControl {
    using SafeMath for uint256;

    function initialize(
        address cakeToken_, 
        address swapRouter_, 
        address fireCatNFT_, 
        address fireCatGate_, 
        address fireCatIssuePool_,
        address fireCatRegistry_,
        address fireCatReserves_
    ) initializer public {
        stakeToken = cakeToken_;
        cakeToken = IERC20(cakeToken_);
        swapRouter = swapRouter_;
        fireCatNFT = fireCatNFT_;
        fireCatGate = fireCatGate_;
        fireCatIssuePool = fireCatIssuePool_;
        fireCatRegistry = fireCatRegistry_;
        fireCatReserves = fireCatReserves_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);   
    }

    /// @inheritdoc IFireCatVault
    function isQualified(address user_) public view returns (bool) {
        return IFireCatGate(fireCatGate).hasStaked(user_);
    }
    
    /// @inheritdoc IFireCatVault
    function tokenIdOf(address user_) public view returns (uint256) {
        return IFireCatGate(fireCatGate).stakedOf(user_);
    }

    /// @inheritdoc IFireCatVault
    function migrateIn(uint256 tokenId_, uint256 amount_) external onlyRole(FIRECAT_GATE) returns(uint256) {
        require(cakeToken.balanceOf(msg.sender) >= amount_, "VAULT:E01");
        uint256 actualAddAmount = _stake(tokenId_, amount_, msg.sender);  // fireCatGate Stake Cake to this vault
        IFireCatIssuePool(fireCatIssuePool).stake(tokenId_, actualAddAmount);
        return actualAddAmount;
    }

    /// @inheritdoc IFireCatVault
    function migrateOut(uint256 tokenId_, uint256 amount_) external renewPool onlyRole(FIRECAT_GATE) returns (uint256) {
        require(staked[tokenId_] >= amount_, "VAULT:E04");
        address tokenOwner = IFireCatNFT(fireCatNFT).ownerOf(tokenId_);
        _getReward(tokenOwner, tokenId_);  // claim reward to user

        uint256 actualClaimedAmount = _getReward(tokenOwner, tokenId_);
        uint256 actualSubAmount = _withdraw(msg.sender, tokenId_, amount_);  // withdraw to fireCatGate contract 
        IFireCatIssuePool(fireCatIssuePool).withdrawn(tokenId_, actualSubAmount);
        totalInvest = totalFunds.sub(actualClaimedAmount).sub(actualSubAmount);
        return actualSubAmount;
    }

    /// @inheritdoc IFireCatVault
    function claimTokens(address token, address to, uint256 amount) external nonReentrant onlyRole(SAFE_ADMIN) {
        if (amount > 0) {
            if (token == address(0)) {
                (bool res,) = to.call{value : amount}("");
                require(res, "VAULT:E03");
            } else {
                withdraw(token, to, amount);
            }
        }
    }

    /// @inheritdoc IFireCatVault
    function stake(uint256 amount_) external beforeStake nonReentrant {
        require(isQualified(msg.sender), "VAULT:E00");
        require(amount_ >= 10 ** 17, "MFTP:E1");
        require(cakeToken.balanceOf(msg.sender) >= amount_, "VAULT:E01");

        uint256 tokenId_ = tokenIdOf(msg.sender);
        uint256 actualAddAmount = _stake(tokenId_, amount_, msg.sender);
        IFireCatIssuePool(fireCatIssuePool).stake(tokenId_, actualAddAmount);
    }

    /// @inheritdoc IFireCatVault
    function claim(uint256 tokenId_) external beforeClaim nonReentrant {
        address tokenOwner = IFireCatNFT(fireCatNFT).ownerOf(tokenId_);
        if (tokenOwner == fireCatGate) {
            // nft staked in fireCatGate
            address user = IFireCatGate(fireCatGate).ownerOf(tokenId_);
            require(msg.sender == user, "VAULT:E02");
        } else {
            // nft not staked in fireCatGate, someone own the nft
            require(msg.sender == tokenOwner, "VAULT:E02");
        }

        _claim(tokenId_, msg.sender);
        
    }

    /// @inheritdoc IFireCatVault
    function exitFunds(uint256 tokenId_, address user_) external nonReentrant onlyRole(FIRECAT_GATE) returns(uint256) {
        address tokenOwner = IFireCatNFT(fireCatNFT).ownerOf(tokenId_);
        require(msg.sender == tokenOwner, "VAULT:E02");

        uint256 actualSubAmount = _exitFunds(tokenId_, user_);
        IFireCatIssuePool(fireCatIssuePool).withdrawn(tokenId_, actualSubAmount);
        return actualSubAmount;
    }
}