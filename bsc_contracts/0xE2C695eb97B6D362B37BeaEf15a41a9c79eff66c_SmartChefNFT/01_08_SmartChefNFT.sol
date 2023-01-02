//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//BNF-02
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

interface IOLYXNFT {
    function tokenFreeze(uint tokenId) external;
    function tokenUnfreeze(uint tokenId) external;
    function getInfoForStaking(uint tokenId) external view returns(address tokenOwner, string memory category, uint level, bool stakeFreeze);
}

contract SmartChefNFT is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint public totalNFTSupply;
    uint public lastRewardBlock;
    address[] public listRewardTokens;
    IOLYXNFT public nftToken;

    // Info of each user
    struct UserInfo {
        uint[] stakedTokensId;
        uint stakedRbAmount;
    }

    struct RewardToken {
        uint rewardPerBlock;
        uint startBlock;
        uint accTokenPerShare; // Accumulated Tokens per share, times 1e12.
        uint rewardsForWithdrawal;
        bool enabled; // true - enable; false - disable
    }

    mapping (address => UserInfo) public userInfo;
    mapping (address => mapping(address => uint)) public rewardDebt; //user => (rewardToken => rewardDebt);
    mapping (address => RewardToken) public rewardTokens;

    event AddNewTokenReward(address token);
    event DisableTokenReward(address token);
    event ChangeTokenReward(address indexed token, uint rewardPerBlock);
    event StakeTokens(address indexed user, uint amountRB, uint[] tokensId);
    event UnstakeToken(address indexed user, uint amountRB, uint[] tokensId);
    event EmergencyWithdraw(address indexed user, uint tokenCount);

    constructor(IOLYXNFT _nftToken) {
        nftToken = _nftToken;
    }

    function isTokenInList(address _token) internal view returns(bool){
        address[] memory _listRewardTokens = listRewardTokens;
        bool thereIs = false;
        for(uint i = 0; i < _listRewardTokens.length; i++){
            if(_listRewardTokens[i] == _token){
                thereIs = true;
                break;
            }
        }
        return thereIs;
    }

    function getUserStakedTokens(address _user) public view returns(uint[] memory){
        uint[] memory tokensId = new uint[](userInfo[_user].stakedTokensId.length);
        tokensId = userInfo[_user].stakedTokensId;
        return tokensId;
    }

    function getUserStakedRbAmount(address _user) public view returns(uint){
        return userInfo[_user].stakedRbAmount;
    }

    function getListRewardTokens() public view returns(address[] memory){
        address[] memory list = new address[](listRewardTokens.length);
        list = listRewardTokens;
        return list;
    }

    function addNewTokenReward(address _newToken, uint _startBlock, uint _rewardPerBlock) public onlyOwner {
        require(_newToken != address(0), "Address shouldn't be 0");
        require(isTokenInList(_newToken) == false, "Token is already in the list");
        listRewardTokens.push(_newToken);
        if(_startBlock == 0){
            rewardTokens[_newToken].startBlock = block.number + 1;
        } else {
            rewardTokens[_newToken].startBlock = _startBlock;
        }
        rewardTokens[_newToken].rewardPerBlock = _rewardPerBlock;
        rewardTokens[_newToken].enabled = true;

        emit AddNewTokenReward(_newToken);
    }

    function disableTokenReward(address _token) public onlyOwner {
        require(isTokenInList(_token), "Token not in the list");
        updatePool();
        rewardTokens[_token].enabled = false;
        emit DisableTokenReward(_token);
    }

    function enableTokenReward(address _token, uint _startBlock, uint _rewardPerBlock) public onlyOwner {
        require(isTokenInList(_token), "Token not in the list");
        require(!rewardTokens[_token].enabled, "Reward token is enabled");
        if(_startBlock == 0){
            _startBlock = block.number + 1;
        }
        require(_startBlock >= block.number, "Start block Must be later than current");
        rewardTokens[_token].enabled = true;
        rewardTokens[_token].startBlock = _startBlock;
        rewardTokens[_token].rewardPerBlock = _rewardPerBlock;
        emit ChangeTokenReward(_token, _rewardPerBlock);

        updatePool();
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint _from, uint _to) public pure returns (uint) {
        if(_to > _from){
            return _to - _from;
        } else {
            return 0;
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (address[] memory, uint[] memory) {
        UserInfo memory user = userInfo[_user];
        uint[] memory rewards = new uint[](listRewardTokens.length);
        if(user.stakedRbAmount == 0){
            return (listRewardTokens, rewards);
        }
        uint _totalNFTSupply = totalNFTSupply;
        uint _multiplier = getMultiplier(lastRewardBlock, block.number);
        uint _accTokenPerShare = 0;
        for(uint i = 0; i < listRewardTokens.length; i++){
            address curToken = listRewardTokens[i];
            RewardToken memory curRewardToken = rewardTokens[curToken];
            if (_multiplier != 0 && _totalNFTSupply != 0 && curRewardToken.enabled == true) {
                uint curMultiplier;
                if(getMultiplier(curRewardToken.startBlock, block.number) < _multiplier){
                    curMultiplier = getMultiplier(curRewardToken.startBlock, block.number);
                } else {
                    curMultiplier = _multiplier;
                }
                _accTokenPerShare = curRewardToken.accTokenPerShare +
                (curMultiplier * curRewardToken.rewardPerBlock * 1e12 / _totalNFTSupply);
            } else {
                _accTokenPerShare = curRewardToken.accTokenPerShare;
            }
            rewards[i] = (user.stakedRbAmount * _accTokenPerShare / 1e12) - rewardDebt[_user][curToken];
        }
        return (listRewardTokens, rewards);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        uint multiplier = getMultiplier(lastRewardBlock, block.number);
        uint _totalNFTSupply = totalNFTSupply; //Gas safe

        if(multiplier == 0){
            return;
        }
        lastRewardBlock = block.number;
        if(_totalNFTSupply == 0){
            return;
        }
        for(uint i = 0; i < listRewardTokens.length; i++){
            address curToken = listRewardTokens[i];
            RewardToken memory curRewardToken = rewardTokens[curToken];
            if(curRewardToken.enabled == false || curRewardToken.startBlock >= block.number){
                continue;
            } else {
                uint curMultiplier;
                if(getMultiplier(curRewardToken.startBlock, block.number) < multiplier){
                    curMultiplier = getMultiplier(curRewardToken.startBlock, block.number);
                } else {
                    curMultiplier = multiplier;
                }
                uint tokenReward = curRewardToken.rewardPerBlock * curMultiplier;
                rewardTokens[curToken].rewardsForWithdrawal += tokenReward;
                rewardTokens[curToken].accTokenPerShare += (tokenReward * 1e12) / _totalNFTSupply;
            }
        }
    }

    function withdrawReward() public {
        _withdrawReward();
    }

    function _updateRewardDebt(address _user) internal {
        for(uint i = 0; i < listRewardTokens.length; i++){
            rewardDebt[_user][listRewardTokens[i]] = userInfo[_user].stakedRbAmount * rewardTokens[listRewardTokens[i]].accTokenPerShare / 1e12;
        }
    }

    //SCN-01, SFR-02
    function _withdrawReward() internal {
        updatePool();
        UserInfo memory user = userInfo[msg.sender];
        address[] memory _listRewardTokens = listRewardTokens;
        if(user.stakedRbAmount == 0){
            return;
        }
        for(uint i = 0; i < _listRewardTokens.length; i++){
            RewardToken storage curRewardToken = rewardTokens[_listRewardTokens[i]];
            uint pending = user.stakedRbAmount * curRewardToken.accTokenPerShare / 1e12 - rewardDebt[msg.sender][_listRewardTokens[i]];
            if(pending > 0){
                curRewardToken.rewardsForWithdrawal -= pending;
                rewardDebt[msg.sender][_listRewardTokens[i]] = user.stakedRbAmount * curRewardToken.accTokenPerShare / 1e12;
                IERC20(_listRewardTokens[i]).safeTransfer(address(msg.sender), pending);
            }
        }
    }

    function removeTokenIdFromUserInfo(uint index, address user) internal {
        uint[] storage tokensId = userInfo[user].stakedTokensId;
        tokensId[index] = tokensId[tokensId.length - 1];
        tokensId.pop();
    }

    // Stake _NFT tokens to SmartChefNFT
    //BNF-02, SFR-02
    function stake(uint[] calldata tokensId) public nonReentrant {
        _withdrawReward();
        uint depositedBoost = 0;
        for(uint i = 0; i < tokensId.length; i++){
            (address tokenOwner, , uint level, bool stakeFreeze) = nftToken.getInfoForStaking(tokensId[i]);
            require(tokenOwner == msg.sender, "Not token owner");
            require(stakeFreeze == false, "Token has already been staked");
           
            nftToken.tokenFreeze(tokensId[i]);
            depositedBoost += level;
            userInfo[msg.sender].stakedTokensId.push(tokensId[i]);
        }
        if(depositedBoost > 0){
            userInfo[msg.sender].stakedRbAmount += depositedBoost;
            totalNFTSupply += depositedBoost;
        }
        _updateRewardDebt(msg.sender);
        emit StakeTokens(msg.sender, depositedBoost, tokensId);
    }

    // Withdraw _NFT tokens from STAKING.
    //BNF-02, SFR-02
    function unstake(uint[] calldata tokensId) public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.stakedTokensId.length >= tokensId.length, "Wrong token count given");
        uint withdrawalBAmount = 0;
        _withdrawReward();
        bool findToken;
        for(uint i = 0; i < tokensId.length; i++){
            findToken = false;
            for(uint j = 0; j < user.stakedTokensId.length; j++){
                if(tokensId[i] == user.stakedTokensId[j]){
                    removeTokenIdFromUserInfo(j, msg.sender);
                (, , uint level, ) = nftToken.getInfoForStaking(tokensId[i]);
   
                    withdrawalBAmount += level;
                    nftToken.tokenUnfreeze(tokensId[i]);
                    findToken = true;
                    break;
                }
            }
            require(findToken, "Token not staked by user");
        }
        if(withdrawalBAmount > 0){
            user.stakedRbAmount -= withdrawalBAmount;
            totalNFTSupply -= withdrawalBAmount;
            _updateRewardDebt(msg.sender);
        }
        emit UnstakeToken(msg.sender, withdrawalBAmount, tokensId);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyUnstake() public {
        uint[] memory tokensId = userInfo[msg.sender].stakedTokensId;
        totalNFTSupply -= userInfo[msg.sender].stakedRbAmount;
        delete userInfo[msg.sender];
        for(uint i = 0; i < listRewardTokens.length; i++){
            delete rewardDebt[msg.sender][listRewardTokens[i]];
        }
        for(uint i = 0; i < tokensId.length; i++){
            nftToken.tokenUnfreeze(tokensId[i]);
        }
        emit EmergencyWithdraw(msg.sender, tokensId.length);
    }

    // Withdraw reward token. EMERGENCY ONLY.
    function emergencyRewardTokenWithdraw(address _token, uint256 _amount) public onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Not enough balance");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}