// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import {ISmartChefInitializable} from "../src/interfaces/ISmartChefInitializable.sol";
import {IPancakeRouter02} from "../src/interfaces/IPancakeRouter02.sol";
import {IFireCatRegistryProxy} from "../src/interfaces/IFireCatRegistryProxy.sol";
import {IFireCatReserves} from "../src/interfaces/IFireCatReserves.sol";
import {IFireCatTrigger} from "../src/interfaces/IFireCatTrigger.sol";
import {FireCatAccessControl} from "../src/utils/FireCatAccessControl.sol";
import {FireCatTransfer} from "../src/utils/FireCatTransfer.sol";
import {FireCatTriggerStorage} from "../src/storages/FireCatTriggerStorage.sol";

/**
 * @title FireCat's FireCatTrigger contract
 * @notice main: redeemFunds, reinvest
 * @author FireCat Finance
 */
contract FireCatTrigger is IFireCatTrigger, FireCatTriggerStorage, FireCatTransfer, FireCatAccessControl {
    using SafeMath for uint256;

    event Staked(address indexed user_, uint256 tokenId_, uint256 actualAddAmount_, uint256 totalStakedNew);
    event Claimed(address indexed user_, uint256 tokenId_, uint256 actualClaimedAmount, uint256 totalClaimedNew);
    event Withdrawn(address indexed user_, uint256 tokenId_, uint256 actualSubAmount, uint256 totalStakedNew);
    event Swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event SetPath(address rewardToken_, address[] swapPath_);
    event SetMiningPool(address user_, uint256[] weightsArray_, address[] smartChefArray_);
    event SetExitFeeFactor(address user_, uint256 exitFeeFactor_);
    event SetReservesShareFactor(address user_, uint256 reservesShareFactor_);
    event SetInviterShareFactor(address user_, uint256 inviterShareFactor_);

    modifier renewPool(){
        _redeemFunds();
        _;
        _reinvest();
    }

    /**
    * @notice the total earnings amount, depend on totalFunds and totalInvest
    * @return totalEarnings
    */
    function totalEarnings() public view returns (uint256) {
        // rewardPerToken * totalStaked
        return rewardPerToken().mul(totalStaked);
    }

    /**
    * @notice the rewardPerToken.
    * @return rewardPerToken
    */
    function rewardPerToken() public view returns (uint256) {
        // (totalFunds - totalInvest) / totalStaked + rewardPerTokenStored
        if (totalStaked == 0 ) {
            return 0;
        }
        return (totalFunds.sub(totalInvest)).mul(1e18).div(totalStaked).add(rewardPerTokenStored);
    }

    /**
    * @notice check the last reward of user.
    * @param tokenId_ uint256
    * @return reward
    */
    function rewardOf(uint256 tokenId_) public view returns (uint256) {
        // (rewardPerToken - userOwnRewardPerToken[tokenId_]) * staked[tokenId_]
        uint256 rewardPerToken_ = rewardPerToken();
        return (rewardPerToken_.sub(userOwnRewardPerToken[tokenId_])).mul(staked[tokenId_]).div(1e18);
    }

    function _updateRate(uint256 tokenId_) internal {
        uint256 _rewardPerToken = rewardPerToken();
        rewardPerTokenStored = _rewardPerToken;
        userOwnRewardPerToken[tokenId_] = _rewardPerToken;
    }
    
    function _addStake(address from_, uint256 tokenId_, uint256 amount_) internal returns (uint256) {
        uint256 actualAddAmount = doTransferIn(address(cakeToken), from_, amount_);
        uint256 totalStakedNew = totalStaked.add(actualAddAmount);
        require(totalStakedNew > totalStaked, "VAULT:E08");
        totalStaked = totalStakedNew;
        staked[tokenId_] = staked[tokenId_].add(actualAddAmount);
        emit Staked(from_, tokenId_, actualAddAmount, totalStakedNew);
        return actualAddAmount;
    }

    function _withdraw(address to_, uint256 tokenId_, uint256 amount_) internal returns (uint256) {
        uint256 actualSubAmount = doTransferOut(address(cakeToken), to_, amount_);
        uint256 totalStakedNew = totalStaked.sub(actualSubAmount);
        require(totalStakedNew < totalStaked, "VAULT:E08");
        totalStaked = totalStakedNew;
        staked[tokenId_] = staked[tokenId_].sub(actualSubAmount);
        emit Withdrawn(to_, tokenId_, actualSubAmount, totalStakedNew);
        return actualSubAmount;
    }

    function _claimInternal(address to_, uint256 tokenId_, uint256 amount_) internal returns (uint256) {
        uint256 actualClaimedAmount = doTransferOut(address(cakeToken), to_, amount_);
        uint256 totalClaimedNew = totalClaimed.add(actualClaimedAmount);
        require(totalClaimedNew > totalClaimed, "VAULT:E08");
        totalClaimed = totalClaimedNew;
        claimed[tokenId_] = claimed[tokenId_].add(actualClaimedAmount);
        emit Claimed(to_, tokenId_, actualClaimedAmount, totalClaimedNew);
        return actualClaimedAmount;
    }

    function _getReward(address user_, uint256 tokenId_) internal returns (uint256) {
        if (totalFunds > 0) {
            uint256 reward = rewardOf(tokenId_);
            _updateRate(tokenId_);
            
            if (reward > 0) {
                // reserves contracat reward
                uint256 reservesReward = reward.mul(reservesShareFactor).div(1e9);
                IERC20(cakeToken).approve(fireCatReserves, reservesReward);
                uint256 actualReservesClaimed = IFireCatReserves(fireCatReserves).addReserves(user_, reservesReward);

                // inviter reward
                address inviterAddress = IFireCatRegistryProxy(fireCatRegistry).getInviter(user_);
                // (reward - actualReservesClaimed) * inviterShareFactor / 1e9;
                uint256 inviterReward = (reward.sub(actualReservesClaimed)).mul(inviterShareFactor).div(1e9);
                uint256 actualInviterClaimed = _claimInternal(inviterAddress, tokenId_, inviterReward);

                // uesr reward
                uint256 userReward = reward - actualReservesClaimed - actualInviterClaimed;
                uint256 actualUserClaimed = _claimInternal(user_, tokenId_, userReward);
                
                return actualInviterClaimed + actualReservesClaimed + actualUserClaimed;
            }
        }
        return 0;
    }

    function _swap(address tokenIn, uint256 amountIn_) internal returns (uint256) {
        if (amountIn_ == 0) {
            return 0;
        }

        address[] memory path = swapPath[tokenIn];
        address tokenOut = path[path.length - 1];

        // Calculate the amount of exchange result.  [swapIn, swapOut]
        uint256[] memory amounts = IPancakeRouter02(swapRouter).getAmountsOut(amountIn_, path);

        IERC20(tokenIn).approve(swapRouter, amountIn_);
        uint256[] memory SwapResult = IPancakeRouter02(swapRouter).swapExactTokensForTokens(
            amountIn_,  // the amount of input tokens.
            amounts[1],  // The minimum amount tokens to receive.
            path,  // An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
            address(this),  // Address of recipient.
            block.timestamp  // Unix timestamp deadline by which the transaction must confirm.
        );

        uint256 actualIn = SwapResult[0];
        uint256 actualOut = SwapResult[1];
        require(actualIn > 0 && actualOut > 0, "VAULT:E07");
        emit Swap(tokenIn, tokenOut, actualIn, actualOut);
        return actualOut;
    }

    function _redeemFunds() internal {
        if (totalInvest == 0 ) {
            // last invest funds is zero, no funds withdraw from smartChef.
            totalFunds = 0;
        } else {
            require(smartChefArray.length > 0, "VAULT:E06");
            uint256 prevBalance = cakeToken.balanceOf(address(this));
            
            for (uint256 i = 0; i < smartChefArray.length; ++i) {
                uint256 weight = weightsArray[i];
                smartChef = ISmartChefInitializable(smartChefArray[i]);
                address rewardToken = smartChef.rewardToken();

                if (weight > 0) {
                    (uint256 stakedAmount,) = smartChef.userInfo(address(this));  // fetch last staked amount
                    uint256 prevRewardBalance = IERC20(rewardToken).balanceOf(address(this));
                    smartChef.withdraw(stakedAmount);  // withdraw all cake and rewardToken.
                    uint256 afterRewardBalance = IERC20(rewardToken).balanceOf(address(this));

                    uint256 actualRewardBalance = afterRewardBalance - prevRewardBalance;
                    _swap(rewardToken, actualRewardBalance);
                }
            
            }

            uint256 afterBalance = cakeToken.balanceOf(address(this));
            totalFunds = afterBalance.sub(prevBalance);
        }
        
    }

    function _reinvest() internal {
        require(smartChefArray.length > 0, "VAULT:E06");
        uint256 prevBalance = cakeToken.balanceOf(address(this));
        uint256 length = smartChefArray.length;
        
        for (uint256 i = 0; i < length; ++i) {
            uint256 weight = weightsArray[i];
            smartChef = ISmartChefInitializable(smartChefArray[i]);

            if (weight > 0) {
                uint256 investAmount = totalInvest.mul(weight).div(100);
                IERC20(cakeToken).approve(smartChefArray[i], investAmount);
                smartChef.deposit(investAmount);
            }
        
        }

        uint256 afterBalance = cakeToken.balanceOf(address(this));
        totalInvest = prevBalance.sub(afterBalance);    // actualInvestAmount
    }

    function _stake(uint256 tokenId_, uint256 amount_, address user_) internal renewPool returns (uint256) {        
        uint256 actualAddAmount;
        if (totalFunds == 0) {
            actualAddAmount = _addStake(user_, tokenId_, amount_);
            totalInvest = actualAddAmount;
        } else {
            uint256 actualClaimedAmount = _getReward(user_, tokenId_);
            actualAddAmount = _addStake(user_, tokenId_, amount_);
            totalInvest = totalFunds.sub(actualClaimedAmount).add(actualAddAmount);
        }
        return actualAddAmount;
    }

    function _claim(uint256 tokenId_, address user_) internal renewPool returns (uint256) {
        uint256 actualClaimedAmount = _getReward(user_, tokenId_);
        require(actualClaimedAmount > 0, "VAULT:E05");
        totalInvest = totalFunds.sub(actualClaimedAmount);
        return actualClaimedAmount;
    }

    function _exitFunds(uint256 tokenId_, address user_) internal renewPool returns (uint256) {
        uint256 actualClaimedAmount = _getReward(user_, tokenId_);

        uint256 reservesWithdraw =  staked[tokenId_].mul(exitFeeFacotr).div(1e9);
        IERC20(cakeToken).approve(fireCatReserves, reservesWithdraw);
        uint256 actualReservesAmount = IFireCatReserves(fireCatReserves).addReserves(user_, reservesWithdraw);
        uint256 userWithdraw = staked[tokenId_] - actualReservesAmount;
        uint256 actualUserAmount = _withdraw(user_, tokenId_, userWithdraw);
        uint256 totalWithdraw = actualReservesAmount + actualUserAmount;

        totalInvest = totalFunds.sub(actualClaimedAmount).sub(totalWithdraw);
        return totalWithdraw;
    }

    /**
    * @notice set the swap path.
    * @param rewardToken_ address
    * @param swapPath_ address[]
    */
    function setPath(address rewardToken_, address[] calldata swapPath_) external nonReentrant onlyRole(DATA_ADMIN) {
        swapPath[rewardToken_] = swapPath_;
        emit SetPath(rewardToken_, swapPath_);
    }

    /**
    * @notice set the exit funds fee facotr.
    * @param exitFeeFactor_ uint256
    */
    function setExitFeeFactor(uint256 exitFeeFactor_) external nonReentrant onlyRole(DATA_ADMIN) {
        // decimals: 1e9
        exitFeeFacotr = exitFeeFactor_;
        emit SetExitFeeFactor(msg.sender, exitFeeFactor_);
    }

    /**
    * @notice set the reserves contract reward facotr.
    * @param reservesShareFactor_ uint256
    */
    function setReservesShareFactor(uint256 reservesShareFactor_) external nonReentrant onlyRole(DATA_ADMIN) {
        // decimals: 1e9
        reservesShareFactor = reservesShareFactor_;
        emit SetReservesShareFactor(msg.sender, reservesShareFactor_);
    }

    /**
    * @notice set the inviter share reward facotr.
    * @param inviterShareFactor_ uint256
    */
    function setInviterShareFactor(uint256 inviterShareFactor_) external nonReentrant onlyRole(DATA_ADMIN) {
        // decimals: 1e9
        inviterShareFactor = inviterShareFactor_;
        emit SetInviterShareFactor(msg.sender, inviterShareFactor_);
    }

    /**
    * @notice set the mining pools.
    * @param weightsArray_ uint256[]
    * @param smartChefArray_ address[]
    */
    function setMiningPool(
        uint256[] calldata weightsArray_, 
        address[] calldata smartChefArray_
    ) external nonReentrant onlyRole(DATA_ADMIN) {
        require(weightsArray_.length == smartChefArray_.length, "VAULT:E09");
        weightsArray = weightsArray_;
        smartChefArray = smartChefArray_;
        emit SetMiningPool(msg.sender, weightsArray_, smartChefArray_);
    }
   
}