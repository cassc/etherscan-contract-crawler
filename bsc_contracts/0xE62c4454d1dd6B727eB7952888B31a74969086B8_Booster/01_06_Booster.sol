// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/Interfaces.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";

/**
 * @title   Booster
 * @author  ConvexFinance -> WombexFinance
 * @notice  Main deposit contract; keeps track of pool info & user deposits; distributes rewards.
 * @dev     They say all paths lead to Rome, and the Booster is no different. This is where it all goes down.
 *          It is responsible for tracking all the pools, it collects rewards from all pools and redirects it.
 */
contract Booster{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public constant MAX_DISTRIBUTION = 2500;
    uint256 public constant MAX_EARMARK_INCENTIVE = 100;
    uint256 public constant MAX_PENALTY_SHARE = 3000;
    uint256 public constant DENOMINATOR = 10000;

    address public immutable crv;
    address public immutable cvx;
    address public immutable voterProxy;

    address public owner;
    address public feeManager;
    address public poolManager;
    address public rewardFactory;
    address public tokenFactory;
    address public voteDelegate;
    address public crvLockRewards;
    address public cvxLocker;

    IExtraRewardsDistributor public extraRewardsDist;

    uint256 public penaltyShare = 0;
    uint256 public earmarkIncentive;

    uint256 public minMintRatio;
    uint256 public maxMintRatio;
    uint256 public mintRatio;

    mapping(address => TokenDistro[]) public distributionByTokens;
    struct TokenDistro {
        address distro;
        uint256 share;
        bool callQueue;
    }
    address[] distributionTokens;

    bool public isShutdown;

    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        bool shutdown;
    }

    //index(pid) -> pool
    PoolInfo[] public poolInfo;
    mapping(address => bool) public votingMap;

    event Deposited(address indexed user, uint256 indexed poolid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed poolid, uint256 amount);

    event PoolAdded(address indexed lpToken, address gauge, address token, address crvRewards, uint256 pid);
    event PoolShutdown(uint256 indexed poolId);
    event RewardMigrate(address indexed crvRewards, address indexed newBooster, uint256 indexed poolId);

    event OwnerUpdated(address newOwner);
    event FeeManagerUpdated(address newFeeManager);
    event PoolManagerUpdated(address newPoolManager);
    event FactoriesUpdated(address rewardFactory, address tokenFactory);
    event ExtraRewardsDistributorUpdated(address newDist);
    event PenaltyShareUpdated(uint256 newPenalty);
    event VoteDelegateUpdated(address newVoteDelegate);
    event VotingMapUpdated(address voting, bool valid);
    event LockRewardContractsUpdated(address lockRewards, address cvxLocker);
    event MintRatioUpdated(uint256 mintRatio);
    event SetEarmarkIncentive(uint256 earmarkIncentive);
    event FeeInfoUpdated(address feeDistro, address lockFees, address feeToken);
    event FeeInfoChanged(address feeToken, bool active);
    event TokenDistributionUpdate(address indexed token, address indexed distro, uint256 share, bool callQueue);
    event DistributionUpdate(address indexed token, uint256 distrosLength, uint256 sharesLength, uint256 callQueueLength, uint256 totalShares);

    event EarmarkRewards(address indexed token, uint256 amount);
    event RewardClaimed(uint256 indexed pid, address indexed user, uint256 amount, bool indexed lock, uint256 mintAmount, uint256 penalty);

    /**
     * @dev Constructor doing what constructors do. It is noteworthy that
     *      a lot of basic config is set to 0 - expecting subsequent calls to setFeeInfo etc.
     * @param _voterProxy                 VoterProxy (locks the crv and adds to all gauges)
     * @param _cvx                    CVX/WMX token
     * @param _crv                    CRV/WOM
     */
    constructor(
        address _voterProxy,
        address _cvx,
        address _crv,
        uint256 _minMintRatio,
        uint256 _maxMintRatio
    ) public {
        voterProxy = _voterProxy;
        cvx = _cvx;
        crv = _crv;
        isShutdown = false;

        minMintRatio = _minMintRatio;
        maxMintRatio = _maxMintRatio;

        owner = msg.sender;
        voteDelegate = msg.sender;
        feeManager = msg.sender;
        poolManager = msg.sender;

        emit OwnerUpdated(msg.sender);
        emit VoteDelegateUpdated(msg.sender);
        emit FeeManagerUpdated(msg.sender);
        emit PoolManagerUpdated(msg.sender);
    }


    /// SETTER SECTION ///

    /**
     * @notice Owner is responsible for setting initial config, updating vote delegate and shutting system
     */
    function setOwner(address _owner) external {
        require(msg.sender == owner, "!auth");
        owner = _owner;

        emit OwnerUpdated(_owner);
    }

    /**
     * @notice Fee Manager can update the fees (lockIncentive, stakeIncentive, earmarkIncentive, platformFee)
     */
    function setFeeManager(address _feeM) external {
        require(msg.sender == owner, "!auth");
        feeManager = _feeM;

        emit FeeManagerUpdated(_feeM);
    }

    /**
     * @notice Pool manager is responsible for adding new pools
     */
    function setPoolManager(address _poolM) external {
        require(msg.sender == poolManager, "!auth");
        poolManager = _poolM;

        emit PoolManagerUpdated(_poolM);
    }

    /**
     * @notice Factories are used when deploying new pools.
     */
    function setFactories(address _rfactory, address _tfactory) external {
        require(msg.sender == owner, "!auth");
        require(rewardFactory == address(0), "!zero");

        //reward factory only allow this to be called once even if owner
        //removes ability to inject malicious staking contracts
        //token factory can also be immutable
        rewardFactory = _rfactory;
        tokenFactory = _tfactory;

        emit FactoriesUpdated(_rfactory, _tfactory);
    }

    /**
     * @notice Extra rewards distributor handles cvx/wmx penalty
     */
    function setExtraRewardsDistributor(address _dist) external {
        require(msg.sender==owner, "!auth");
        extraRewardsDist = IExtraRewardsDistributor(_dist);

        IERC20(cvx).safeApprove(_dist, 0);
        IERC20(cvx).safeApprove(_dist, type(uint256).max);

        emit ExtraRewardsDistributorUpdated(_dist);
    }

    /**
     * @notice Extra rewards distributor handles cvx/wmx penalty
     */
    function setRewardClaimedPenalty(uint256 _penaltyShare) external {
        require(msg.sender==owner, "!auth");
        require(_penaltyShare <= MAX_PENALTY_SHARE, ">max");
        penaltyShare = _penaltyShare;

        emit PenaltyShareUpdated(_penaltyShare);
    }

    function setRewardTokenPausedInPools(address[] memory _rewardPools, address _token, bool _paused) external {
        require(msg.sender==owner, "!auth");

        for (uint256 i = 0; i < _rewardPools.length; i++) {
            IRewards(_rewardPools[i]).setRewardTokenPaused(_token, _paused);
        }
    }

    /**
     * @notice Vote Delegate has the rights to cast votes on the VoterProxy via the Booster
     */
    function setVoteDelegate(address _voteDelegate) external {
        require(msg.sender==owner, "!auth");
        voteDelegate = _voteDelegate;

        emit VoteDelegateUpdated(_voteDelegate);
    }

    /**
     * @notice Vote Delegate has the rights to cast votes on the VoterProxy via the Booster
     */
    function setVotingValid(address _voting, bool _valid) external {
        require(msg.sender==owner, "!auth");
        votingMap[_voting] = _valid;

        emit VotingMapUpdated(_voting, _valid);
    }

    /**
     * @notice Only called once, to set the address of cvxCrv/wmxWOM (lockRewards)
     */
    function setLockRewardContracts(address _crvLockRewards, address _cvxLocker) external {
        require(msg.sender == owner, "!auth");

        //reward contracts are immutable or else the owner
        //has a means to redeploy and mint cvx/wmx via rewardClaimed()
        if (crvLockRewards == address(0)){
            crvLockRewards = _crvLockRewards;
            cvxLocker = _cvxLocker;
            IERC20(cvx).approve(cvxLocker, type(uint256).max);
            emit LockRewardContractsUpdated(_crvLockRewards, _cvxLocker);
        }
    }

    /**
     * @notice Change mint ratio in boundaries
     */
    function setMintRatio(uint256 _mintRatio) external {
        require(msg.sender == owner, "!auth");
        if (_mintRatio != 0) {
            require(_mintRatio >= minMintRatio && _mintRatio <= maxMintRatio, "!boundaries");
        }

        mintRatio = _mintRatio;
        emit MintRatioUpdated(_mintRatio);
    }

    /**
     * @notice Allows turning off or on for fee distro
     */
    function updateDistributionByTokens(address _token, address[] memory _distros, uint256[] memory _shares, bool[] memory _callQueue) external {
        require(msg.sender==owner, "!auth");
        uint256 len = _distros.length;
        require(len==_shares.length && len==_callQueue.length, "!length");

        if (distributionByTokens[_token].length == 0) {
            distributionTokens.push(_token);
        }

        uint256 curLen = distributionByTokens[_token].length;
        for (uint256 i = 0; i < curLen; i++) {
            address distro = distributionByTokens[_token][distributionByTokens[_token].length - 1].distro;
            IERC20(_token).safeApprove(distro, 0);
            distributionByTokens[_token].pop();
        }

        uint256 totalShares = 0;
        for (uint256 i = 0; i < len; i++) {
            require(_distros[i] != address(0), "!distro");
            totalShares = totalShares.add(_shares[i]);
            distributionByTokens[_token].push(TokenDistro(_distros[i], _shares[i], _callQueue[i]));
            emit TokenDistributionUpdate(_token, _distros[i], _shares[i], _callQueue[i]);

            if (_callQueue[i]) {
                IERC20(_token).safeApprove(_distros[i], 0);
                IERC20(_token).safeApprove(_distros[i], type(uint256).max);
            }
        }
        require(totalShares <= MAX_DISTRIBUTION, ">max");

        uint256 poolLen = poolInfo.length;
        for (uint256 i = 0; i < poolLen; i++) {
            IERC20(_token).safeApprove(poolInfo[i].crvRewards, 0);
            IERC20(_token).safeApprove(poolInfo[i].crvRewards, type(uint256).max);
        }

        emit DistributionUpdate(_token, _distros.length, _shares.length, _callQueue.length, totalShares);
    }

    /**
     * @notice Fee manager can set all the relevant fees
     * @param _earmarkIncentive   % for whoever calls the claim where 1% == 100
     */
    function setEarmarkIncentive(uint256 _earmarkIncentive) external{
        require(msg.sender==feeManager, "!auth");
        require(_earmarkIncentive <= MAX_EARMARK_INCENTIVE, ">max");
        earmarkIncentive = _earmarkIncentive;
        emit SetEarmarkIncentive(_earmarkIncentive);
    }

    /// END SETTER SECTION ///

    /**
     * @notice Called by the PoolManager (i.e. PoolManagerProxy) to add a new pool - creates all the required
     *         contracts (DepositToken, RewardPool) and then adds to the list!
     */
    function addPool(address _lptoken, address _gauge) external returns(bool){
        //the next pool's pid
        uint256 pid = poolInfo.length;

        //create a tokenized deposit
        address token = ITokenFactory(tokenFactory).CreateDepositToken(_lptoken);
        //create a reward contract for crv rewards
        address newRewardPool = IRewardFactory(rewardFactory).CreateCrvRewards(pid,token,_lptoken);

        return addCreatedPool(_lptoken, _gauge, token, newRewardPool);
    }


    /**
     * @notice Called by the PoolManager (i.e. PoolManagerProxy) to add a new pool - creates all the required
     *         contracts (DepositToken, RewardPool) and then adds to the list!
     */
    function addCreatedPool(address _lptoken, address _gauge, address _token, address _crvRewards) public returns(bool){
        require(msg.sender==poolManager && !isShutdown, "!add");
        require(_gauge != address(0) && _lptoken != address(0),"!param");

        //the next pool's pid
        uint256 pid = poolInfo.length;

        if (IRewards(_crvRewards).pid() != pid) {
            IRewards(_crvRewards).updateOperatorData(address(this), pid);
        }

        IERC20(_token).safeApprove(_crvRewards, 0);
        IERC20(_token).safeApprove(_crvRewards, type(uint256).max);

        //add the new pool
        poolInfo.push(
            PoolInfo({
                lptoken: _lptoken,
                token: _token,
                gauge: _gauge,
                crvRewards: _crvRewards,
                shutdown: false
            })
        );

        uint256 distTokensLen = distributionTokens.length;
        for (uint256 i = 0; i < distTokensLen; i++) {
            IERC20(distributionTokens[i]).safeApprove(_crvRewards, 0);
            IERC20(distributionTokens[i]).safeApprove(_crvRewards, type(uint256).max);
        }

        emit PoolAdded(_lptoken, _gauge, _token, _crvRewards, pid);
        return true;
    }

    /**
     * @notice Shuts down the pool by withdrawing everything from the gauge to here (can later be
     *         claimed from depositors by using the withdraw fn) and marking it as shut down
     */
    function shutdownPool(uint256 _pid) external returns(bool){
        require(msg.sender==poolManager, "!auth");
        PoolInfo storage pool = poolInfo[_pid];

        //withdraw from gauge
        IStaker(voterProxy).withdrawAllLp(pool.lptoken,pool.gauge);

        pool.shutdown = true;

        emit PoolShutdown(_pid);
        return true;
    }

    /**
     * @notice Shuts down the pool and sets shutdown flag even if withdrawAllLp failed.
     */
    function forceShutdownPool(uint256 _pid) external returns(bool){
        require(msg.sender==poolManager, "!auth");
        PoolInfo storage pool = poolInfo[_pid];

        //withdraw from gauge
        try IStaker(voterProxy).withdrawAllLp(pool.lptoken, pool.gauge){} catch {}

        pool.shutdown = true;

        emit PoolShutdown(_pid);
        return true;
    }

    /**
     * @notice Shuts down the WHOLE SYSTEM by withdrawing all the LP tokens to here and then allowing
     *         for subsequent withdrawal by any depositors.
     */
    function shutdownSystem() external{
        require(msg.sender == owner, "!auth");
        isShutdown = true;

        for(uint i=0; i < poolInfo.length; i++){
            PoolInfo storage pool = poolInfo[i];
            if (pool.shutdown) continue;

            address token = pool.lptoken;
            address gauge = pool.gauge;

            //withdraw from gauge
            try IStaker(voterProxy).withdrawAllLp(token,gauge){
                pool.shutdown = true;
            }catch{}
        }
    }

    function migrateRewards(address[] calldata _rewards, uint256[] calldata _pids, address _newBooster) external {
        require(msg.sender == owner, "!auth");
        require(isShutdown, "!shutdown");

        uint256 len = _rewards.length;
        require(len == _pids.length, "!length");

        for (uint256 i = 0; i < len; i++) {
            if (_rewards[i] == address(0)) {
                continue;
            }
            IRewards(_rewards[i]).updateOperatorData(_newBooster, _pids[i]);
            if (_rewards[i] != crvLockRewards) {
                address stakingToken = IRewards(_rewards[i]).stakingToken();
                ITokenMinter(stakingToken).updateOperator(_newBooster);
            }
            emit RewardMigrate(_rewards[i], _newBooster, _pids[i]);
        }
    }

    /**
     * @notice  Deposits an "_amount" to a given gauge (specified by _pid), mints a `DepositToken`
     *          and subsequently stakes that on BaseRewardPool
     */
    function deposit(uint256 _pid, uint256 _amount, bool _stake) public returns(bool){
        return depositFor(_pid, _amount, _stake, msg.sender);
    }

    /**
     * @notice  Deposits an "_amount" to a given gauge (specified by _pid), mints a `DepositToken`
     *          and subsequently stakes that on BaseRewardPool
     */
    function depositFor(uint256 _pid, uint256 _amount, bool _stake, address _receiver) public returns(bool){
        require(!isShutdown,"shutdown");
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.shutdown == false, "pool is closed");

        //send to proxy to stake
        address lptoken = pool.lptoken;
        IERC20(lptoken).safeTransferFrom(msg.sender, voterProxy, _amount);

        //stake
        address gauge = pool.gauge;
        require(gauge != address(0),"!gauge setting");
        IStaker(voterProxy).deposit(lptoken, gauge);

        address token = pool.token;
        if(_stake){
            //mint here and send to rewards on user behalf
            ITokenMinter(token).mint(address(this), _amount);
            IRewards(pool.crvRewards).stakeFor(_receiver, _amount);
        }else{
            //add user balance directly
            ITokenMinter(token).mint(_receiver, _amount);
        }

        emit Deposited(_receiver, _pid, _amount);
        return true;
    }

    /**
     * @notice  Deposits all a senders balance to a given gauge (specified by _pid), mints a `DepositToken`
     *          and subsequently stakes that on BaseRewardPool
     */
    function depositAll(uint256 _pid, bool _stake) external returns(bool){
        address lptoken = poolInfo[_pid].lptoken;
        uint256 balance = IERC20(lptoken).balanceOf(msg.sender);
        deposit(_pid,balance,_stake);
        return true;
    }

    /**
     * @notice  Withdraws LP tokens from a given PID (& user).
     *          1. Burn the cvxLP/wmxLP balance from "_from" (implicit balance check)
     *          2. If pool !shutdown.. withdraw from gauge
     *          3. Transfer out the LP tokens
     */
    function _withdraw(uint256 _pid, uint256 _amount, address _from, address _to) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address lptoken = pool.lptoken;
        address gauge = pool.gauge;

        //remove lp balance
        address token = pool.token;
        ITokenMinter(token).burn(_from,_amount);

        //pull from gauge if not shutdown
        // if shutdown tokens will be in this contract
        if (!pool.shutdown) {
            IStaker(voterProxy).withdrawLp(lptoken, gauge, _amount);
        }

        //return lp tokens
        IERC20(lptoken).safeTransfer(_to, _amount);

        emit Withdrawn(_to, _pid, _amount);
    }

    /**
     * @notice  Withdraw a given amount from a pool (must already been unstaked from the Reward Pool -
     *          BaseRewardPool uses withdrawAndUnwrap to get around this)
     */
    function withdraw(uint256 _pid, uint256 _amount) public returns(bool){
        _withdraw(_pid,_amount,msg.sender,msg.sender);
        return true;
    }

    /**
     * @notice  Withdraw all the senders LP tokens from a given gauge
     */
    function withdrawAll(uint256 _pid) public returns(bool){
        address token = poolInfo[_pid].token;
        uint256 userBal = IERC20(token).balanceOf(msg.sender);
        withdraw(_pid, userBal);
        return true;
    }

    /**
     * @notice Allows the actual BaseRewardPool to withdraw and send directly to the user
     */
    function withdrawTo(uint256 _pid, uint256 _amount, address _to) external returns(bool){
        address rewardContract = poolInfo[_pid].crvRewards;
        require(msg.sender == rewardContract,"!auth");

        _withdraw(_pid,_amount,msg.sender,_to);
        return true;
    }

    /**
     * @notice set valid vote hash on VoterProxy
     */
    function setVote(bytes32 _hash, bool valid) external returns(bool){
        require(msg.sender == voteDelegate, "!auth");

        IStaker(voterProxy).setVote(_hash, valid);
        return true;
    }

    /**
     * @notice Delegate address votes on gauge weight via VoterProxy
     */
    function voteExecute(address _voting, uint256 _value, bytes calldata _data) external payable returns(bool) {
        require(msg.sender == voteDelegate, "!auth");
        require(votingMap[_voting], "!voting");

        IStaker(voterProxy).execute{value:_value}(_voting, _value, _data);
        return true;
    }

    /**
     * @notice Basically a hugely pivotal function.
     *         Responsible for collecting the crv/wom from gauge, and then redistributing to the correct place.
     *         Pays the caller a fee to process this.
     */
    function _earmarkRewards(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.shutdown == false, "pool is closed");

        address gauge = pool.gauge;
        //claim crv/wom and bonus tokens
        address[] memory tokens = IStaker(voterProxy).getGaugeRewardTokens(pool.lptoken, gauge);
        uint256 tLen = tokens.length;
        uint256[] memory balances = new uint256[](tLen);

        for (uint256 i = 0; i < tLen; i++) {
            balances[i] = IERC20(tokens[i]).balanceOf(address(this));
        }

        IStaker(voterProxy).claimCrv(pool.lptoken, gauge);

        for (uint256 i = 0; i < tLen; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 balance = token.balanceOf(address(this)).sub(balances[i]);

            emit EarmarkRewards(address(token), balance);

            if (balance == 0) {
                continue;
            }
            uint256 dLen = distributionByTokens[address(token)].length;
            require(dLen > 0, "!dLen");

            uint256 earmarkIncentiveAmount = balance.mul(earmarkIncentive).div(DENOMINATOR);
            uint256 sentSum = earmarkIncentiveAmount;

            for (uint256 j = 0; j < dLen; j++) {
                TokenDistro memory tDistro = distributionByTokens[address(token)][j];
                uint256 amount = balance.mul(tDistro.share).div(DENOMINATOR);
                if (tDistro.callQueue) {
                    IRewards(tDistro.distro).queueNewRewards(address(token), amount);
                } else {
                    token.safeTransfer(tDistro.distro, amount);
                }
                sentSum = sentSum.add(amount);
            }
            if (earmarkIncentiveAmount > 0) {
                token.safeTransfer(msg.sender, earmarkIncentiveAmount);
            }
            //send crv to lp provider reward contract
            IRewards(pool.crvRewards).queueNewRewards(address(token), balance.sub(sentSum));
        }
    }

    /**
     * @notice Basically a hugely pivotal function.
     *         Responsible for collecting the crv/wom from gauge, and then redistributing to the correct place.
     *         Pays the caller a fee to process this.
     */
    function earmarkRewards(uint256 _pid) external returns(bool){
        require(!isShutdown,"shutdown");
        _earmarkRewards(_pid);
        return true;
    }

    /**
     * @notice Callback from reward contract when crv/wom is received.
     * @dev    Goes off and mints a relative amount of CVX/WMX based on the distribution schedule.
     */
    function rewardClaimed(uint256 _pid, address _address, uint256 _amount, bool _lock) external returns(bool){
        address rewardContract = poolInfo[_pid].crvRewards;
        require(msg.sender == rewardContract || msg.sender == crvLockRewards, "!auth");

        uint256 mintAmount = _amount;
        if (mintRatio > 0) {
            mintAmount = mintAmount.mul(mintRatio).div(DENOMINATOR);
        }

        uint256 penalty;
        if (_lock) {
            uint256 balanceBefore = IERC20(cvx).balanceOf(address(this));
            ITokenMinter(cvx).mint(address(this), mintAmount);
            ICvxLocker(cvxLocker).lock(_address, IERC20(cvx).balanceOf(address(this)).sub(balanceBefore));
        } else {
            penalty = mintAmount.mul(penaltyShare).div(DENOMINATOR);
            mintAmount = mintAmount.sub(penalty);
            //mint reward to user, except the penalty
            ITokenMinter(cvx).mint(_address, mintAmount);
            if (penalty > 0) {
                uint256 balanceBefore = IERC20(cvx).balanceOf(address(this));
                ITokenMinter(cvx).mint(address(this), penalty);
                extraRewardsDist.addReward(cvx, IERC20(cvx).balanceOf(address(this)).sub(balanceBefore));
            }
        }
        emit RewardClaimed(_pid, _address, _amount, _lock, mintAmount, penalty);
        return true;
    }


    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function distributionByTokenLength(address _token) external view returns (uint256) {
        return distributionByTokens[_token].length;
    }

    function distributionTokenList() external view returns (address[] memory) {
        return distributionTokens;
    }
}