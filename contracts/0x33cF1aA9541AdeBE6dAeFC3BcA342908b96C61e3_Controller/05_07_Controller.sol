// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./utils/Interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils/MathUtil.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Controller contract
/// @dev Controller contract for Prime Pools is based on the convex Booster.sol contract
contract Controller is IController {
    using SafeERC20 for IERC20;
    using MathUtil for uint256;

    event OwnerChanged(address _newOwner);
    event FeeManagerChanged(address _newFeeManager);
    event PoolManagerChanged(address _newPoolManager);
    event TreasuryChanged(address _newTreasury);
    event VoteDelegateChanged(address _newVoteDelegate);
    event FeesChanged(uint256 _newPlatformFee, uint256 _newProfitFee);
    event PoolShutDown(uint256 _pid);
    event FeeTokensCleared();
    event AddedPool(
        uint256 _pid,
        address _lpToken,
        address _token,
        address _gauge,
        address _baseRewardsPool,
        address _stash
    );
    event Deposited(address _user, uint256 _pid, uint256 _amount, bool _stake);
    event Withdrawn(address _user, uint256 _pid, uint256 _amount);
    event SystemShutdown();

    error Unauthorized();
    error Shutdown();
    error PoolIsClosed();
    error InvalidParameters();
    error InvalidStash();
    error RedirectFailed();

    uint256 public constant MAX_FEES = 3000;
    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public constant MAX_LOCK_TIME = 365 days; // 1 year is the time for the new deposided tokens to be locked until they can be withdrawn

    address public immutable bal;
    address public immutable staker;
    address public immutable feeDistro; // Balancer FeeDistributor

    uint256 public profitFees = 250; //2.5% // FEE_DENOMINATOR/100*2.5
    uint256 public platformFees = 1000; //10% //possible fee to build treasury

    address public owner;
    address public feeManager;
    address public poolManager;
    address public rewardFactory;
    address public stashFactory;
    address public tokenFactory;
    address public voteDelegate;
    address public treasury;
    address public lockRewards;

    // Balancer supports rewards in multiple fee tokens
    IERC20[] public feeTokens;
    // Fee token to VirtualBalanceReward pool mapping
    mapping(address => address) public feeTokenToPool;

    bool public isShutdown;
    bool public canClaim;

    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address balRewards;
        address stash;
        bool shutdown;
    }

    //index(pid) -> pool
    PoolInfo[] public poolInfo;
    mapping(address => bool) public gaugeMap;

    constructor(
        address _staker,
        address _bal,
        address _feeDistro
    ) {
        bal = _bal;
        feeDistro = _feeDistro;
        staker = _staker;
        owner = msg.sender;
        voteDelegate = msg.sender;
        feeManager = msg.sender;
        poolManager = msg.sender;
    }

    modifier onlyAddress(address authorizedAddress) {
        if (msg.sender != authorizedAddress) {
            revert Unauthorized();
        }
        _;
    }

    modifier isNotShutDown() {
        if (isShutdown) {
            revert Shutdown();
        }
        _;
    }

    /// SETTER SECTION ///

    /// @notice sets the owner variable
    /// @param _owner The address of the owner of the contract
    function setOwner(address _owner) external onlyAddress(owner) {
        owner = _owner;
        emit OwnerChanged(_owner);
    }

    /// @notice sets the feeManager variable
    /// @param _feeM The address of the fee manager
    function setFeeManager(address _feeM) external onlyAddress(feeManager) {
        feeManager = _feeM;
        emit FeeManagerChanged(_feeM);
    }

    /// @notice sets the poolManager variable
    /// @param _poolM The address of the pool manager
    function setPoolManager(address _poolM) external onlyAddress(poolManager) {
        poolManager = _poolM;
        emit PoolManagerChanged(_poolM);
    }

    /// @notice sets the reward, token, and stash factory addresses
    /// @param _rfactory The address of the reward factory
    /// @param _sfactory The address of the stash factory
    /// @param _tfactory The address of the token factory
    function setFactories(
        address _rfactory,
        address _sfactory,
        address _tfactory
    ) external onlyAddress(owner) {
        //reward factory only allow this to be called once even if owner
        //removes ability to inject malicious staking contracts
        //token factory can also be immutable
        if (rewardFactory == address(0)) {
            rewardFactory = _rfactory;
            tokenFactory = _tfactory;
        }

        //stash factory should be considered more safe to change
        //updating may be required to handle new types of gauges
        stashFactory = _sfactory;
    }

    /// @notice sets the voteDelegate variable
    /// @param _voteDelegate The address of whom votes will be delegated to
    function setVoteDelegate(address _voteDelegate) external onlyAddress(voteDelegate) {
        voteDelegate = _voteDelegate;
        emit VoteDelegateChanged(_voteDelegate);
    }

    /// @notice sets the lockRewards variable
    /// @param _rewards The address of the rewards contract
    function setRewardContracts(address _rewards) external onlyAddress(owner) {
        if (lockRewards == address(0)) {
            lockRewards = _rewards;
        }
    }

    /// @notice sets the address of the feeToken
    /// @param _feeToken feeToken
    function addFeeToken(IERC20 _feeToken) external onlyAddress(feeManager) {
        feeTokens.push(_feeToken);
        // If fee token is BAL forward rewards to BaseRewardPool
        if (address(_feeToken) == bal) {
            feeTokenToPool[address(_feeToken)] = lockRewards;
            return;
        }
        // Create VirtualBalanceRewardPool and forward rewards there for other tokens
        address virtualBalanceRewardPool = IRewardFactory(rewardFactory).createTokenRewards(
            address(_feeToken),
            lockRewards,
            address(this)
        );
        feeTokenToPool[address(_feeToken)] = virtualBalanceRewardPool;
    }

    /// @notice Clears fee tokens
    function clearFeeTokens() external onlyAddress(feeManager) {
        delete feeTokens;
        emit FeeTokensCleared();
    }

    /// @notice sets the lock, staker, caller, platform fees and profit fees
    /// @param _profitFee The amount to set for the profit fees
    /// @param _platformFee The amount to set for the platform fees
    function setFees(uint256 _platformFee, uint256 _profitFee) external onlyAddress(feeManager) {
        uint256 total = _profitFee + _platformFee;
        if (total > MAX_FEES) {
            revert InvalidParameters();
        }

        //values must be within certain ranges
        if (
            _platformFee >= 500 && //5%
            _platformFee <= 2000 && //20%
            _profitFee >= 100 && //1%
            _profitFee <= 1000 //10%
        ) {
            platformFees = _platformFee;
            profitFees = _profitFee;
            emit FeesChanged(_platformFee, _profitFee);
        }
    }

    /// @notice sets the contracts treasury variables
    /// @param _treasury The address of the treasury contract
    function setTreasury(address _treasury) external onlyAddress(feeManager) {
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    /// END SETTER SECTION ///

    /// @inheritdoc IController
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function feeTokensLength() external view returns (uint256) {
        return feeTokens.length;
    }

    /// @notice creates a new pool
    /// @param _lptoken The address of the lp token
    /// @param _gauge The address of the gauge controller
    function addPool(address _lptoken, address _gauge) external onlyAddress(poolManager) isNotShutDown {
        if (_gauge == address(0) || _lptoken == address(0) || gaugeMap[_gauge]) {
            revert InvalidParameters();
        }
        //the next pool's pid
        uint256 pid = poolInfo.length;
        //create a tokenized deposit
        address token = ITokenFactory(tokenFactory).createDepositToken(_lptoken);
        //create a reward contract for bal rewards
        address newRewardPool = IRewardFactory(rewardFactory).createBalRewards(pid, token);
        //create a stash to handle extra incentives
        address stash = IStashFactory(stashFactory).createStash(pid, _gauge);

        if (stash == address(0)) {
            revert InvalidStash();
        }

        //add the new pool
        poolInfo.push(
            PoolInfo({
                lptoken: _lptoken,
                token: token,
                gauge: _gauge,
                balRewards: newRewardPool,
                stash: stash,
                shutdown: false
            })
        );
        gaugeMap[_gauge] = true;
        // give stashes access to RewardFactory and VoterProxy
        // VoterProxy so that it can grab the incentive tokens off the contract after claiming rewards
        // RewardFactory so that stashes can make new extra reward contracts if a new incentive is added to the gauge
        poolInfo[pid].stash = stash;
        IRewardFactory(rewardFactory).grantRewardStashAccess(stash);
        redirectGaugeRewards(stash, _gauge);
        emit AddedPool(pid, _lptoken, token, _gauge, newRewardPool, stash);
    }

    /// @notice Shuts down multiple pools
    /// @dev Claims rewards for that pool before shutting it down
    /// @param _startPoolIdx Start pool index
    /// @param _endPoolIdx End pool index (excluded)
    function bulkPoolShutdown(uint256 _startPoolIdx, uint256 _endPoolIdx) external onlyAddress(poolManager) {
        for (uint256 i = _startPoolIdx; i < _endPoolIdx; i = i.unsafeInc()) {
            PoolInfo storage pool = poolInfo[i];

            if (pool.shutdown) {
                continue;
            }

            _earmarkRewards(i);

            //withdraw from gauge
            // solhint-disable-next-line
            try IVoterProxy(staker).withdrawAll(pool.lptoken, pool.gauge) {
                // solhint-disable-next-line
            } catch {}

            pool.shutdown = true;
            gaugeMap[pool.gauge] = false;
            emit PoolShutDown(i);
        }
    }

    /// @notice shuts down all pools
    /// @dev This shuts down the contract
    function shutdownSystem() external onlyAddress(owner) {
        isShutdown = true;
        emit SystemShutdown();
    }

    /// @inheritdoc IController
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) public isNotShutDown {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.shutdown) {
            revert PoolIsClosed();
        }
        //send to proxy to stake
        address lptoken = pool.lptoken;
        IERC20(lptoken).transferFrom(msg.sender, staker, _amount);

        //stake
        address gauge = pool.gauge;
        IVoterProxy(staker).deposit(lptoken, gauge); // VoterProxy

        address token = pool.token; //D2DPool token
        if (_stake) {
            //mint here and send to rewards on user behalf
            ITokenMinter(token).mint(address(this), _amount);
            address rewardContract = pool.balRewards;
            IERC20(token).approve(rewardContract, _amount);
            IRewards(rewardContract).stakeFor(msg.sender, _amount);
        } else {
            //add user balance directly
            ITokenMinter(token).mint(msg.sender, _amount);
        }

        emit Deposited(msg.sender, _pid, _amount, _stake);
    }

    /// @inheritdoc IController
    function depositAll(uint256 _pid, bool _stake) external {
        address lptoken = poolInfo[_pid].lptoken;
        uint256 balance = IERC20(lptoken).balanceOf(msg.sender);
        deposit(_pid, balance, _stake);
    }

    /// @notice internal function that withdraws lp tokens from the pool
    /// @param _pid The pool id to withdraw the tokens from
    /// @param _amount amount of LP tokens to withdraw
    /// @param _from address of where the lp tokens will be withdrawn from
    /// @param _to address of where the lp tokens will be sent to
    function _withdraw(
        uint256 _pid,
        uint256 _amount,
        address _from,
        address _to
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address lptoken = pool.lptoken;
        address gauge = pool.gauge;

        //remove lp balance
        address token = pool.token;
        ITokenMinter(token).burn(_from, _amount);

        //pull from gauge if not shutdown
        // if shutdown tokens will be in this contract
        if (!pool.shutdown) {
            IVoterProxy(staker).withdraw(lptoken, gauge, _amount);
        }
        //return lp tokens
        IERC20(lptoken).transfer(_to, _amount);

        emit Withdrawn(_to, _pid, _amount);
    }

    /// @inheritdoc IController
    function withdraw(uint256 _pid, uint256 _amount) public {
        _withdraw(_pid, _amount, msg.sender, msg.sender);
    }

    /// @inheritdoc IController
    function withdrawAll(uint256 _pid) public {
        address token = poolInfo[_pid].token;
        uint256 userBal = IERC20(token).balanceOf(msg.sender);
        withdraw(_pid, userBal);
    }

    /// @inheritdoc IController
    function withdrawTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external {
        address rewardContract = poolInfo[_pid].balRewards;
        if (msg.sender != rewardContract) {
            revert Unauthorized();
        }
        _withdraw(_pid, _amount, msg.sender, _to);
    }

    /// @inheritdoc IController
    function withdrawUnlockedWethBal() external onlyAddress(owner) {
        canClaim = true;
        IVoterProxy(staker).withdrawWethBal(address(this));
    }

    /// @inheritdoc IController
    function redeemWethBal() external {
        require(canClaim);
        IBalDepositor balDepositor = IBalDepositor(IVoterProxy(staker).depositor());
        uint256 balance = IERC20(balDepositor.d2dBal()).balanceOf(msg.sender);
        balDepositor.burnD2DBal(msg.sender, balance);
        IERC20(balDepositor.wethBal()).safeTransfer(msg.sender, balance);
    }

    /// @notice Delegates voting power from VoterProxy
    /// @param _delegateTo to whom we delegate voting power
    function delegateVotingPower(address _delegateTo) external onlyAddress(owner) {
        IVoterProxy(staker).delegateVotingPower(_delegateTo);
    }

    /// @notice Clears delegation of voting power from EOA for VoterProxy
    function clearDelegation() external onlyAddress(owner) {
        IVoterProxy(staker).clearDelegate();
    }

    /// @notice Votes for multiple gauges
    /// @param _gauges array of gauge addresses
    /// @param _weights array of vote weights
    function voteGaugeWeight(address[] calldata _gauges, uint256[] calldata _weights)
        external
        onlyAddress(voteDelegate)
    {
        IVoterProxy(staker).voteMultipleGauges(_gauges, _weights);
    }

    /// @notice claims rewards from a specific pool
    /// @param _pid the id of the pool
    /// @param _gauge address of the gauge
    function claimRewards(uint256 _pid, address _gauge) external {
        address stash = poolInfo[_pid].stash;
        if (msg.sender != stash) {
            revert Unauthorized();
        }
        IVoterProxy(staker).claimRewards(_gauge);
    }

    /// @notice internal function that claims rewards from a pool and disperses them to the rewards contract
    /// @param _pid the id of the pool where lp tokens are held
    function _earmarkRewards(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.shutdown) {
            revert PoolIsClosed();
        }
        address gauge = pool.gauge;

        //claim bal
        IVoterProxy(staker).claimBal(gauge);

        //check if there are extra rewards
        address stash = pool.stash;
        if (stash != address(0)) {
            //claim extra rewards
            IStash(stash).claimRewards();
            //process extra rewards
            IStash(stash).processStash();
        }

        //bal balance
        uint256 balBal = IERC20(bal).balanceOf(address(this));

        if (balBal > 0) {
            //Profit fees are taken on the rewards together with platform fees.
            uint256 _profit = (balBal * profitFees) / FEE_DENOMINATOR;
            //profit fees are distributed to the gnosisSafe, which owned by Prime; which is here feeManager
            IERC20(bal).transfer(feeManager, _profit);

            //send treasury
            if (treasury != address(0) && treasury != address(this) && platformFees > 0) {
                //only subtract after address condition check
                uint256 _platform = (balBal * platformFees) / FEE_DENOMINATOR;
                balBal = balBal - _platform;
                IERC20(bal).transfer(treasury, _platform);
            }
            balBal = balBal - _profit;

            //send bal to lp provider reward contract
            address rewardContract = pool.balRewards;
            IERC20(bal).transfer(rewardContract, balBal);
            IRewards(rewardContract).queueNewRewards(balBal);
        }
    }

    /// @inheritdoc IController
    function earmarkRewards(uint256 _pid) external {
        _earmarkRewards(_pid);
    }

    /// @inheritdoc IController
    function earmarkFees() external {
        IERC20[] memory feeTokensMemory = feeTokens;
        // Claim fee rewards from fee distro
        IVoterProxy(staker).claimFees(feeDistro, feeTokensMemory);

        // VoterProxy transfers rewards to this contract, and we need to distribute them to
        // VirtualBalanceRewards contracts
        for (uint256 i = 0; i < feeTokensMemory.length; i = i.unsafeInc()) {
            IERC20 feeToken = feeTokensMemory[i];
            uint256 balance = feeToken.balanceOf(address(this));
            if (balance != 0) {
                feeToken.safeTransfer(feeTokenToPool[address(feeToken)], balance);
                IRewards(feeTokenToPool[address(feeToken)]).queueNewRewards(balance);
            }
        }
    }

    /// @notice redirects rewards from gauge to rewards contract
    /// @param _stash stash address
    /// @param _gauge gauge address
    function redirectGaugeRewards(address _stash, address _gauge) private {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("set_rewards_receiver(address)")), _stash);
        (bool success, ) = IVoterProxy(staker).execute(_gauge, uint256(0), data);
        if (!success) {
            revert RedirectFailed();
        }
    }
}