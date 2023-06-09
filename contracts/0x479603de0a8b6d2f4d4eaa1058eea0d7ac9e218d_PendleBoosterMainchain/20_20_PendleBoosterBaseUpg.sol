// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./Interfaces/IXEqbToken.sol";
import "@shared/lib-contracts-v0.8/contracts/Dependencies/TransferHelper.sol";
import "./Interfaces/IPendleBooster.sol";
import "./Interfaces/IPendleProxy.sol";
import "./Interfaces/IDepositToken.sol";
import "./Interfaces/IPendleDepositor.sol";
import "./Interfaces/IEqbMinter.sol";
import "./Interfaces/IBaseRewardPool.sol";

abstract contract PendleBoosterBaseUpg is IPendleBooster, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using TransferHelper for address;

    address public pendle;

    address public pendleProxy;
    address public eqbMinter;
    address public eqb;
    address public xEqb;
    address public vlEqb;
    address public treasury;
    address public ePendleRewardReceiver; // ePendle rewards receiver
    address public ePendleRewardPool; // ePendle rewards pool
    address public contributor;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public constant MaxFees = 3500;
    uint256 public vlEqbIncentive; // incentive to eqb lockers
    uint256 public ePendleIncentive; //incentive to pendle stakers
    uint256 public platformFee; // possible fee to build treasury
    uint256 public earmarkIncentive; // incentive to earmark caller

    uint256 public farmEqbShare;
    uint256 public teamEqbShare;

    bool public isShutdown;

    struct PoolInfo {
        address market;
        address token;
        address rewardPool;
        bool shutdown;
    }

    // index(pid) -> pool
    PoolInfo[] public override poolInfo;

    bool public earmarkOnOperation;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __PendleBoosterBaseUpg_init() internal onlyInitializing {
        __PendleBoosterBaseUpg_init_unchained();
    }

    function __PendleBoosterBaseUpg_init_unchained() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    /// SETTER SECTION ///

    function setParams(
        address _pendle,
        address _pendleProxy,
        address _eqbMinter,
        address _eqb,
        address _xEqb,
        address _vlEqb,
        address _ePendleRewardReceiver,
        address _ePendleRewardPool,
        address _treasury
    ) external onlyOwner {
        require(pendleProxy == address(0), "params has already been set");

        require(_pendle != address(0), "invalid _pendle!");
        require(_pendleProxy != address(0), "invalid _pendleProxy!");
        require(_eqbMinter != address(0), "invalid _eqbMinter!");
        require(_eqb != address(0), "invalid _eqb!");
        require(_xEqb != address(0), "invalid _xEqb!");
        require(_vlEqb != address(0), "invalid _vlEqb!");
        require(
            _ePendleRewardReceiver != address(0),
            "invalid _ePendleRewardReceiver!"
        );
        require(
            _ePendleRewardPool != address(0),
            "invalid _ePendleRewardPool!"
        );
        require(_treasury != address(0), "invalid _treasury!");

        isShutdown = false;

        pendle = _pendle;

        pendleProxy = _pendleProxy;
        eqbMinter = _eqbMinter;
        eqb = _eqb;
        xEqb = _xEqb;
        vlEqb = _vlEqb;

        ePendleRewardReceiver = _ePendleRewardReceiver;
        ePendleRewardPool = _ePendleRewardPool;

        treasury = _treasury;

        vlEqbIncentive = 500;
        ePendleIncentive = 1500;
        platformFee = 250;
        earmarkIncentive = 50;

        farmEqbShare = 2500;
        teamEqbShare = 5000;

        earmarkOnOperation = true;
    }

    function setVlEqb(address _vlEqb) external onlyOwner {
        require(_vlEqb != address(0), "invalid _vlEqb");
        vlEqb = _vlEqb;
    }

    function setFees(
        uint256 _vlEqbIncentive,
        uint256 _ePendleIncentive,
        uint256 _platformFee,
        uint256 _earmarkIncentive
    ) external onlyOwner {
        require(
            _ePendleIncentive +
                _vlEqbIncentive +
                _platformFee +
                _earmarkIncentive <=
                MaxFees,
            ">MaxFees"
        );

        //values must be within certain ranges
        require(
            _vlEqbIncentive >= 0 && _vlEqbIncentive <= 1000,
            "invalid _vlEqbIncentive"
        );
        require(
            _ePendleIncentive >= 800 && _ePendleIncentive <= 2000,
            "invalid _ePendleIncentive"
        );
        require(
            _platformFee >= 0 && _platformFee <= 500,
            "invalid _platformFee"
        );
        require(
            _earmarkIncentive >= 0 && _earmarkIncentive <= 100,
            "invalid _earmarkIncentive"
        );

        vlEqbIncentive = _vlEqbIncentive;
        ePendleIncentive = _ePendleIncentive;
        platformFee = _platformFee;
        earmarkIncentive = _earmarkIncentive;
    }

    function setFarmEqbShare(uint256 _farmEqbShare) external onlyOwner {
        require(_farmEqbShare <= DENOMINATOR, "invalid _farmEqbShare");
        farmEqbShare = _farmEqbShare;
    }

    function setTeamEqbShare(uint256 _teamEqbShare) external onlyOwner {
        require(_teamEqbShare <= DENOMINATOR, "invalid _teamEqbShare");
        teamEqbShare = _teamEqbShare;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setContributor(address _contributor) external onlyOwner {
        contributor = _contributor;
    }

    function setEarmarkOnOperation(
        bool _earmarkOnOperation
    ) external onlyOwner {
        earmarkOnOperation = _earmarkOnOperation;
    }

    /// END SETTER SECTION ///

    function poolLength() external view override returns (uint256) {
        return poolInfo.length;
    }

    // create a new pool
    function addPool(
        address _market,
        address _token,
        address _rewardPool
    ) external onlyOwner {
        require(!isShutdown, "!add");

        require(
            IPendleProxy(pendleProxy).isValidMarket(_market),
            "invalid _market"
        );

        // the next pool's pid
        uint256 pid = poolInfo.length;

        // config pendle rewards
        IBaseRewardPool(_rewardPool).setParams(pid, _token, pendle);

        // add the new pool
        poolInfo.push(
            PoolInfo({
                market: _market,
                token: _token,
                rewardPool: _rewardPool,
                shutdown: false
            })
        );
    }

    // shutdown pool
    function shutdownPool(uint256 _pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(!pool.shutdown, "already shutdown!");

        pool.shutdown = true;
    }

    // shutdown this contract.
    // only allow withdrawals
    function shutdownSystem() external onlyOwner {
        isShutdown = true;

        for (uint256 i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            if (pool.shutdown) {
                continue;
            }

            shutdownPool(i);
        }
    }

    // deposit market tokens and stake
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) public override {
        require(!isShutdown, "shutdown");
        PoolInfo memory pool = poolInfo[_pid];
        require(pool.shutdown == false, "pool is closed");

        if (earmarkOnOperation) {
            _earmarkRewards(_pid, address(0), new uint256[](0));
        }

        // send to proxy
        address market = pool.market;
        IERC20(market).safeTransferFrom(msg.sender, pendleProxy, _amount);

        address token = pool.token;
        if (_stake) {
            // mint here and send to rewards on user behalf
            IDepositToken(token).mint(address(this), _amount);
            address rewardContract = pool.rewardPool;
            _approveTokenIfNeeded(token, rewardContract, _amount);
            IBaseRewardPool(rewardContract).stakeFor(msg.sender, _amount);
        } else {
            // add user balance directly
            IDepositToken(token).mint(msg.sender, _amount);
        }

        emit Deposited(msg.sender, _pid, _amount);
    }

    //deposit all market tokens and stake
    function depositAll(uint256 _pid, bool _stake) external {
        address market = poolInfo[_pid].market;
        uint256 balance = IERC20(market).balanceOf(msg.sender);
        deposit(_pid, balance, _stake);
    }

    // withdraw market tokens
    function _withdraw(
        uint256 _pid,
        uint256 _amount,
        address _from,
        address _to
    ) internal {
        PoolInfo memory pool = poolInfo[_pid];
        address market = pool.market;

        address token = pool.token;
        IDepositToken(token).burn(_from, _amount);

        if (earmarkOnOperation) {
            _earmarkRewards(_pid, address(0), new uint256[](0));
        }

        // return market tokens
        IPendleProxy(pendleProxy).withdraw(market, _to, _amount);

        emit Withdrawn(_to, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public override {
        _withdraw(_pid, _amount, msg.sender, msg.sender);
    }

    function withdrawAll(uint256 _pid) external {
        address token = poolInfo[_pid].token;
        uint256 userBal = IERC20(token).balanceOf(msg.sender);
        withdraw(_pid, userBal);
    }

    // disperse pendle and extra rewards to reward contracts
    function _earmarkRewards(
        uint256 _pid,
        address _caller,
        uint256[] memory _rewardAmounts
    ) internal {
        PoolInfo memory pool = poolInfo[_pid];
        address[] memory rewardTokens;
        if (_rewardAmounts.length > 0) {
            rewardTokens = IPendleProxy(pendleProxy).claimRewardsManually(
                pool.market,
                _rewardAmounts
            );
        } else {
            (rewardTokens, _rewardAmounts) = IPendleProxy(pendleProxy)
                .claimRewards(pool.market);
        }

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            uint256 rewardAmount = _rewardAmounts[i];
            if (rewardToken == address(0) || rewardAmount == 0) {
                continue;
            }
            if (rewardToken.balanceOf(address(this)) < rewardAmount) {
                continue;
            }
            emit RewardClaimed(_pid, rewardToken, rewardAmount);

            uint256 vlEqbIncentiveAmount = (rewardAmount * vlEqbIncentive) /
                DENOMINATOR;
            uint256 ePendleIncentiveAmount = (rewardAmount * ePendleIncentive) /
                DENOMINATOR;

            uint256 earmarkIncentiveAmount = 0;
            if (_caller != address(0) && earmarkIncentive > 0) {
                earmarkIncentiveAmount =
                    (rewardAmount * earmarkIncentive) /
                    DENOMINATOR;

                // send incentives for calling
                rewardToken.safeTransferToken(_caller, earmarkIncentiveAmount);

                emit EarmarkIncentiveSent(
                    _pid,
                    _caller,
                    rewardToken,
                    earmarkIncentiveAmount
                );
            }

            // send treasury
            uint256 platform = 0;
            if (platformFee > 0) {
                platform = (rewardAmount * platformFee) / DENOMINATOR;
                rewardToken.safeTransferToken(treasury, platform);
                emit TreasurySent(_pid, rewardToken, platform);
            }

            // remove incentives from balance
            rewardAmount =
                rewardAmount -
                vlEqbIncentiveAmount -
                ePendleIncentiveAmount -
                earmarkIncentiveAmount -
                platform;

            // send lp provider reward contract
            _sendReward(pool.rewardPool, rewardToken, rewardAmount);

            // send to vlEqb
            if (vlEqbIncentiveAmount > 0) {
                rewardToken.safeTransferToken(vlEqb, vlEqbIncentiveAmount);
            }

            // send to ePendle reward contract
            if (ePendleIncentiveAmount > 0) {
                rewardToken.safeTransferToken(
                    ePendleRewardReceiver,
                    ePendleIncentiveAmount
                );
            }
        }
    }

    function earmarkRewards(uint256 _pid) external {
        require(!isShutdown, "shutdown");
        PoolInfo memory pool = poolInfo[_pid];
        require(pool.shutdown == false, "pool is closed");

        _earmarkRewards(_pid, msg.sender, new uint256[](0));
    }

    function earmarkRewardsManually(
        uint256 _pid,
        uint256[] memory _amounts
    ) external onlyOwner {
        _earmarkRewards(_pid, address(0), _amounts);
    }

    // callback from reward contract when pendle is received.
    function rewardClaimed(
        uint256 _pid,
        address _account,
        address _token,
        uint256 _amount
    ) external override {
        PoolInfo memory pool = poolInfo[_pid];
        require(
            msg.sender == pool.rewardPool || msg.sender == ePendleRewardPool,
            "!auth"
        );

        if (_token != pendle || isShutdown) {
            return;
        }

        // mint eqb
        _mintEqbRewards(_account, _amount, farmEqbShare);

        if (contributor == address(0)) {
            return;
        }
        uint256 contributorAmount = _getContributorAmount(pool, _amount);
        if (contributorAmount > 0) {
            _mintEqbRewards(contributor, contributorAmount, teamEqbShare);
        }
    }

    function _mintEqbRewards(
        address _to,
        uint256 _amount,
        uint256 _share
    ) internal {
        // mint eqb
        uint256 mintAmount = IEqbMinter(eqbMinter).mint(address(this), _amount);
        uint256 eqbAmount = (mintAmount * _share) / DENOMINATOR;
        IERC20(eqb).safeTransfer(_to, eqbAmount);

        uint256 xEqbAmount = mintAmount - eqbAmount;
        _approveTokenIfNeeded(eqb, xEqb, xEqbAmount);
        IXEqbToken(xEqb).convertTo(xEqbAmount, _to);

        emit EqbRewardsSent(_to, eqbAmount, xEqbAmount);
    }

    function _sendReward(
        address _rewardPool,
        address _rewardToken,
        uint256 _rewardAmount
    ) internal {
        if (_rewardAmount == 0) {
            return;
        }
        if (AddressLib.isPlatformToken(_rewardToken)) {
            IRewards(_rewardPool).queueNewRewards{value: _rewardAmount}(
                _rewardToken,
                _rewardAmount
            );
        } else {
            _approveTokenIfNeeded(_rewardToken, _rewardPool, _rewardAmount);
            IRewards(_rewardPool).queueNewRewards(_rewardToken, _rewardAmount);
        }
    }

    function _getContributorAmount(
        PoolInfo memory _pool,
        uint256 _amount
    ) internal view returns (uint256) {
        address market = _pool.market;
        uint256 share = (IERC20(market).balanceOf(pendleProxy) * DENOMINATOR) /
            IERC20(market).totalSupply();
        uint256 percent;
        if (share <= 1000) {
            // [0%, 10%], 0.00%
            percent = 0;
        } else if (share <= 2000) {
            // (10%, 20%], 12.30%
            percent = 1230;
        } else if (share <= 3000) {
            // (20%, 30%], 24.40%
            percent = 2440;
        } else {
            // (30%, 100%], 36.60%
            percent = 3660;
        }
        return (_amount * percent) / DENOMINATOR;
    }

    function _approveTokenIfNeeded(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _to) < _amount) {
            IERC20(_token).safeApprove(_to, 0);
            IERC20(_token).safeApprove(_to, type(uint256).max);
        }
    }

    receive() external payable {}

    uint256[100] private __gap;
}