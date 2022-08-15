// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IStakingClaim.sol";

contract StakingClaim is IStakingClaim, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    merkleTreeInfo[] public rootHashInfos;
    mapping (address => mapping(uint256 => receivedInfo)) public receivedInfos;
    uint256 constant compensationAmount = 240 * 1 ether;
    address public tavaTokenAddress;
    stakingCondition public condition;

    constructor(
        address _tavaTokenAddress
    ) {
        tavaTokenAddress = _tavaTokenAddress;
        condition = stakingCondition(30, 5);
    }

    function BalanceToAddress(address account) 
        external view returns(uint256)
    {
        return IERC20(tavaTokenAddress).balanceOf(account);
    }

    function approvalTava(uint256 _amount) 
        external override 
    {
        IERC20(tavaTokenAddress).approve(address(this), _amount);
    }

    function GetElapsedToDuration(uint256 _rootHashIdx) 
        public view override 
        returns(uint256 _elapsedDays)
    {
        uint256 _duration = (condition.duration) * 1 days;
        uint256 _paymentDt = rootHashInfos[_rootHashIdx].paymentDt;

        if(_paymentDt > block.timestamp){
            return 0;
        }

        if(_paymentDt == block.timestamp){
            return 1;
        }

        uint256 _elapsedDaysTemp = (block.timestamp.sub(_paymentDt)).div(_duration) + 1;
        if(_elapsedDaysTemp > 5) {
            _elapsedDays = 5;
        } else {
            _elapsedDays = _elapsedDaysTemp;
        }
    }

    function GetTokensCurrentlyReciveable(uint256 _roothashIdx, uint256 _proofLength) 
        public view override
        returns(uint256 _tokensCurrentlyReciveable)
    {
        uint256 _amount = compensationAmount.mul(_proofLength);
        uint256 _totalReciveableToken = _amount.div(condition.unlockCnt).mul(GetElapsedToDuration(_roothashIdx));
        uint256 _amountReceived = receivedInfos[_msgSender()][_roothashIdx].amountReceived;
        if(_totalReciveableToken > _amountReceived) {
            _tokensCurrentlyReciveable = _totalReciveableToken - _amountReceived;
        } else {
            _tokensCurrentlyReciveable = 0;
        }
    }

    function GetTotalVestedTokenAmount() 
        public view 
        returns(uint256 _totalVestedTokenAmount)
    {
        for(uint i = 0 ; i < rootHashInfos.length ; i++){
            _totalVestedTokenAmount += rootHashInfos[i].totalTokenAmount;
        }
    }

    function GetUnlockedAmount() 
        public view 
        returns(uint256 _unlockedAmount) 
    {
        for(uint i = 0 ; i < rootHashInfos.length ; i++){
            _unlockedAmount += GetUnlockedAmount(i);
        }
    }

    function GetUnlockedAmount(uint256 _roothashIdx) 
        public view 
        returns(uint256 _unlockedAmount) 
    {
        _unlockedAmount = GetElapsedToDuration(_roothashIdx).mul((rootHashInfos[_roothashIdx].totalTokenAmount).div(condition.unlockCnt));
    }

    function SetRootHash(bytes32 _root, uint256 _paymentDt, uint256 _rootHashLength) 
        external override 
        onlyOwner 
    {
        rootHashInfos.push(merkleTreeInfo(_root, _paymentDt, _rootHashLength * compensationAmount));
        emit setRootHash (_paymentDt, rootHashInfos.length-1);
    }

    function SetRewardCA(address _rewardCA) 
        external onlyOwner 
    {
        tavaTokenAddress = _rewardCA;
    }

    function SetCondition(uint256 _duration, uint256 _unlockCnt) 
        external override 
        onlyOwner 
    {
        condition = stakingCondition(_duration, _unlockCnt);
        emit setCondition (_duration, _unlockCnt);
    }

    function ClaimToStaking(uint256 _roothashIdx, bytes32[] memory _proof, bool[] memory _proofFlags, bytes32[] memory _leaves) 
        external override 
        nonReentrant
    {
        bytes32 root = rootHashInfos[_roothashIdx].rootHash;
        require(MerkleProof.multiProofVerify(_proof, _proofFlags, root, _leaves), "ClaimToStaking_ERR01");
        uint256 _amount = compensationAmount.mul(_leaves.length);
        uint256 _amountReceived = receivedInfos[_msgSender()][_roothashIdx].amountReceived;
        require(_amount > _amountReceived,"ClaimToStaking_ERR02");

        uint256 _amountReceive = GetTokensCurrentlyReciveable(_roothashIdx ,_leaves.length);
        require(_amountReceive > 0,"ClaimToStaking_ERR03");

        IERC20(tavaTokenAddress).transfer(_msgSender(), _amountReceive);

        receivedInfos[_msgSender()][_roothashIdx] = receivedInfo(_roothashIdx, (_amountReceived + _amountReceive));
        emit claimToStaking(_msgSender(), _roothashIdx, _amountReceive, block.timestamp);
    }

    function claimTava() 
        external override   
        onlyOwner
    {
        uint256 _TavaBalance = IERC20(tavaTokenAddress).balanceOf(address(this));
        IERC20(tavaTokenAddress).transfer(owner(), _TavaBalance);
    }

    function claimTava(uint256 _amount) 
        external override 
        onlyOwner
    {
        IERC20(tavaTokenAddress).transfer(owner(), _amount.mul(1 ether));
    }
}