// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IGloryReferral.sol";
import "./interfaces/IGloryToken.sol";
import "./interfaces/IGloryTreasury.sol";
import "./interfaces/IMasterChefV2.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IBEP20.sol";
import "./libraries/DSMath.sol";
import "./libraries/UserInfo.sol";

contract GloryAggregator is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeMath for uint256;
    using UserInfo for UserInfo.Data;

    // The Glory TOKEN!
    IGloryToken public glory;
    IGloryTreasury public gloryTreasury;

    IERC20 public cake;
    IERC20 public usdt;

    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;
    IMasterChefV2 public masterChef;
    IGloryReferral public gloryReferral;

    // Configurable variable for fee
    uint256 public harvestFee;
    uint256 public referralCommissionRate;

    // Info of each user that stakes LP tokens. Pid => user address => UserInfo
    mapping(uint256 => mapping(address => UserInfo.Data)) public userInfo;

    // total staked of each pid farm
    mapping(uint256 => uint256) public totalStaked;

    // rewardPerTokenStored of each pid farm
    mapping(uint256 => uint256) public rewardPerToken;

    // total harvested reward of each farm pid
    mapping(uint256 => uint256) public totalFarmReward;

    event Deposit(uint256 pid, address user, uint256 amount);
    event Withdraw(uint256 pid, address user, uint256 amount);
    event Harvest(uint256 pid, address user, uint256 amount);
    event ReferralCommissionPaid(
        address user,
        address referrer,
        uint256 commissionAmount
    );

    function initialize(
        uint256 _harvestFee,
        uint256 _referralCommissionRate,
        IGloryToken _glory,
        IGloryReferral _gloryReferral,
        IMasterChefV2 _masterChef,
        IERC20 _cake,
        IERC20 _usdt,
        IUniswapV2Router02 _router,
        IUniswapV2Factory _factory
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();

        harvestFee = _harvestFee;
        referralCommissionRate = _referralCommissionRate;

        glory = _glory;
        gloryReferral = _gloryReferral;
        // pancake masterChef address
        masterChef = _masterChef;
        cake = _cake;
        usdt = _usdt;
        router = _router;
        factory = _factory;

        cake.approve(address(router), type(uint256).max);
        usdt.approve(address(router), type(uint256).max);
    }

    function updateReward(uint256 _pid, address _user) internal {
        uint256 memRewardPerToken = rewardPerToken[_pid];
        if (userInfo[_pid][_user].rewardPerTokenPaid != memRewardPerToken) {
            // need update userInfo.reward and userInfo.rewardPerTokenPaid to update latest reward
            // userInfo.reward is harvested reward of old userInfo.amount
            // userInfo.rewardPerTokenPaid is different between user and pool's rewardPerToken of new user.amount
            if (_user != address(0)) {
                userInfo[_pid][_user].updateReward(
                    earned(_pid, _user),
                    memRewardPerToken
                );
            }
        }
    }

    function pendingGlory(
        uint256 _pid,
        address _user
    ) public view returns (uint256) {
        UserInfo.Data memory memUserInfo = userInfo[_pid][_user];
        uint256 pendingCake = memUserInfo
            .amount
            .mul(
                pendingRewardPerToken(_pid).sub(memUserInfo.rewardPerTokenPaid)
            )
            .div(1e18)
            .add(memUserInfo.rewards);
        IUniswapV2Pair cakeUsdtPair = getCakeUsdtPair();
        uint256 cakeBalanceOfCakeLP = cake.balanceOf(address(cakeUsdtPair));
        uint256 usdtBalanceOfCakeLP = usdt.balanceOf(address(cakeUsdtPair));
        uint256 cakePrice = usdtBalanceOfCakeLP.mul(1e18).div(cakeBalanceOfCakeLP);

        IUniswapV2Pair gloryUsdtPair = getUsdtGloryPair();
        uint256 gloryBalanceOfGloryLP = glory.balanceOf(address(gloryUsdtPair));
        uint256 usdtBalanceOfGloryLP = usdt.balanceOf(address(gloryUsdtPair));
        uint256 gloryPrice = usdtBalanceOfGloryLP.mul(1e18).div(gloryBalanceOfGloryLP);
        return pendingCake.mul(cakePrice).div(gloryPrice);
    }

    // total user's rewards ready to withdraw
    function earned(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo.Data memory memUserInfo = userInfo[_pid][_user];
        return
            memUserInfo
                .amount
                .mul(rewardPerToken[_pid].sub(memUserInfo.rewardPerTokenPaid))
                .div(1e18)
                .add(memUserInfo.rewards);
    }

    function totalFarmPendingReward(
        uint256 _pid
    ) public view returns (uint256) {
        return masterChef.pendingCake(_pid, address(this));
    }

    function pendingRewardPerToken(uint256 _pid) public view returns (uint256) {
        uint256 memTotalStaked = totalStaked[_pid];
        if (memTotalStaked == 0) {
            return 0;
        }
        return
            rewardPerToken[_pid].add(
                totalFarmPendingReward(_pid).mul(1e18).div(memTotalStaked)
            );
    }

    function approve(uint256 _pid) public onlyOwner {
        uint256 maxUint256 = type(uint256).max;
        IBEP20 farmLpToken = masterChef.lpToken(_pid);
        farmLpToken.approve(address(masterChef), maxUint256);
    }

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _referrer
    ) external nonReentrant {
        address user = msg.sender;
        updateReward(_pid, user);
        IBEP20 lpToken = masterChef.lpToken(_pid);
        lpToken.transferFrom(user, address(this), _amount);

        // get cake balance changed when deposit to masterChef
        uint256 balanceBeforeDeposit = cake.balanceOf(address(this));
        masterChef.deposit(_pid, _amount);
        uint256 balanceAfterDeposit = cake.balanceOf(address(this));
        uint256 cakeReceived = balanceAfterDeposit.sub(balanceBeforeDeposit);

        // update total reward of this farm pid
        totalFarmReward[_pid] += cakeReceived;

        // update total staked of this farm pid
        totalStaked[_pid] += _amount;

        // update total staked in userInfo
        userInfo[_pid][user].amount += _amount;

        // update reward per token of this farm pid
        rewardPerToken[_pid] += cakeReceived.mul(1e18).div(totalStaked[_pid]);

        emit Deposit(_pid, user, _amount);
    }

    function withdraw(
        uint256 _pid,
        uint256 _amount,
        address _referrer
    ) external nonReentrant {
        address user = msg.sender;
        updateReward(_pid, user);
        IBEP20 lpToken = masterChef.lpToken(_pid);

        // get cake balance changed when withdraw from masterChef
        uint256 balanceBeforeDeposit = cake.balanceOf(address(this));
        masterChef.withdraw(_pid, _amount);
        uint256 balanceAfterDeposit = cake.balanceOf(address(this));
        uint256 cakeReceived = balanceAfterDeposit.sub(balanceBeforeDeposit);

        // update total reward of this farm pid
        totalFarmReward[_pid] += cakeReceived;

        uint256 newRewardPerTokenReceived = cakeReceived.mul(1e18).div(
            totalStaked[_pid]
        );
        // update total staked in userInfo
        rewardPerToken[_pid] += newRewardPerTokenReceived;

        // update total staked of this farm pid
        totalStaked[_pid] -= _amount;

        // update total staked in userInfo
        userInfo[_pid][user].amount -= _amount;
        // update earned reward by withdraw amount multiple new received reward per token
        userInfo[_pid][user].rewards += (
            _amount.mul(newRewardPerTokenReceived).div(1e18)
        );

        // transfer lp back to user
        lpToken.transfer(user, _amount);
        emit Withdraw(_pid, user, _amount);
    }

    function harvest(uint256 _pid) external nonReentrant {
        address user = msg.sender;
        uint256 pendingReward = pendingGlory(_pid, user);
        if (pendingReward > 0) {
            uint256 balanceOfThis = cake.balanceOf(address(this));
            if (balanceOfThis < pendingReward) {
                // harvest current pending cake
                masterChef.deposit(_pid, 0);
            }
            {
                // swap cake to glory
                uint256 usdtBalanceBeforeSwap = usdt.balanceOf(address(this));
                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    pendingReward,
                    0,
                    getCakeUsdtRouter(),
                    address(this),
                    block.timestamp
                );
                uint256 receivedUsdt = usdt.balanceOf(address(this)).sub(
                    usdtBalanceBeforeSwap
                );
                uint256 gloryBalanceBeforeSwap = glory.balanceOf(address(this));
                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    receivedUsdt,
                    0,
                    getUsdtGloryRouter(),
                    address(this),
                    block.timestamp
                );
                uint256 receivedGlory = glory.balanceOf(address(this)).sub(
                    gloryBalanceBeforeSwap
                );
                glory.transfer(user, receivedGlory);
                // TODO payReferralCommission
                emit Harvest(_pid, user, receivedGlory);
            }
        }
    }

    function getCakeUsdtPair() public view returns (IUniswapV2Pair) {
        return IUniswapV2Pair(factory.getPair(address(cake), address(usdt)));
    }

    function getUsdtGloryPair() public view returns (IUniswapV2Pair) {
        return IUniswapV2Pair(factory.getPair(address(usdt), address(glory)));
    }

    function getCakeUsdtRouter() private view returns (address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(cake);
        paths[1] = address(usdt);
    }

    function getUsdtGloryRouter()
        private
        view
        returns (address[] memory paths)
    {
        paths = new address[](2);
        paths[0] = address(usdt);
        paths[1] = address(glory);
    }

    function lpToken(uint256 _pid) external view returns (IBEP20) {
        return masterChef.lpToken(_pid);
    }

    function poolInfo(
        uint256 _pid
    ) external view returns (IMasterChefV2.PoolInfo memory) {
        return masterChef.poolInfo(_pid);
    }
}