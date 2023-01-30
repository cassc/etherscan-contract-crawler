// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Interfaces.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/utils/Address.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/utils/Address.sol";
import { SafeERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";

/**
 * @title   GaugeVoting
 * @author  WombexFinance
 */
contract GaugeVoting is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant DENOMINATOR = 10000;

    IWmxLocker public wmxLocker;
    IBooster public booster;
    IBribeVoter public bribeVoter;
    address public voterProxy;
    IERC20 public veWom;

    ITokenFactory public tokenFactory;
    IBribesRewardFactory public bribeRewardsFactory;
    INftLocker public nftLocker;

    mapping(address => uint256) public userVotes;
    mapping(address => address) public lpTokenRewards;

    enum LpTokenStatus {
        NOT_EXISTS,
        ADDED,
        ACTIVE
    }
    mapping(address => LpTokenStatus) public lpTokenStatus;
    address[] public lpTokensAdded;

    ITokenMinter public stakingToken;
    uint256 public lastVoteAt;
    uint256 public votePeriod;
    uint256 public voteIncentive;
    uint256 public voteThreshold;
    bool public executeOnVote;

    event SetVotingConfig(uint256 votePeriod, uint256 voteThreshold, uint256 voteIncentive, bool executeOnVote);
    event SetNftLocker(address indexed nftLocker);
    event SetFactories(address indexed tokenFactory, address indexed rewardFactory);
    event AddLpToken(address indexed lpToken, address indexed rewards);
    event SetLpTokenStatus(address indexed lpToken, LpTokenStatus indexed status);
    event StakingTokenMigrate(address indexed newOperator);
    event RewardPoolMigrate(address indexed rewards, address indexed newOperator);
    event Vote(address[] lpTokens, int256[] deltas, uint256 availableVotes, uint256 votedAmount);
    event DistributeBribeRewards(address indexed lpToken, address indexed rewardsPool, address indexed bribe, address[] rewardTokens, uint256[] rewardAmounts);
    event TransferRewards(address indexed lpToken, address indexed rewardToken, address indexed recipient, uint256 rewardAmount, bool queueRewards);
    event VoteExecute(address[] lpTokens, int256[] deltas, int256[] votes);

    constructor(
        IWmxLocker _wmxLocker,
        IBooster _booster,
        IBribeVoter _bribeVoter
    ) {
        wmxLocker = _wmxLocker;
        booster = _booster;
        voterProxy = _booster.voterProxy();
        veWom = IERC20(IStaker(voterProxy).veWom());
        bribeVoter = _bribeVoter;
    }

    function setVotingConfig(uint256 _votePeriod, uint256 _voteThreshold, uint256 _voteIncentive, bool _executeOnVote) public onlyOwner {
        require(_voteIncentive <= 1000, "voteIncentive>1000");
        votePeriod = _votePeriod;
        voteThreshold = _voteThreshold;
        voteIncentive = _voteIncentive;
        executeOnVote = _executeOnVote;
        emit SetVotingConfig(_votePeriod, _voteThreshold, _voteIncentive, _executeOnVote);
    }

    function setNftLocker(INftLocker _nftLocker) public onlyOwner {
        nftLocker = _nftLocker;
        emit SetNftLocker(address(_nftLocker));
    }

    function setFactories(address _tokenFactory, address _rewardFactory, address _stakingToken) public onlyOwner {
        require(address(tokenFactory) == address(0), "!zero");
        tokenFactory = ITokenFactory(_tokenFactory);
        bribeRewardsFactory = IBribesRewardFactory(_rewardFactory);

        if (_stakingToken == address(0)) {
            stakingToken = ITokenMinter(tokenFactory.CreateBribesVotingToken());
        } else {
            stakingToken = ITokenMinter(_stakingToken);
        }

        emit SetFactories(_tokenFactory, _rewardFactory);
    }

    function approveRewards(address[] memory _rewardTokens) external onlyOwner {
        uint256 lpLen = lpTokensAdded.length;
        for (uint256 i = 0; i < lpLen; i++) {
            address rewardPool = lpTokenRewards[lpTokensAdded[i]];
            uint256 rtLen = _rewardTokens.length;
            for (uint256 j = 0; j < rtLen; j++) {
                IERC20(_rewardTokens[j]).approve(rewardPool, 0);
                IERC20(_rewardTokens[j]).approve(rewardPool, type(uint256).max);
            }
        }
    }

    function updateBribeRewardsConfig(address[] calldata _rewards, bool _callOperatorOnGetReward) external onlyOwner {
        for(uint256 i = 0; i < _rewards.length; i++) {
            IBribeRewardsPool(_rewards[i]).updateBribesConfig(_callOperatorOnGetReward);
        }
    }

    function updateRatioConfig(address[] calldata _rewards, uint256 _duration, uint256 _newRewardRatio) external onlyOwner {
        require(_duration >= 60 && _duration <= 30 days, "!duration");
        require(_newRewardRatio > 0, "!maxRewardRatio");

        for(uint256 i = 0; i < _rewards.length; i++) {
            IBribeRewardsPool(_rewards[i]).updateRatioConfig(_duration, _newRewardRatio);
        }
    }

    function setRewardTokenPausedInPools(address[] memory _rewardPools, address _token, bool _paused) external onlyOwner {
        for (uint256 i = 0; i < _rewardPools.length; i++) {
            IRewards(_rewardPools[i]).setRewardTokenPaused(_token, _paused);
        }
    }

    function migrateStakingToken(address _newOperator) external onlyOwner {
        stakingToken.updateOperator(_newOperator);
        emit StakingTokenMigrate(_newOperator);
    }

    function migrateRewards(address[] calldata _rewards, address _newOperator) external onlyOwner {
        uint256 len = _rewards.length;

        for (uint256 i = 0; i < len; i++) {
            IRewards(_rewards[i]).updateOperatorData(_newOperator, 0);
            emit RewardPoolMigrate(_rewards[i], _newOperator);
        }
    }

    function registerLpTokens(address[] memory _lpTokens) external onlyOwner {
        uint256 len = _lpTokens.length;
        for (uint256 i = 0; i < len; i++) {
            _registerLpToken(_lpTokens[i]);
        }
    }

    function registerCreatedLpTokens(address[] memory _lpTokens, address[] memory _rewards) external onlyOwner {
        uint256 len = _lpTokens.length;
        require(len == _rewards.length, "!len");
        for (uint256 i = 0; i < len; i++) {
            _registerCreatedLpToken(_lpTokens[i], _rewards[i]);
        }
    }

    function setLpTokenStatus(address _lpToken, LpTokenStatus _status) public onlyOwner {
        require(lpTokenStatus[_lpToken] != LpTokenStatus.NOT_EXISTS, "already exists");
        lpTokenStatus[_lpToken] = _status;
        emit SetLpTokenStatus(_lpToken, _status);
    }

    function _registerLpToken(address _lpToken) internal {
        _registerCreatedLpToken(_lpToken, bribeRewardsFactory.CreateBribesRewards(address(stakingToken), _lpToken, true));
    }

    function _registerCreatedLpToken(address _lpToken, address _rewards) internal {
        require(lpTokenStatus[_lpToken] == LpTokenStatus.NOT_EXISTS, "already exists");
        lpTokenStatus[_lpToken] = LpTokenStatus.ACTIVE;

        lpTokensAdded.push(_lpToken);
        lpTokenRewards[_lpToken] = _rewards;

        stakingToken.approve(_rewards, 0);
        stakingToken.approve(_rewards, type(uint256).max);

        emit AddLpToken(_lpToken, _rewards);
    }

    function vote(address[] memory _lpTokens, int256[] memory _deltas) public {
        uint256 len = _lpTokens.length;
        require(len == _deltas.length, "!len");
        uint256 userLockerVotes = boostedUserVotes(msg.sender, true);
        require(userLockerVotes != 0, "no votes");

        int256 lastDelta = 0;

        for (uint256 i = 0; i < len; i++) {
            require(lpTokenStatus[_lpTokens[i]] == LpTokenStatus.ACTIVE, "only active");
            require(i == 0 || _deltas[i] >= lastDelta, "< lastDelta");
            lastDelta = _deltas[i];
            address rewards = lpTokenRewards[_lpTokens[i]];

            IBribeRewardsPool rewardsPool = IBribeRewardsPool(rewards);
            uint256 amount = _deltas[i] < 0 ? uint256(-_deltas[i]) : uint256(_deltas[i]);
            if (_deltas[i] < 0) {
                _rewardPoolWithdraw(rewardsPool, msg.sender, amount, msg.sender);
            } else if (_deltas[i] > 0) {
                _rewardPoolDeposit(rewardsPool, msg.sender, amount, msg.sender);
            }
        }

        require(userVotes[msg.sender] <= userLockerVotes, "votes overflow");

        emit Vote(_lpTokens, _deltas, userLockerVotes, userVotes[msg.sender]);

        if (executeOnVote && isVoteExecuteReady()) {
            voteExecute(msg.sender);
        }
    }

    function _rewardPoolWithdraw(IBribeRewardsPool _rewardsPool, address _user, uint256 _amount, address _claimFor) internal {
        userVotes[_user] -= _amount;
        _rewardsPool.withdrawAndUnwrapFrom(_user, _amount, _claimFor);
        stakingToken.burn(address(_rewardsPool), _amount);
    }

    function _rewardPoolDeposit(IBribeRewardsPool _rewardsPool, address _user, uint256 _amount, address _claimFor) internal {
        userVotes[_user] += _amount;
        stakingToken.mint(address(this), _amount);
        _rewardsPool.stakeFor(_user, _amount);
    }

    function voteExecute(address _incentiveRecipient) public {
        require(isVoteExecuteReady(), "!ready");

        (int256[] memory deltas, int256[] memory votes) = getVotesDelta();
        if (deltas.length == 0) {
            return;
        }

        bytes memory rewardsData = booster.voteExecute(
            address(bribeVoter),
            0,
            abi.encodeWithSelector(IBribeVoter.vote.selector, lpTokensAdded, deltas)
        );

        uint256[][] memory bribeRewards = abi.decode(rewardsData, (uint256[][]));
        for (uint256 i = 0; i < deltas.length; i++) {
            address lpToken = lpTokensAdded[i];
            if (lpTokenStatus[lpToken] != LpTokenStatus.ACTIVE) {
                continue;
            }

            uint256[] memory rewards = bribeRewards[i];
            (, , , , , , address bribe) = bribeVoter.infos(lpToken);
            address[] memory rewardTokens = IMasterWombatRewarder(bribe).rewardTokens();

            uint256 tLen = rewardTokens.length;
            for (uint256 j = 0; j < tLen; j++) {
                uint256 amount = rewards[j];
                booster.voteExecute( //TODO: check return data
                    rewardTokens[j],
                    0,
                    abi.encodeWithSelector(IERC20.transfer.selector, address(this), amount)
                );
                uint256 incentiveAmount = amount * voteIncentive / DENOMINATOR;
                if (incentiveAmount > 0) {
                    IERC20(rewardTokens[j]).safeTransfer(_incentiveRecipient, incentiveAmount);
                    emit TransferRewards(lpToken, rewardTokens[j], _incentiveRecipient, incentiveAmount, false);
                }
                IBribeRewardsPool(lpTokenRewards[lpToken]).queueNewRewards(rewardTokens[j], amount - incentiveAmount);
                emit TransferRewards(lpToken, rewardTokens[j], lpTokenRewards[lpToken], amount - incentiveAmount, true);
            }
            emit DistributeBribeRewards(lpToken, lpTokenRewards[lpToken], bribe, rewardTokens, rewards);
        }

        emit VoteExecute(lpTokensAdded, deltas, votes);
    }

    function getVotesDelta() public view returns (int256[] memory deltas, int256[] memory votes) {
        uint256 totalVotesAmount = totalVotes();
        if (totalVotesAmount == 0) {
            return (deltas, votes);
        }

        uint256 ratio = veWom.totalSupply() * 1 ether / totalVotesAmount;
        deltas = new int256[](lpTokensAdded.length);
        votes = new int256[](lpTokensAdded.length);
        for (uint256 i = 0; i < deltas.length; i++) {
            address lpToken = lpTokensAdded[i];
            address rewardsPool = lpTokenRewards[lpToken];
            int256 bribeVotes = int256(bribeVoter.votes(voterProxy, lpToken));
            votes[i] = int256(IERC20(rewardsPool).totalSupply() * ratio) / 1 ether;
            deltas[i] = votes[i] - bribeVotes;
        }
    }

    function rewardClaimed(uint256, address _account, uint256, bool) external {
        IBribeRewardsPool rewardsPool = IBribeRewardsPool(msg.sender);
        address asset = rewardsPool.asset();
        require(lpTokenRewards[asset] == msg.sender, "!lpTokenRewards");

        _onVotesChanged(_account, _account, _account);
        if (executeOnVote && isVoteExecuteReady()) {
            voteExecute(_account);
        }
    }

    function onVotesChanged(address _user, address _incentiveRecipient) public {
        address msgSender = msg.sender == address(nftLocker) ? _user : msg.sender;
        _onVotesChanged(_user, _incentiveRecipient, msgSender);
    }

    function _onVotesChanged(address _user, address _incentiveRecipient, address _msgSender) internal {
        if (boostedUserVotes(_user, _user == _msgSender) >= userVotes[_user]) {
            return;
        }

        uint256 len = lpTokensAdded.length;
        for (uint256 i = 0; i < len; i++) {
            IBribeRewardsPool rewardsPool = IBribeRewardsPool(lpTokenRewards[lpTokensAdded[i]]);
            _rewardPoolWithdraw(rewardsPool, _user, rewardsPool.balanceOf(_user), _incentiveRecipient);
        }
    }

    function isVoteExecuteReady() public view returns(bool) {
        return stakingToken.totalSupply() >= voteThreshold && isPeriodReady();
    }

    function isPeriodReady() public view returns(bool) {
        return lastVoteAt + votePeriod < block.timestamp;
    }

    function totalVotes() public view returns (uint256) {
        return stakingToken.totalSupply();
    }

    function getLpTokensAdded() external view returns (address[] memory) {
        return lpTokensAdded;
    }

    function boostedUserVotes(address _user, bool _locked) public view returns (uint256 userLockerVotes) {
        (uint256 totalBalance, , uint256 lockedBalance, ) = wmxLocker.lockedBalances(_user);
        userLockerVotes = _locked ? lockedBalance : totalBalance;
        if (address(nftLocker) != address(0)) {
            userLockerVotes = userLockerVotes * nftLocker.voteBoost(_user) / 1 ether;
        }
    }
}