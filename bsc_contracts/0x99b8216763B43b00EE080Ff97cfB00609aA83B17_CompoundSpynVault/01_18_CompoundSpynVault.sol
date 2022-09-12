pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/ISpynPool.sol";
import "./interfaces/IMigratable.sol";
import "./libs/UserInfo.sol";
import "./libs/SwapMath.sol";
import "./libs/ISpynReferral.sol";
import "./libs/ISpynLeaderboard.sol";

/*
A vault that helps users stake in SPYN farms and pools more simply.
Supporting auto compound in Single Staking Pool.
*/

contract CompoundSpynVault is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, IMigratable {
    using SafeMath for uint256;
    using UserInfo for UserInfo.Data;

    // MAINNET
    IERC20 public spyn;
    IERC20 public token1;
    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;
    IMasterChef public masterchef;
    ISpynReferral public spynReferral;
    ISpynLeaderboard public spynLeaderboard;
    uint256 public farmPid;

    address private constant DEAD_WALLET = address(0x000000000000000000000000000000000000dEaD);
    uint256 public constant MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    mapping(address => UserInfo.Data) public userInfo;
    uint256 public totalSupply;
    uint256 public pendingRewardPerTokenStored;
    uint256 public lastUpdatePoolPendingReward;
    uint256 public lastCompoundRewardPerToken;

    uint256 public depositFee;
    uint256 public harvestFee;
    uint16[] public harvestReferralCommissionRates;
    uint16[] public depositReferralCommissionRates;
    uint256 public percentFeeForCompounding;

    address public treasury;
    address public feeTreasury;
    address public migrateToContract;
    address public migrateFromContract;

    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event Harvest(address account, uint256 amount);
    event Compound(address caller, uint256 reward);
    event RewardPaid(address account, uint256 reward);
    event HarvestReferralCommissionPaid(
        address indexed user,
        address indexed referrer,
        uint256 level,
        uint256 commissionAmount
    );
    event HarvestReferralCommissionMissed(
        address indexed user,
        address indexed referrer,
        uint256 level,
        uint256 commissionAmount
    );
    event DepositReferralCommissionPaid(
        address indexed user, 
        address indexed referrer, 
        uint256 level, 
        uint256 commissionAmount, 
        address token
    );
    event DepositReferralCommissionMissed(
        address indexed user, 
        address indexed referrer, 
        uint256 level, 
        uint256 commissionAmount, 
        address token
    );
    event HarvestReferralCommissionRatesUpdated(uint16[] value);
    event HarvestFeeUpdated(uint256 value);
    event DepositReferralCommissionRatesUpdated(uint16[] value);
    event DepositFeeUpdated(uint256 value);
    event TreasuryUpdated(address value);
    event FeeTreasuryUpdated(address value);

    modifier noCallFromContract {
        // due to flashloan attack
        // we don't like contract calls to our vault
        require(tx.origin == msg.sender, "no contract call");
        _;
    }

    modifier updateReward(address account) {

        pendingRewardPerTokenStored = pendingRewardPerToken();
        if(pendingRewardPerTokenStored != 0){
            lastUpdatePoolPendingReward = totalPoolPendingRewards();
        }

        if(account != address(0)){
            if(lastCompoundRewardPerToken >= userInfo[account].pendingRewardPerTokenPaid){
                // set user earned
                userInfo[account].updateEarnedRewards(earned(account));
            }
            userInfo[account].updatePendingReward(
                pendingEarned(account),
                pendingRewardPerTokenStored
            );
        }
        _;
    }

    modifier waitForCompound {
        require(!canCompound(), "Call compound first");
        _;
    }

    function initialize(
        uint256 _farmPid,
        address _spyn,
        address _token1,
        address _router,
        address _factory,
        address _masterchef,
        address _treasury,
        address _feeTreasury
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        farmPid = _farmPid;
        spyn = IERC20(_spyn);
        token1 = IERC20(_token1);
        router = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(_factory);
        masterchef = IMasterChef(_masterchef);
        percentFeeForCompounding = 10; //default 1%
        treasury = _treasury;
        feeTreasury = _feeTreasury;

        depositFee = 500;
        depositReferralCommissionRates.push(500);
        depositReferralCommissionRates.push(400);
        depositReferralCommissionRates.push(300);
        depositReferralCommissionRates.push(200);
        depositReferralCommissionRates.push(100);

        harvestFee = 500;
        harvestReferralCommissionRates.push(100);
        harvestReferralCommissionRates.push(100);
        harvestReferralCommissionRates.push(100);
        harvestReferralCommissionRates.push(100);
        harvestReferralCommissionRates.push(100);
    }

    function canCompound() public view returns (bool) {
        return masterchef.canHarvest(farmPid, address(this)) && pendingSpynNextCompound() > 0;
    }

    function nearestCompoundingTime() public view returns (uint256 time) {
        (,,,time) = masterchef.userInfo(farmPid, address(this));
    }

    function balanceOf(address user) public view returns (uint256) {
        return getReserveInAmount1ByLP(userInfo[user].amount);
    }

    function lpOf(address user) public view returns (uint256) {
        return userInfo[user].amount;
    }


    function totalPoolPendingRewards() public view returns (uint256) {
        (,,uint256 rewardLockedUp,) = masterchef.userInfo(farmPid, address(this));
        return masterchef.pendingSpyn(farmPid, address(this)).add(rewardLockedUp);
    }

    function totalPoolAmount() public view returns (uint256 amount) {
        (amount,,,) = masterchef.userInfo(farmPid, address(this));
    }

    // total user's rewards: pending + earned
    function pendingEarned(address account) public view returns (uint256) {
        UserInfo.Data memory _userInfo = userInfo[account];
        uint256 _pendingRewardPerToken = pendingRewardPerToken();
        if(lastCompoundRewardPerToken >= _userInfo.pendingRewardPerTokenPaid){
            // only count for the next change
            return lpOf(account).mul(
                _pendingRewardPerToken
                .sub(lastCompoundRewardPerToken)
            )
            .div(1e18);
        }else{
            return lpOf(account).mul(
                _pendingRewardPerToken
                .sub(_userInfo.pendingRewardPerTokenPaid)
            )
            .div(1e18)
            .add(_userInfo.pendingRewards);
        }

    }

    // total user's rewards ready to withdraw
    function earned(address account) public view returns (uint256) {
        UserInfo.Data memory _userInfo = userInfo[account]; // save gas
        if(lastCompoundRewardPerToken < _userInfo.pendingRewardPerTokenPaid) return _userInfo.rewards;
        return lpOf(account).mul(
            lastCompoundRewardPerToken
            .sub(_userInfo.pendingRewardPerTokenPaid)
        )
        .div(1e18)
        .add(_userInfo.pendingRewards)
        .add(_userInfo.rewards);
    }

    function pendingRewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return 0;
        }
        return pendingRewardPerTokenStored.add(
            totalPoolPendingRewards()
            .sub(lastUpdatePoolPendingReward)
            .mul(1e18)
            .div(totalSupply)
        );
    }

    function getSwappingPair() internal view returns (IUniswapV2Pair) {
        return IUniswapV2Pair(
            factory.getPair(address(spyn), address(token1))
        );
    }

    function updateMigrateToContract(address _migrateToContract) external onlyOwner {
        migrateToContract = _migrateToContract;
    }

    function updateMigrateFromContract(address _migrateFromContract) external onlyOwner {
        migrateFromContract = _migrateFromContract;
    }

    function updateSpynReferral(ISpynReferral _spynReferral) external onlyOwner {
        spynReferral = _spynReferral;
    }

    function updateSpynLeaderboard(ISpynLeaderboard _spynLeaderboard) external onlyOwner {
        spynLeaderboard = _spynLeaderboard;
    }

    function updatePercentFeeForCompounding(uint256 _rate) external onlyOwner {
        require(_rate <= 100);
        percentFeeForCompounding = _rate;
    }

    function setHarvestReferralCommissionRates(uint16[] memory _referralCommissionRates) public onlyOwner {
        require(_referralCommissionRates.length <= 10);
        harvestReferralCommissionRates = _referralCommissionRates;

        emit HarvestReferralCommissionRatesUpdated(_referralCommissionRates);
    }

    function setHarvestFee(uint256 _harvestFee) public onlyOwner {
        require(_harvestFee <= 3000);
        harvestFee = _harvestFee;

        emit HarvestFeeUpdated(_harvestFee);
    }

    function setDepositReferralCommissionRates(uint16[] memory _referralCommissionRates) public onlyOwner {
        require(_referralCommissionRates.length <= 10);
        depositReferralCommissionRates = _referralCommissionRates;

        emit DepositReferralCommissionRatesUpdated(_referralCommissionRates);
    }

    function setDepositFee(uint256 _depositFee) public onlyOwner {
        require(_depositFee <= 3000);
        depositFee = _depositFee;

        emit DepositFeeUpdated(_depositFee);
    }

    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0));
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setFeeTreasury(address _feeTreasury) public onlyOwner {
        require(_feeTreasury != address(0));
        feeTreasury = _feeTreasury;
        emit FeeTreasuryUpdated(_feeTreasury);
    }


    function approve() public {
        spyn.approve(address(masterchef), MAX_INT);
        spyn.approve(address(router), MAX_INT);
        token1.approve(address(router), MAX_INT);
        getSwappingPair().approve(address(masterchef), MAX_INT);
        getSwappingPair().approve(address(router), MAX_INT);
    }

    function getReserveInAmount1ByLP(uint256 lp) public view returns (uint256 amount) {
        IUniswapV2Pair pair = getSwappingPair();
        uint256 balance0 = spyn.balanceOf(address(pair));
        uint256 balance1 = token1.balanceOf(address(pair));
        uint256 _totalSupply = pair.totalSupply();
        uint256 amount0 = lp.mul(balance0) / _totalSupply;
        uint256 amount1 = lp.mul(balance1) / _totalSupply;
        // convert amount0 -> amount1
        amount = amount1.add(amount0.mul(balance1).div(balance0));
    }

    /**
    * return lp Needed to get back total amount in amount 1
    * exp. amount = 1000 token1
    * lpNeeded returns 10
    * once remove liquidity, 10 LP will get back 500 token1 and an amount in SPYN corresponding to 500 token1
    */
    function getLPTokenByAmount1(uint256 amount) internal view returns (uint256 lpNeeded) {
        (, uint256 res1) = getPairReserves();
        lpNeeded = amount.mul(getSwappingPair().totalSupply()).div(res1).div(2);
    }

    /**
    * return lp Needed to get back total amount in amount 0
    * exp. amount = 1000 SPYN
    * lpNeeded returns 10
    * once remove liquidity, 10 LP will get back 500 SPYN and an amount in token1 corresponding to 500 SPYN
    */
    function getLPTokenByAmount0(uint256 amount) internal view returns (uint256 lpNeeded) {
        (uint256 res0,) = getPairReserves();
        lpNeeded = amount.mul(getSwappingPair().totalSupply()).div(res0).div(2);
    }

    function deposit(uint256 amount, address referrer) external updateReward(msg.sender) nonReentrant noCallFromContract waitForCompound {
        require(amount > 0, "deposit zero amount");
        // function to deposit token1
        token1.transferFrom(msg.sender, address(this), amount);
        uint256 amountToken = amount;

        if (
            address(spynReferral) != address(0) &&
            referrer != address(0) &&
            referrer != msg.sender
        ) {
            spynReferral.recordReferral(msg.sender, referrer);
        }

        if (amountToken > 0) {
            // take deposit fee
            uint256 feeTaken = takeDepositFee(msg.sender, amountToken, address(token1));
            amountToken = amountToken.sub(feeTaken);
        }

        (, uint256 res1) = getPairReserves();
        uint256 amountToSwap = SwapMath.calculateSwapInAmount(res1, amountToken);
        uint256 spynOut = swapToken1ToSpyn(amountToSwap);
        uint256 amountLeft = amountToken.sub(amountToSwap);
        (,uint256 token1Added,uint256 liquidityAmount) = router.addLiquidity(
            address(spyn),
            address(token1),
            spynOut,
            amountLeft,
            0,
            0,
            address(this),
            block.timestamp
        );
        _depositLP(msg.sender, liquidityAmount);
        // trasnfer back amount left
        if(amountToken > token1Added+amountToSwap){
            token1.transfer(msg.sender, amountToken - (token1Added + amountToSwap));
        }
    }

    function depositTokenPair(
        uint256 amountSpyn,
        uint256 amountToken1,
        address referrer
    ) external updateReward(msg.sender) nonReentrant noCallFromContract waitForCompound {
        require(amountSpyn > 0 && amountToken1 > 0, "deposit zero amount");
        token1.transferFrom(msg.sender, address(this), amountToken1);
        uint256 balanceOfSpynBeforeTrasnfer = spyn.balanceOf(address(this));
        spyn.transferFrom(msg.sender, address(this), amountSpyn);
        uint256 balanceOfSpynAfterTransfer = spyn.balanceOf(address(this));
        uint256 amountSpynReceived = balanceOfSpynAfterTransfer - balanceOfSpynBeforeTrasnfer;

        if (
            address(spynReferral) != address(0) &&
            referrer != address(0) &&
            referrer != msg.sender
        ) {
            spynReferral.recordReferral(msg.sender, referrer);
        }

        uint256 amountToken1Final = amountToken1;
        if (amountToken1Final > 0) {
            // take deposit fee
            uint256 feeTaken = takeDepositFee(msg.sender, amountToken1Final, address(token1));
            amountToken1Final = amountToken1Final.sub(feeTaken);
        }

        if (amountSpynReceived > 0) {
            // take deposit fee
            uint256 feeTaken = takeDepositFee(msg.sender, amountSpynReceived, address(spyn));
            amountSpynReceived = amountSpynReceived.sub(feeTaken);
        }
        // note spynAdded is might reduced by ~1%
        (uint256 spynAdded, uint256 token1Added, uint256 liquidityAmount) = router.addLiquidity(
            address(spyn),
            address(token1),
            amountSpynReceived,
            amountToken1Final,
            0,
            0,
            address(this),
            block.timestamp
        );
        // transfer back amount that didn't add to the pool
        if(amountSpynReceived.mul(99).div(100) > spynAdded){
            uint256 amountLeft = amountSpynReceived.mul(99).div(100) - spynAdded;
            if(spyn.balanceOf(address(this)) >= amountLeft)
                spyn.transfer(msg.sender, amountLeft);
        }
        if(amountToken1Final > token1Added){
            token1.transfer(msg.sender, amountToken1Final - token1Added);
        }
        _depositLP(msg.sender, liquidityAmount);
    }

    function depositLP(uint256 amount, address referrer) external updateReward(msg.sender) nonReentrant noCallFromContract waitForCompound {
        require(amount > 0, "deposit zero amount");

        IUniswapV2Pair pair = getSwappingPair();
        uint256 balanceOfPairBeforeTransfer = pair.balanceOf(address(this));
        pair.transferFrom(msg.sender, address(this), amount);
        uint256 amountPairReceived = pair.balanceOf(address(this)) - balanceOfPairBeforeTransfer;

        if (
            address(spynReferral) != address(0) &&
            referrer != address(0) &&
            referrer != msg.sender
        ) {
            spynReferral.recordReferral(msg.sender, referrer);
        }

        if (amountPairReceived > 0) {
            // take deposit fee
            uint256 feeTaken = takeDepositFee(msg.sender, amountPairReceived, address(pair));
            amountPairReceived = amountPairReceived.sub(feeTaken);
        }
        _depositLP(msg.sender, amountPairReceived);
    }

    function _depositLP(address account, uint256 liquidityAmount) internal {
        //stake in farms
        depositStakingPool(liquidityAmount);
        //set state
        userInfo[account].deposit(liquidityAmount);
        totalSupply = totalSupply.add(liquidityAmount);
        if (address(spynLeaderboard) != address(0)) {
            IUniswapV2Pair pair = getSwappingPair();
            spynLeaderboard.recordStaking(account, address(pair), liquidityAmount);
        }
        emit Deposit(account, liquidityAmount);
    }

    function withdraw(uint256 amount) external updateReward(msg.sender) nonReentrant noCallFromContract waitForCompound {
        uint256 lpAmountNeeded;
        if(amount >= balanceOf(msg.sender)){
            // withdraw all
            lpAmountNeeded = lpOf(msg.sender);
        }else{
            //calculate LP needed that corresponding with amount
            lpAmountNeeded = getLPTokenByAmount1(amount);
            if(lpAmountNeeded >= lpOf(msg.sender)){
                // if >= current lp, use all lp
                lpAmountNeeded = lpOf(msg.sender);
            }
        }
        //withdraw from farm then remove liquidity
        masterchef.withdraw(farmPid, lpAmountNeeded);
        (uint256 amountA,uint256 amountB) = removeLiquidity(lpAmountNeeded);
        token1.transfer(msg.sender, amountB);

        uint256 burnAmount = amountA.mul(80).div(100);
        if (burnAmount > 0) {
            spyn.transfer(DEAD_WALLET, burnAmount);
        }
        uint256 remainingAmount = amountA.sub(burnAmount);
        if (remainingAmount > 0) {
            spyn.transfer(feeTreasury, remainingAmount);
        }
        /*
        if(isReceiveToken1){
            // send as much as we can
            // doesn't guarantee enough $amount
            token1.transfer(msg.sender, swapSpynToToken1(amountA).add(amountB));
        }else{
            spyn.transfer(msg.sender, amountA);
            token1.transfer(msg.sender, amountB);
        }
        */
        // update state
        userInfo[msg.sender].withdraw(lpAmountNeeded);
        totalSupply = totalSupply.sub(lpAmountNeeded);
        require(totalSupply > 0);
        if (address(spynLeaderboard) != address(0)) {
            IUniswapV2Pair pair = getSwappingPair();
            spynLeaderboard.recordUnstaking(msg.sender, address(pair), lpAmountNeeded);
        }
        emit Withdraw(msg.sender, lpAmountNeeded);
    }

    function migrateTo(address account) external override updateReward(account) nonReentrant waitForCompound {
        require(userInfo[account].amount > 0);
        require(msg.sender == migrateToContract);

        uint256 lpAmount = userInfo[account].amount;
        masterchef.withdraw(farmPid, lpAmount);
        getSwappingPair().transfer(msg.sender, lpAmount);
        userInfo[account].withdraw(lpAmount);
        totalSupply = totalSupply.sub(lpAmount);
        require(totalSupply > 0);
        if (address(spynLeaderboard) != address(0)) {
            IUniswapV2Pair pair = getSwappingPair();
            spynLeaderboard.recordUnstaking(msg.sender, address(pair), lpAmount);
        }
        emit MigratedTo(account, msg.sender, lpAmount);
    }

    function migrateFrom() external override updateReward(msg.sender) nonReentrant waitForCompound {
        IUniswapV2Pair pair = getSwappingPair();
        uint256 balanceOfPairBeforeTransfer = pair.balanceOf(address(this));
        IMigratable(migrateFromContract).migrateTo(msg.sender);
        uint256 amountPairReceived = pair.balanceOf(address(this)) - balanceOfPairBeforeTransfer;

        require (amountPairReceived > 0);
        _depositLP(msg.sender, amountPairReceived);
        emit MigratedFrom(msg.sender, migrateFromContract, amountPairReceived);
    }

    // function withdrawLP(uint256 lpAmount) external updateReward(msg.sender) nonReentrant waitForCompound {
    //     require(userInfo[msg.sender].amount >= lpAmount, "INSUFFICIENT_LP");
    //     masterchef.withdraw(farmPid, lpAmount);
    //     getSwappingPair().transfer(msg.sender, lpAmount);
    //     userInfo[msg.sender].withdraw(lpAmount);
    //     emit Withdraw(msg.sender, lpAmount);
    // }

    // emergency only! withdraw don't care about rewards
    // function emergencyWithdraw(uint256 lpAmount) external nonReentrant waitForCompound {
    //     require(userInfo[msg.sender].amount >= lpAmount, "INSUFFICIENT_LP");
    //     masterchef.withdraw(farmPid, lpAmount);
    //     getSwappingPair().transfer(msg.sender, lpAmount);
    //     userInfo[msg.sender].withdraw(lpAmount);
    //     emit Withdraw(msg.sender, lpAmount);
    // }

    function harvest(bool isReceiveToken1) external updateReward(msg.sender) nonReentrant noCallFromContract waitForCompound {
        // function to harvest rewards
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            userInfo[msg.sender].harvest(block.number);
            //get corresponding amount in LP
            uint256 lpNeeded = getLPTokenByAmount0(reward);
            masterchef.withdraw(farmPid, lpNeeded);
            (uint256 amountSpyn,uint256 amountToken1) = removeLiquidity(lpNeeded);
            if(isReceiveToken1) {
                uint256 balanceBefore = token1.balanceOf(address(this));
                router.swapExactTokensForTokens(
                    amountSpyn,
                    0,
                    getSpynToken1Route(),
                    address(this),
                    block.timestamp
                );
                uint256 balanceAfter = token1.balanceOf(address(this));
                amountToken1 = amountToken1.add(balanceAfter).sub(balanceBefore);

                uint256 feeTaken = takeHarvestFee(msg.sender, amountToken1, address(token1));
                amountToken1 = amountToken1.sub(feeTaken);
                token1.transfer(msg.sender, amountToken1);
            }else{
                uint256 balanceBefore = spyn.balanceOf(address(this));
                router.swapExactTokensForTokens(
                    amountToken1,
                    0,
                    getToken1SpynRoute(),
                    address(this),
                    block.timestamp
                );
                uint256 balanceAfter = spyn.balanceOf(address(this));
                amountSpyn = amountSpyn.add(balanceAfter).sub(balanceBefore);

                uint256 feeTaken = takeHarvestFee(msg.sender, amountSpyn, address(spyn));
                amountSpyn = amountSpyn.sub(feeTaken);
                spyn.transfer(msg.sender, amountSpyn);
            }
            emit RewardPaid(msg.sender, reward);
        }
    }

    function compound() external updateReward(address(0)) nonReentrant {
        // function to compound for pool
        bool _canCompound = canCompound();
        if (_canCompound) {
            lastCompoundRewardPerToken = pendingRewardPerToken();
            // harvesting by deposit 0
            depositStakingPool(0);
            uint256 amountCollected = spyn.balanceOf(address(this));
            uint256 rewardForCaller = amountCollected.mul(percentFeeForCompounding).div(1000);
            uint256 rewardForPool = amountCollected.sub(rewardForCaller);
            // swap -> add liquidity -> stake back to pool
            (uint256 res0,) = getPairReserves();
            uint256 spynAmountToSwap = SwapMath.calculateSwapInAmount(res0, rewardForPool);
            uint256 token1Out = swapSpynToToken1(spynAmountToSwap);
            (,, uint256 liquidityAmount) = router.addLiquidity(
                address(spyn),
                address(token1),
                rewardForPool.sub(spynAmountToSwap),
                token1Out,
                0,
                0,
                address(this),
                block.timestamp
            );
            depositStakingPool(liquidityAmount);
            spyn.transfer(msg.sender, rewardForCaller);
            lastUpdatePoolPendingReward = 0;
            emit Compound(msg.sender, rewardForPool);
        }
    }

    function resetUpdatePoolReward() external onlyOwner {
        lastUpdatePoolPendingReward = 0;
    }

    function pendingSpynNextCompound() public view returns (uint256){
        (,,uint256 rewardLockedUp,) = masterchef.userInfo(farmPid, address(this));
        return masterchef.pendingSpyn(farmPid, address(this)).add(rewardLockedUp);
    }

    function rewardForCompounder() external view returns (uint256){
        return pendingSpynNextCompound().mul(percentFeeForCompounding).div(1000);
    }

    // Pay referral commission to the referrer who referred this user.
    function takeHarvestFee(address _user, uint256 _pending, address _token) internal returns (uint256 feeTaken) {
        uint256 referralFeeMissing;
        uint256 referralFeeTaken;
        if (address(spynReferral) != address(0)) {
            address[] memory referrersByLevel = spynReferral.getReferrersByLevel(_user, harvestReferralCommissionRates.length);

            uint256 commissionAmount;
            for (uint256 i = 0; i < harvestReferralCommissionRates.length; i ++) {
                commissionAmount = _pending.mul(harvestReferralCommissionRates[i]).div(10000);
                if (commissionAmount > 0 && referrersByLevel[i] != address(0)) {
                    referralFeeTaken = referralFeeTaken.add(commissionAmount);
                    if (address(spynLeaderboard) != address(0) && spynLeaderboard.hasStaking(referrersByLevel[i])) {
                        IERC20(_token).transfer(referrersByLevel[i], commissionAmount);
                        spynReferral.recordReferralCommission(referrersByLevel[i], _user, commissionAmount, _token, 0, i);
                        emit HarvestReferralCommissionPaid(_user, referrersByLevel[i], i + 1, commissionAmount);
                    } else {
                        IERC20(_token).transfer(treasury, commissionAmount);
                        spynReferral.recordReferralCommissionMissing(referrersByLevel[i], _user, commissionAmount, _token, 0, i);
                        emit HarvestReferralCommissionMissed(_user, referrersByLevel[i], i + 1, commissionAmount);
                    }
                } else {
                    referralFeeMissing = referralFeeMissing.add(commissionAmount);
                }
            }
        } else {
            uint256 commissionAmount;
            for (uint256 i = 0; i < harvestReferralCommissionRates.length; i ++) {
                commissionAmount = _pending.mul(harvestReferralCommissionRates[i]).div(10000);
                referralFeeMissing = referralFeeMissing.add(commissionAmount);
            }
        }


        uint256 harvestFeeAmount = _pending.mul(harvestFee).div(10000);
        harvestFeeAmount = harvestFeeAmount.add(referralFeeMissing);
        if (harvestFeeAmount > 0) {
            IERC20(_token).transfer(feeTreasury, harvestFeeAmount);
        }

        feeTaken = harvestFeeAmount.add(referralFeeTaken);
    }

    // Pay referral commission to the referrer who referred this user.
    function takeDepositFee(address _user, uint256 _depositedAmount, address _token) internal returns (uint256 feeTaken) {
        uint256 referralFeeMissing;
        uint256 referralFeeTaken;

        // take referral fee
        if (address(spynReferral) != address(0)) {
            address[] memory referrersByLevel = spynReferral.getReferrersByLevel(_user, depositReferralCommissionRates.length);

            uint256 commissionAmount;
            for (uint256 i = 0; i < depositReferralCommissionRates.length; i ++) {
                commissionAmount = _depositedAmount.mul(depositReferralCommissionRates[i]).div(10000);
                if (commissionAmount > 0 && referrersByLevel[i] != address(0)) {
                    referralFeeTaken = referralFeeTaken.add(commissionAmount);
                    if (address(spynLeaderboard) != address(0) && spynLeaderboard.hasStaking(referrersByLevel[i])) {
                        IERC20(_token).transfer(referrersByLevel[i], commissionAmount);
                        spynReferral.recordReferralCommission(referrersByLevel[i], _user, commissionAmount, _token, 1, i);
                        emit DepositReferralCommissionPaid(_user, referrersByLevel[i], i + 1, commissionAmount, _token);
                    } else {
                        IERC20(_token).transfer(treasury, commissionAmount);
                        spynReferral.recordReferralCommissionMissing(referrersByLevel[i], _user, commissionAmount, _token, 1, i);
                        emit DepositReferralCommissionMissed(_user, referrersByLevel[i], i + 1, commissionAmount, _token);
                    }
                } else {
                    referralFeeMissing = referralFeeMissing.add(commissionAmount);
                }
            }
        } else {
            uint256 commissionAmount;
            for (uint256 i = 0; i < depositReferralCommissionRates.length; i ++) {
                commissionAmount = _depositedAmount.mul(depositReferralCommissionRates[i]).div(10000);
                referralFeeMissing = referralFeeMissing.add(commissionAmount);
            }
        }

        // take deposit fee
        uint256 depositFeeAmount = _depositedAmount.mul(depositFee).div(10000);
        depositFeeAmount = depositFeeAmount.add(referralFeeMissing);
        if (depositFeeAmount > 0) {
            IERC20(_token).transfer(feeTreasury, depositFeeAmount);
        }

        feeTaken = depositFeeAmount.add(referralFeeTaken);
    }

    function swapToken1ToSpyn(uint256 amountToSwap) internal returns (uint256 amountOut) {
        uint256 spynBalanceBefore = spyn.balanceOf(address(this));
        router.swapExactTokensForTokens(
            amountToSwap,
            0,
            getToken1SpynRoute(),
            address(this),
            block.timestamp
        );
        amountOut = spyn.balanceOf(address(this)).sub(spynBalanceBefore);
    }

    function swapSpynToToken1(uint256 amountToSwap) internal returns (uint256 amountOut) {
        uint256 token1BalanceBefore = token1.balanceOf(address(this)); // remove for testing
        router.swapExactTokensForTokens(
            amountToSwap,
            0,
            getSpynToken1Route(),
            address(this),
            block.timestamp
        );
        amountOut = token1.balanceOf(address(this)).sub(token1BalanceBefore);
    }

    function removeLiquidity(uint256 lpAmount) internal returns (uint256 amountSpyn, uint256 amountToken1){
        uint256 spynBalanceBefore = spyn.balanceOf(address(this));
        (,amountToken1) = router.removeLiquidity(
            address(spyn),
            address(token1),
            lpAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
        amountSpyn = spyn.balanceOf(address(this)).sub(spynBalanceBefore);
    }

    function depositStakingPool(uint256 amount) internal {
        masterchef.deposit(farmPid, amount, address(0));
    }

    function getPairReserves() internal view returns (uint reserveA, uint reserveB) {
        address token0 = address(spyn) < address(token1) ? address(spyn) : address(token1);
        (uint reserve0, uint reserve1, ) = getSwappingPair().getReserves();
        (reserveA, reserveB) = address(spyn) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getToken1SpynRoute() private view returns (address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(token1);
        paths[1] = address(spyn);
    }

    function getSpynToken1Route() private view returns (address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(spyn);
        paths[1] = address(token1);
    }
}