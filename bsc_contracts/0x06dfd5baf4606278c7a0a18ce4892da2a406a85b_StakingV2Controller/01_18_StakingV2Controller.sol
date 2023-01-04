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
import {Constant} from "./09_18_Constant.sol";
import {ISecurityMatrix} from "./10_18_ISecurityMatrix.sol";
import {IStakersPoolV2} from "./11_18_IStakersPoolV2.sol";
import {ILPToken} from "./12_18_ILPToken.sol";
import {IStakingV2Controller} from "./13_18_IStakingV2Controller.sol";
import {Math} from "./14_18_Math.sol";
import {ICapitalPool} from "./15_18_ICapitalPool.sol";
import {IExchangeRate} from "./16_18_IExchangeRate.sol";

contract StakingV2Controller is IStakingV2Controller, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function initializeStakingV2Controller() public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    address public stakersPoolV2;
    address public feePool;
    // _token => _lpToken
    mapping(address => address) public tokenToLPTokenMap;
    uint256 public mapCounter;
    // _token => staking info
    mapping(address => uint256) public minStakeAmtPT;
    mapping(address => uint256) public minUnstakeAmtPT;
    mapping(address => uint256) public maxUnstakeAmtPT;
    mapping(address => uint256) public unstakeLockBlkPT;
    uint256 public constant G_WITHDRAW_FEE_BASE = 10000;
    mapping(address => uint256) public withdrawFeePT;

    address public securityMatrix;
    address public capitalPool;

    mapping(address => uint256) public totalStakedCapPT;
    mapping(address => uint256) public perAccountCapPT;

    // exchange rate
    address public exchangeRate;

    // staking controller signer and nonce flag (signer/nonce -> true/false)
    mapping(address => bool) public signerFlagMap;
    mapping(address => mapping(uint256 => bool)) public nonceFlagMap;

    function setup(
        address _securityMatrix,
        address _stakersPoolV2,
        address _feePool,
        address _capitalPool,
        address _exchangeRate
    ) external onlyOwner {
        require(_securityMatrix != address(0), "S:1");
        require(_stakersPoolV2 != address(0), "S:2");
        require(_feePool != address(0), "S:3");
        require(_capitalPool != address(0), "S:4");
        require(_exchangeRate != address(0), "S:5");
        securityMatrix = _securityMatrix;
        stakersPoolV2 = _stakersPoolV2;
        feePool = _feePool;
        capitalPool = _capitalPool;
        exchangeRate = _exchangeRate;
    }

    modifier allowedCaller() {
        require((ISecurityMatrix(securityMatrix).isAllowdCaller(address(this), _msgSender())) || (_msgSender() == owner()), "allowedCaller");
        _;
    }

    modifier onlyAllowedToken(address _token) {
        address lpToken = tokenToLPTokenMap[_token];
        require(lpToken != address(0), "onlyAllowedToken");
        _;
    }

    function setTokenToLPTokenMap(address _token, address _lpToken) external onlyOwner {
        require(_token != address(0), "STTLPTM:1");
        tokenToLPTokenMap[_token] = _lpToken;
    }

    function setMapCounter(uint256 _mapCounter) external onlyOwner {
        mapCounter = _mapCounter;
    }

    function setStakeInfo(
        address _token,
        uint256 _minStakeAmt,
        uint256 _minUnstakeAmt,
        uint256 _maxUnstakeAmt,
        uint256 _unstakeLockBlk,
        uint256 _withdrawFee
    ) external onlyOwner onlyAllowedToken(_token) {
        require(_token != address(0), "SSI:1");
        minStakeAmtPT[_token] = _minStakeAmt;
        require(_minUnstakeAmt < _maxUnstakeAmt, "SSI:2");
        minUnstakeAmtPT[_token] = _minUnstakeAmt;
        maxUnstakeAmtPT[_token] = _maxUnstakeAmt;
        unstakeLockBlkPT[_token] = _unstakeLockBlk;
        withdrawFeePT[_token] = _withdrawFee;
    }

    function setStakeCap(
        address _token,
        uint256 _totalStakedCapPT,
        uint256 _perAccountCapPT
    ) external onlyOwner onlyAllowedToken(_token) {
        totalStakedCapPT[_token] = _totalStakedCapPT;
        perAccountCapPT[_token] = _perAccountCapPT;
    }

    event SetStakingControllerSignerEvent(address indexed signer, bool enabled);

    function setStakingControllerSigner(address signer, bool enabled) external onlyOwner {
        require(signer != address(0), "SSCS: 1");
        signerFlagMap[signer] = enabled;
        emit SetStakingControllerSignerEvent(signer, enabled);
    }

    // pause
    function pauseAll() external onlyOwner whenNotPaused {
        _pause();
    }

    function unPauseAll() external onlyOwner whenPaused {
        _unpause();
    }

    event StakeTokensEvent(address indexed _from, address indexed _lpToken, uint256 _deltaAmt, uint256 _balance);
    event StakeTokensEventV2(address indexed _from, address indexed _token, uint256 _amount, address indexed _lpToken, uint256 _deltaAmt, uint256 _balance);

    function stakeTokens(uint256 _amount, address _token) external payable override whenNotPaused nonReentrant onlyAllowedToken(_token) {
        require(minStakeAmtPT[_token] <= _amount, "ST:1");

        address lpToken = tokenToLPTokenMap[_token];
        IStakersPoolV2(stakersPoolV2).reCalcPoolPT(lpToken);
        IStakersPoolV2(stakersPoolV2).settlePendingRewards(_msgSender(), lpToken);
        if (_token == Constant.BCNATIVETOKENADDRESS) {
            require(_amount <= msg.value, "ST:2");
        } else {
            require(IERC20Upgradeable(_token).balanceOf(_msgSender()) >= _amount, "ST:3");
            uint256 allowanceAmt = IERC20Upgradeable(_token).allowance(_msgSender(), address(this));
            require(allowanceAmt >= _amount, "ST:4");
            IERC20Upgradeable(_token).safeTransferFrom(_msgSender(), address(this), _amount);
        }
        // eth/lpeth = constant = _amount/lpTokenAmount
        uint256 lpTokenAmount = _amount;
        uint256 stakedTokenAmt = IStakersPoolV2(stakersPoolV2).getStakedAmountPT(_token);

        if (stakedTokenAmt > 0) {
            lpTokenAmount = _amount.mul(IERC20Upgradeable(lpToken).totalSupply()).div(stakedTokenAmt);
            require(lpTokenAmount != 0, "ST:5");
        }
        if (_token == Constant.BCNATIVETOKENADDRESS) {
            IStakersPoolV2(stakersPoolV2).addStkAmount{value: _amount}(_token, _amount);
        } else {
            IERC20Upgradeable(_token).safeTransfer(stakersPoolV2, _amount);
            IStakersPoolV2(stakersPoolV2).addStkAmount(_token, _amount);
        }
        uint256 poolRewardPerLPToken = IStakersPoolV2(stakersPoolV2).getPoolRewardPerLPToken(lpToken);
        ILPToken(lpToken).mint(_msgSender(), lpTokenAmount, poolRewardPerLPToken);
        uint256 lpTokenAmtAfterStaked = IERC20Upgradeable(lpToken).balanceOf(_msgSender());
        require(stakedTokenAmt.add(_amount) <= totalStakedCapPT[_token], "ST:6");
        uint256 tokenAmtAfterStaked = lpTokenAmtAfterStaked.mul(stakedTokenAmt.add(_amount)).div(IERC20Upgradeable(lpToken).totalSupply());
        require(tokenAmtAfterStaked <= perAccountCapPT[_token], "ST:7");
        emit StakeTokensEventV2(_msgSender(), _token, _amount, lpToken, lpTokenAmount, IERC20Upgradeable(lpToken).balanceOf(_msgSender()));
    }

    // propose unstake
    event ProposeUnstakeEvent(address indexed _from, address indexed _token, uint256 _deltaAmt);
    event ProposeUnstakeEventV2(address indexed _from, address indexed _token, uint256 _amount, address indexed _lpToken, uint256 _deltaAmt);

    function proposeUnstake(uint256 _amount, address _token) external override nonReentrant whenNotPaused onlyAllowedToken(_token) {
        require(minUnstakeAmtPT[_token] <= _amount && maxUnstakeAmtPT[_token] >= _amount, "PU:1");
        address lpToken = tokenToLPTokenMap[_token];
        // eth/lpeth = constant = _amount/lpTokenAmount
        require(IStakersPoolV2(stakersPoolV2).getStakedAmountPT(_token) >= _amount, "PU:2");
        uint256 proposeUnstakeLP = _amount.mul(IERC20Upgradeable(lpToken).totalSupply()).div(IStakersPoolV2(stakersPoolV2).getStakedAmountPT(_token));
        require(proposeUnstakeLP != 0, "PU:3");
        ILPToken(lpToken).proposeToBurn(_msgSender(), proposeUnstakeLP, unstakeLockBlkPT[_token]);
        emit ProposeUnstakeEventV2(_msgSender(), _token, _amount, lpToken, proposeUnstakeLP);
    }

    // Withdraw related
    event WithdrawTokensEvent(address indexed _from, address indexed _token, uint256 _deltaAmt, uint256 _balance);
    event WithdrawTokensEventV2(address indexed _from, address indexed _token, uint256 _amount, address indexed _lpToken, uint256 _deltaAmt, uint256 _balance);

    function withdrawTokens(
        address _caller,
        address payable _staker,
        uint256 _amount,
        address _token,
        uint256 _nonce,
        uint256 _deadline,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external override nonReentrant whenNotPaused onlyAllowedToken(_token) {
        bytes32 msgHash = keccak256(abi.encodePacked(address(this), _caller, _staker, _amount, _token, _nonce, _deadline));
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        address signer = ecrecover(prefixedHash, v[0], r[0], s[0]);
        require(signerFlagMap[signer], "WTKN:1");

        require(!nonceFlagMap[_staker][_nonce], "WTKN:2");
        nonceFlagMap[_staker][_nonce] = true;

        address msgSender = _msgSender();
        require(msgSender == _caller || msgSender == _staker, "WTKN:3");
        require(block.number < _deadline, "WTKN:4");

        _withdrawTokens(_staker, _amount, _token);
    }

    function _withdrawTokens(
        address payable _staker,
        uint256 _amount,
        address _token
    ) private {
        require(_amount > 0, "WT:1");
        address lpToken = tokenToLPTokenMap[_token];
        IStakersPoolV2(stakersPoolV2).reCalcPoolPT(lpToken);
        IStakersPoolV2(stakersPoolV2).settlePendingRewards(_staker, lpToken);
        // eth/lpeth = constant = _amount/lpTokenAmount
        uint256 unstakeLP = _amount;
        require(IStakersPoolV2(stakersPoolV2).getStakedAmountPT(_token) != 0, "WT:2");
        unstakeLP = _amount.mul(IERC20Upgradeable(lpToken).totalSupply()).div(IStakersPoolV2(stakersPoolV2).getStakedAmountPT(_token));
        require(unstakeLP != 0, "WT:3");
        uint256 withdrawAmtAfterFee = _amount.mul(G_WITHDRAW_FEE_BASE.sub(withdrawFeePT[_token])).div(G_WITHDRAW_FEE_BASE);
        IStakersPoolV2(stakersPoolV2).withdrawTokens(_staker, withdrawAmtAfterFee, _token, feePool, _amount.sub(withdrawAmtAfterFee));
        uint256 poolRewardPerLPToken = IStakersPoolV2(stakersPoolV2).getPoolRewardPerLPToken(lpToken);
        ILPToken(lpToken).burn(_staker, unstakeLP, poolRewardPerLPToken);
        emit WithdrawTokensEventV2(_staker, _token, _amount, lpToken, unstakeLP, IERC20Upgradeable(lpToken).balanceOf(_staker));
    }

    event UnlockRewardsFromPoolsEvent(address indexed _to, address indexed _token, uint256 _amount);

    function unlockRewardsFromPoolsByController(
        address _staker,
        address _to,
        address[] memory _tokenList
    ) external override allowedCaller whenNotPaused nonReentrant returns (uint256) {
        uint256 delta = _unlockRewardsFromPools(_staker, _to, _tokenList);
        return delta;
    }

    function _unlockRewardsFromPools(
        address staker,
        address _to,
        address[] memory _tokenList
    ) private returns (uint256) {
        require(_to != address(0), "_URFP:1");
        require(_tokenList.length <= mapCounter, "_URFP:2");
        uint256 totalHarvestedAmt = 0;
        for (uint256 i = 0; i < _tokenList.length; i++) {
            address token = _tokenList[i];
            address lpToken = tokenToLPTokenMap[token];
            require(lpToken != address(0), "_URFP:3");
            if (IERC20Upgradeable(lpToken).balanceOf(staker) != 0) {
                IStakersPoolV2(stakersPoolV2).reCalcPoolPT(lpToken);
                IStakersPoolV2(stakersPoolV2).settlePendingRewards(staker, lpToken);
            }
            uint256 harvestedAmt = IStakersPoolV2(stakersPoolV2).harvestRewards(staker, lpToken, _to);
            totalHarvestedAmt = totalHarvestedAmt.add(harvestedAmt);
            if (IERC20Upgradeable(lpToken).balanceOf(staker) != 0) {
                uint256 poolRewardPerLPToken = IStakersPoolV2(stakersPoolV2).getPoolRewardPerLPToken(lpToken);
                ILPToken(lpToken).mint(staker, 0, poolRewardPerLPToken);
            }
            emit UnlockRewardsFromPoolsEvent(staker, token, harvestedAmt);
        }
        return totalHarvestedAmt;
    }

    function showRewardsFromPools(address[] memory _tokenList) external view override returns (uint256) {
        return _showRewardsFromPools(_msgSender(), _tokenList);
    }

    function showRewardsFromPoolsByStaker(address staker, address[] memory _tokenList) external view override returns (uint256) {
        return _showRewardsFromPools(staker, _tokenList);
    }

    function _showRewardsFromPools(address staker, address[] memory _tokenList) internal view returns (uint256) {
        require(_tokenList.length <= mapCounter, "SRFP:1");
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < _tokenList.length; i++) {
            address token = _tokenList[i];
            address lpToken = tokenToLPTokenMap[token];
            require(lpToken != address(0), "SRFP:2");
            uint256 pendingRewards = IStakersPoolV2(stakersPoolV2).showPendingRewards(staker, lpToken);
            uint256 harvestRewards = IStakersPoolV2(stakersPoolV2).showHarvestRewards(staker, lpToken);
            totalRewards = totalRewards.add(pendingRewards).add(harvestRewards);
        }
        return totalRewards;
    }

    function getRebalancedPools(
        uint256 _weightTotal,
        uint256 _blockPerYear,
        uint256 _expectedAPYX10000,
        address[] memory _tokenInclusionList,
        address[] memory _tokenExclusionList
    ) external view returns (uint256[] memory weightList_, uint256 rewardPerBlock_) {
        require(_weightTotal >= 100000000, "GRBPL:1");
        require(_blockPerYear > 0, "GRBPL:2");
        require(_expectedAPYX10000 >= 0 && _expectedAPYX10000 <= 10000, "GRBPL:3");
        require(_tokenInclusionList.length + _tokenExclusionList.length == mapCounter, "GRBPL:4");
        // reward per block per pool
        uint256[] memory rewardPBPP = new uint256[](_tokenInclusionList.length + _tokenExclusionList.length);
        uint256[] memory retWeightList = new uint256[](rewardPBPP.length);
        uint256 rewardPerBlock = 0;
        uint256 rewardPBPPIndex = 0;
        uint256 expectedAPYX10000 = _expectedAPYX10000;
        uint256 weightTotal = _weightTotal;
        uint256 blockPerYear = _blockPerYear;
        for (uint256 i = 0; i < _tokenInclusionList.length; i++) {
            require(tokenToLPTokenMap[_tokenInclusionList[i]] != address(0), "GRBPL:5");
            uint256 tvlAmt = IStakersPoolV2(stakersPoolV2).getStakedAmountPT(_tokenInclusionList[i]);
            uint256 convertReward = IExchangeRate(exchangeRate).getTokenToTokenAmount(_tokenInclusionList[i], IStakersPoolV2(stakersPoolV2).getRewardToken(), tvlAmt);
            rewardPBPP[rewardPBPPIndex] = expectedAPYX10000.mul(convertReward).div(blockPerYear).div(10000);

            rewardPerBlock = rewardPerBlock.add(rewardPBPP[rewardPBPPIndex]);
            rewardPBPPIndex = rewardPBPPIndex.add(1);
        }

        for (uint256 i = 0; i < _tokenExclusionList.length; i++) {
            require(tokenToLPTokenMap[_tokenExclusionList[i]] != address(0), "GRBPL:6");
            rewardPBPP[rewardPBPPIndex] = IStakersPoolV2(stakersPoolV2).getRewardPerBlockPerPool(tokenToLPTokenMap[_tokenExclusionList[i]]);
            rewardPerBlock = rewardPerBlock.add(rewardPBPP[rewardPBPPIndex]);
            rewardPBPPIndex = rewardPBPPIndex.add(1);
        }

        for (uint256 i = 0; i < rewardPBPP.length; i++) {
            retWeightList[i] = weightTotal.mul(rewardPBPP[i]).div(rewardPerBlock);
        }
        return (retWeightList, rewardPerBlock);
    }
}