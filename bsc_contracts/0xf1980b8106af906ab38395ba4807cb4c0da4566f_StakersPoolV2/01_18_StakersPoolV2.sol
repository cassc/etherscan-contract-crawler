/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "./02_18_SafeERC20Upgradeable.sol";
import "./03_18_IERC20Upgradeable.sol";
import "./04_18_SafeMathUpgradeable.sol";
import "./05_18_AddressUpgradeable.sol";
import "./06_18_OwnableUpgradeable.sol";
import "./07_18_PausableUpgradeable.sol";
import "./08_18_ReentrancyGuardUpgradeable.sol";
import {SecurityMatrix} from "./09_18_SecurityMatrix.sol";
import {Constant} from "./10_18_Constant.sol";
import {IStakersPoolV2} from "./11_18_IStakersPoolV2.sol";
import {IFeePool} from "./12_18_IFeePool.sol";
import {ILPToken} from "./13_18_ILPToken.sol";
import {Math} from "./14_18_Math.sol";
import {IClaimSettlementPool} from "./15_18_IClaimSettlementPool.sol";

contract StakersPoolV2 is IStakersPoolV2, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function initializeStakersPoolV2() public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    address public securityMatrix;
    address public insurTokenAddress;
    // _token
    mapping(address => uint256) public stakedAmountPT;
    // _lpToken
    mapping(address => uint256) public poolLastCalcBlock;
    mapping(address => uint256) public poolWeightPT;
    uint256 public totalPoolWeight;
    mapping(address => uint256) public poolRewardPerLPToken;
    uint256 public rewardStartBlock;
    uint256 public rewardEndBlock;
    uint256 public rewardPerBlock;
    // _lpToken -> account -> rewards
    mapping(address => mapping(address => uint256)) public stkRewardsPerAPerLPT;
    mapping(address => mapping(address => uint256)) public harvestedRewardsPerAPerLPT;

    // stakers pool signer flag (signer -> true/false)
    mapping(address => bool) public signerFlagMap;
    // stakers pool nonce flag (nonce -> true/false)
    mapping(uint256 => bool) public nonceFlagMap;

    function setup(address _securityMatrix, address _insurTokenAddress) external onlyOwner {
        require(_securityMatrix != address(0), "S:1");
        securityMatrix = _securityMatrix;
        require(_insurTokenAddress != address(0), "S:2");
        insurTokenAddress = _insurTokenAddress;
    }

    function setPoolWeight(
        address _lpToken,
        uint256 _poolWeightPT,
        address[] memory _lpTokens
    ) external onlyOwner {
        reCalcAllPools(_lpTokens);
        if (poolWeightPT[_lpToken] != 0) {
            totalPoolWeight = totalPoolWeight.sub(poolWeightPT[_lpToken]);
        }
        poolWeightPT[_lpToken] = _poolWeightPT;
        totalPoolWeight = totalPoolWeight.add(_poolWeightPT);
    }

    event SetRewardInfo(uint256 _rewardStartBlock, uint256 _rewardEndBlock, uint256 _rewardPerBlock);

    function setRewardInfo(
        uint256 _rewardStartBlock,
        uint256 _rewardEndBlock,
        uint256 _rewardPerBlock,
        address[] memory _lpTokens
    ) external onlyOwner {
        require(_rewardStartBlock < _rewardEndBlock, "SRI:1");
        require(block.number < _rewardEndBlock, "SRI:2");
        reCalcAllPools(_lpTokens);
        if (block.number <= rewardEndBlock && block.number >= rewardStartBlock) {
            rewardEndBlock = _rewardEndBlock;
            rewardPerBlock = _rewardPerBlock;
        } else {
            rewardStartBlock = _rewardStartBlock;
            rewardEndBlock = _rewardEndBlock;
            rewardPerBlock = _rewardPerBlock;
        }
        emit SetRewardInfo(_rewardStartBlock, _rewardEndBlock, _rewardPerBlock);
    }

    modifier allowedCaller() {
        require((SecurityMatrix(securityMatrix).isAllowdCaller(address(this), _msgSender())) || (_msgSender() == owner()), "allowedCaller");
        _;
    }

    event StakedAmountPTEvent(address indexed _token, uint256 _amount);

    function getPoolReward(
        uint256 _from,
        uint256 _to,
        uint256 _poolWeight
    ) private view returns (uint256) {
        uint256 start = Math.max(_from, rewardStartBlock);
        uint256 end = Math.min(_to, rewardEndBlock);
        if (end <= start) {
            return 0;
        }
        uint256 deltaBlock = end.sub(start);
        uint256 amount = deltaBlock.mul(rewardPerBlock).mul(_poolWeight).div(totalPoolWeight);
        return amount;
    }

    function reCalcAllPools(address[] memory _lpTokens) private {
        for (uint256 i = 0; i < _lpTokens.length; i++) {
            reCalcPoolPT(_lpTokens[i]);
        }
    }

    function reCalcPoolPT(address _lpToken) public override allowedCaller {
        if (block.number <= poolLastCalcBlock[_lpToken]) {
            // require(false, "reCalcPoolPT:1");
            return;
        }
        uint256 lpSupply = IERC20Upgradeable(_lpToken).totalSupply();
        if (lpSupply == 0) {
            poolLastCalcBlock[_lpToken] = block.number;
            return;
        }
        uint256 reward = getPoolReward(poolLastCalcBlock[_lpToken], block.number, poolWeightPT[_lpToken]);
        poolRewardPerLPToken[_lpToken] = poolRewardPerLPToken[_lpToken].add(reward.mul(1e18).div(lpSupply));
        poolLastCalcBlock[_lpToken] = block.number;
    }

    function showPendingRewards(address _account, address _lpToken) external view override returns (uint256) {
        uint256 poolRewardPerLPTokenT = 0;
        uint256 userAmt = IERC20Upgradeable(_lpToken).balanceOf(_account);
        uint256 userRewardDebt = ILPToken(_lpToken).rewardDebtOf(_account);
        uint256 lpSupply = IERC20Upgradeable(_lpToken).totalSupply();
        if (block.number == poolLastCalcBlock[_lpToken]) {
            return 0;
        }
        if (block.number > poolLastCalcBlock[_lpToken] && lpSupply > 0) {
            uint256 reward = getPoolReward(poolLastCalcBlock[_lpToken], block.number, poolWeightPT[_lpToken]);

            poolRewardPerLPTokenT = poolRewardPerLPToken[_lpToken].add(reward.mul(1e18).div(lpSupply));
        }
        require(userAmt.mul(poolRewardPerLPTokenT).div(1e18) >= userRewardDebt, "showPR:1");
        return userAmt.mul(poolRewardPerLPTokenT).div(1e18).sub(userRewardDebt);
    }

    function settlePendingRewards(address _account, address _lpToken) external override allowedCaller {
        uint256 userAmt = IERC20Upgradeable(_lpToken).balanceOf(_account);
        uint256 userRewardDebt = ILPToken(_lpToken).rewardDebtOf(_account);
        if (userAmt > 0) {
            uint256 pendingAmt = userAmt.mul(poolRewardPerLPToken[_lpToken]).div(1e18).sub(userRewardDebt);
            if (pendingAmt > 0) {
                stkRewardsPerAPerLPT[_lpToken][_account] = stkRewardsPerAPerLPT[_lpToken][_account].add(pendingAmt);
            }
        }
    }

    function showHarvestRewards(address _account, address _lpToken) external view override returns (uint256) {
        return stkRewardsPerAPerLPT[_lpToken][_account];
    }

    function harvestRewards(
        address _account,
        address _lpToken,
        address _to
    ) external override allowedCaller returns (uint256) {
        uint256 amtHas = stkRewardsPerAPerLPT[_lpToken][_account];
        harvestedRewardsPerAPerLPT[_lpToken][_account] = harvestedRewardsPerAPerLPT[_lpToken][_account].add(amtHas);
        stkRewardsPerAPerLPT[_lpToken][_account] = 0;
        IERC20Upgradeable(insurTokenAddress).safeTransfer(_to, amtHas);
        return amtHas;
    }

    function getPoolRewardPerLPToken(address _lpToken) external view override returns (uint256) {
        return poolRewardPerLPToken[_lpToken];
    }

    function addStkAmount(address _token, uint256 _amount) external payable override allowedCaller {
        if (_token == Constant.BCNATIVETOKENADDRESS) {
            require(msg.value == _amount, "ASA:1");
        }
        stakedAmountPT[_token] = stakedAmountPT[_token].add(_amount);
        emit StakedAmountPTEvent(_token, stakedAmountPT[_token]);
    }

    function getStakedAmountPT(address _token) external view override returns (uint256) {
        return stakedAmountPT[_token];
    }

    function withdrawTokens(
        address payable _to,
        uint256 _withdrawAmtAfterFee,
        address _token,
        address _feePool,
        uint256 _fee
    ) external override allowedCaller {
        require(_withdrawAmtAfterFee.add(_fee) <= stakedAmountPT[_token], "WDT:1");
        require(_withdrawAmtAfterFee > 0, "WDT:2");

        stakedAmountPT[_token] = stakedAmountPT[_token].sub(_withdrawAmtAfterFee);
        stakedAmountPT[_token] = stakedAmountPT[_token].sub(_fee);

        if (_token == Constant.BCNATIVETOKENADDRESS) {
            _to.transfer(_withdrawAmtAfterFee);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_to, _withdrawAmtAfterFee);
        }

        if (_token == Constant.BCNATIVETOKENADDRESS) {
            IFeePool(_feePool).addUnstkFee{value: _fee}(_token, _fee);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_feePool, _fee);
            IFeePool(_feePool).addUnstkFee(_token, _fee);
        }
        emit StakedAmountPTEvent(_token, stakedAmountPT[_token]);
    }

    event ClaimPayoutEvent(address _fromToken, address _paymentToken, uint256 _settleAmtPT, uint256 _claimId, uint256 _fromRate, uint256 _toRate);

    function claimPayout(
        address _fromToken,
        address _paymentToken,
        uint256 _settleAmtPT,
        address _claimToSettlementPool,
        uint256 _claimId,
        uint256 _fromRate,
        uint256 _toRate
    ) external override allowedCaller {
        if (_settleAmtPT == 0) {
            return;
        }
        uint256 amountIn = _settleAmtPT.mul(_fromRate).mul(10**8).div(_toRate).div(10**8);
        require(stakedAmountPT[_fromToken] >= amountIn, "claimP:1");
        stakedAmountPT[_fromToken] = stakedAmountPT[_fromToken].sub(amountIn);
        _transferTokenTo(_fromToken, amountIn, _claimToSettlementPool);
        emit StakedAmountPTEvent(_fromToken, stakedAmountPT[_fromToken]);
        emit ClaimPayoutEvent(_fromToken, _paymentToken, _settleAmtPT, _claimId, _fromRate, _toRate);
    }

    function _transferTokenTo(
        address _paymentToken,
        uint256 _amt,
        address _claimToSettlementPool
    ) private {
        if (_paymentToken == Constant.BCNATIVETOKENADDRESS) {
            IClaimSettlementPool(_claimToSettlementPool).addSettlementAmount{value: _amt}(_paymentToken, _amt);
        } else {
            IERC20Upgradeable(_paymentToken).safeTransfer(_claimToSettlementPool, _amt);
            IClaimSettlementPool(_claimToSettlementPool).addSettlementAmount(_paymentToken, _amt);
        }
    }

    function getRewardToken() external view override returns (address) {
        return insurTokenAddress;
    }

    function getRewardPerBlockPerPool(address _lpToken) external view override returns (uint256) {
        return rewardPerBlock.mul(poolWeightPT[_lpToken]).div(totalPoolWeight);
    }

    function rebalancePools(
        uint256 _rewardPerBlock,
        address[] memory _lpTokens,
        uint256[] memory _weightList,
        uint256 _nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external allowedCaller {
        require(_rewardPerBlock > 0, "RBLNPL:1");
        require(_lpTokens.length == _weightList.length, "RBLNPL:2");
        require(v.length == 2 && r.length == 2 && s.length == 2, "RBLNPL:3");

        require(_checkSignature(address(this), _rewardPerBlock, _lpTokens, _weightList, _nonce, v, r, s), "RBLNPL:4");

        require(!nonceFlagMap[_nonce], "RBLNPL:5");
        nonceFlagMap[_nonce] = true;

        reCalcAllPools(_lpTokens);
        rewardPerBlock = _rewardPerBlock;
        for (uint256 i = 0; i < _lpTokens.length; i++) {
            address lpToken = _lpTokens[i];
            if (poolWeightPT[lpToken] != 0) {
                totalPoolWeight = totalPoolWeight.sub(poolWeightPT[lpToken]);
            }
            poolWeightPT[lpToken] = _weightList[i];
            totalPoolWeight = totalPoolWeight.add(_weightList[i]);
        }
        emit SetRewardInfo(rewardStartBlock, rewardEndBlock, _rewardPerBlock);
    }

    function _checkSignature(
        address _scAddress,
        uint256 _rewardPerBlock,
        address[] memory _lpTokens,
        uint256[] memory _weightList,
        uint256 _nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) internal view returns (bool) {
        bytes32 msgHash = keccak256(abi.encodePacked(_scAddress, _rewardPerBlock, _lpTokens, _weightList, _nonce));
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, msgHash));
        address signer1 = ecrecover(prefixedHash, v[0], r[0], s[0]);
        address signer2 = ecrecover(prefixedHash, v[1], r[1], s[1]);
        return (signer1 != signer2) && signerFlagMap[signer1] && signerFlagMap[signer2];
    }

    event SetStakersPoolSignerEvent(address indexed signer, bool enabled);

    function setStakersPoolSigner(address signer, bool enabled) external onlyOwner {
        require(signer != address(0), "SSPS: 1");
        signerFlagMap[signer] = enabled;
        emit SetStakersPoolSignerEvent(signer, enabled);
    }
}