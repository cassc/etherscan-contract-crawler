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
import "./interfaces/IMigratable.sol";
import "./libs/UserInfo.sol";
import "./libs/SwapMath.sol";
import "./libs/ISpynReferral.sol";
import "./libs/ISpynLeaderboard.sol";

/*
A vault that helps users stake in SPYN farms and pools more simply.
Supporting auto compound in Single Staking Pool.
*/

contract SingleFarmBnbV2 is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, IMigratable {
    using SafeMath for uint256;
    using UserInfo for UserInfo.Data;

    IERC20 public spyn;
    IERC20 public weth;
    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;
    IMasterChef public masterchef;
    ISpynReferral public spynReferral;
    ISpynLeaderboard public spynLeaderboard;
    uint256 public farmPid;

    uint256 public constant MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    address private constant DEAD_WALLET = address(0x000000000000000000000000000000000000dEaD);

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
    IMigratable public migrateToContract;
    IMigratable public migrateFromContract;

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

    // receive BNB
    fallback() external payable {
    }

    function initialize(
        uint256 _farmPid,
        address _spyn,
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
        router = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(_factory);
        weth = IERC20(router.WETH());
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
            factory.getPair(address(spyn), address(weth))
        );
    }

    function updateMigrateToContract(IMigratable _migrateToContract) external onlyOwner {
        migrateToContract = _migrateToContract;
    }

    function updateMigrateFromContract(IMigratable _migrateFromContract) external onlyOwner {
        migrateFromContract = _migrateFromContract;
    }

    function updateSpynReferral(ISpynReferral _spynReferral) external onlyOwner {
        spynReferral = _spynReferral;
    }

    function updateSpynLeaderboard(ISpynLeaderboard _spynLeaderboard) external onlyOwner {
        spynLeaderboard = _spynLeaderboard;
    }

    function setHarvestReferralCommissionRates(uint16[] memory _referralCommissionRates) public onlyOwner {
        require(_referralCommissionRates.length <= 10, "referral depth is too deep");
        harvestReferralCommissionRates = _referralCommissionRates;

        emit HarvestReferralCommissionRatesUpdated(_referralCommissionRates);
    }

    function setHarvestFee(uint256 _harvestFee) public onlyOwner {
        require(_harvestFee <= 3000, "setHarvetFee: must be less than 3000 (30%) ");
        harvestFee = _harvestFee;

        emit HarvestFeeUpdated(_harvestFee);
    }

    function setDepositReferralCommissionRates(uint16[] memory _referralCommissionRates) public onlyOwner {
        require(_referralCommissionRates.length <= 10, "referral depth is too deep");
        depositReferralCommissionRates = _referralCommissionRates;

        emit DepositReferralCommissionRatesUpdated(_referralCommissionRates);
    }

    function setDepositFee(uint256 _depositFee) public onlyOwner {
        require(_depositFee <= 3000, "setHarvetFee: must be less than 3000 (30%) ");
        depositFee = _depositFee;

        emit DepositFeeUpdated(_depositFee);
    }

    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "set treasury zero address");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setFeeTreasury(address _feeTreasury) public onlyOwner {
        require(_feeTreasury != address(0), "set treasury zero address");
        feeTreasury = _feeTreasury;
        emit FeeTreasuryUpdated(_feeTreasury);
    }

    function updatePercentFeeForCompounding(uint256 _rate) external onlyOwner {
        require(_rate <= 100, "max 10%");
        percentFeeForCompounding = _rate;
    }


    function approve() public {
        spyn.approve(address(masterchef), MAX_INT);
        spyn.approve(address(router), MAX_INT);
        getSwappingPair().approve(address(masterchef), MAX_INT);
        getSwappingPair().approve(address(router), MAX_INT);
    }

    function getReserveInAmount1ByLP(uint256 lp) public view returns (uint256 amount) {
        IUniswapV2Pair pair = getSwappingPair();
        uint256 balance0 = spyn.balanceOf(address(pair));
        uint256 balance1 = weth.balanceOf(address(pair));
        uint256 _totalSupply = pair.totalSupply();
        uint256 amount0 = lp.mul(balance0) / _totalSupply;
        uint256 amount1 = lp.mul(balance1) / _totalSupply;
        // convert amount0 -> amount1
        amount = amount1.add(amount0.mul(balance1).div(balance0));
    }

    /**
    * return lp Needed to get back total amount in amount 1
    * exp. amount = 1000 BUSD
    * lpNeeded returns 10
    * once remove liquidity, 10 LP will get back 500 BUSD and an amount in SPYN corresponding to 500 BUSD
    */
    function getLPTokenByAmount1(uint256 amount) internal view returns (uint256 lpNeeded) {
        (, uint256 res1) = getPairReserves();
        lpNeeded = amount.mul(getSwappingPair().totalSupply()).div(res1).div(2);
    }

    /**
    * return lp Needed to get back total amount in amount 0
    * exp. amount = 1000 SPYN
    * lpNeeded returns 10
    * once remove liquidity, 10 LP will get back 500 SPYN and an amount in BUSD corresponding to 500 SPYN
    */
    function getLPTokenByAmount0(uint256 amount) internal view returns (uint256 lpNeeded) {
        (uint256 res0,) = getPairReserves();
        lpNeeded = amount.mul(getSwappingPair().totalSupply()).div(res0).div(2);
    }

    // function to deposit BNB
    function deposit(address referrer) external payable updateReward(msg.sender) nonReentrant noCallFromContract waitForCompound {
        uint256 amount = msg.value;
        (, uint256 res1) = getPairReserves();
        
        if (
            address(spynReferral) != address(0) &&
            referrer != address(0) &&
            referrer != msg.sender
        ) {
            spynReferral.recordReferral(msg.sender, referrer);
        }
        
        if (amount > 0) {
            // take fee
            uint256 feeTaken = takeDepositFee(msg.sender, amount, address(0));
            amount = amount.sub(feeTaken);
        }

        uint256 amountToSwap = SwapMath.calculateSwapInAmount(res1, amount);
        uint256 spynOut = swapBnbToSpyn(amountToSwap);
        uint256 amountLeft = amount.sub(amountToSwap);
        (,uint256 amountBNB,uint256 liquidityAmount) = _addLiquidity(spynOut, amountLeft);
        _depositLP(msg.sender, liquidityAmount, true);
        // transfer back amount left
        if(amount > amountBNB+amountToSwap){
            payable(msg.sender).transfer(amount - (amountBNB + amountToSwap));
        }
    }

    function depositTokenPair(uint256 amountSpyn, address referrer) external payable updateReward(msg.sender) nonReentrant noCallFromContract waitForCompound {
        uint256 amountBNB = msg.value;
        uint256 balanceOfSpynBeforeTrasnfer = spyn.balanceOf(address(this));
        spyn.transferFrom(msg.sender, address(this), amountSpyn);
        uint256 amountSpynReceived = spyn.balanceOf(address(this)) - balanceOfSpynBeforeTrasnfer;

        if (
            address(spynReferral) != address(0) &&
            referrer != address(0) &&
            referrer != msg.sender
        ) {
            spynReferral.recordReferral(msg.sender, referrer);
        }

        if (amountSpynReceived > 0) {
            // take fee
            uint256 feeTaken = takeDepositFee(msg.sender, amountSpynReceived, address(spyn));
            amountSpynReceived = amountSpynReceived.sub(feeTaken);
        }

        if (amountBNB > 0) {
            // take fee
            uint256 feeTaken = takeDepositFee(msg.sender, amountBNB, address(0));
            amountBNB = amountBNB.sub(feeTaken);
        }

        // note spynAdded is might reduced by ~1%
        (uint256 spynAdded, uint256 bnbAdded, uint256 liquidityAmount) = _addLiquidity(amountSpynReceived, amountBNB);
        // transfer back amount that didn't add to the pool
        if(amountSpynReceived.mul(99).div(100) > spynAdded){
            uint256 amountLeft = amountSpynReceived.mul(99).div(100) - spynAdded;
            if(spyn.balanceOf(address(this)) >= amountLeft)
                spyn.transfer(msg.sender, amountLeft);
        }
        if(amountBNB > bnbAdded){
            payable(msg.sender).transfer(amountBNB - bnbAdded);
        }
        _depositLP(msg.sender, liquidityAmount, true);
    }

    function depositLP(uint256 amount, address referrer) external updateReward(msg.sender) nonReentrant noCallFromContract waitForCompound {
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
            // take fee
            uint256 feeTaken = takeDepositFee(msg.sender, amountPairReceived, address(pair));
            amountPairReceived = amountPairReceived.sub(feeTaken);
        }

        _depositLP(msg.sender, amountPairReceived, true);
    }

    function _depositLP(address account, uint256 liquidityAmount, bool record) internal {
        //stake in farms
        depositStakingPool(liquidityAmount);
        //set state
        userInfo[account].deposit(liquidityAmount);
        totalSupply = totalSupply.add(liquidityAmount);
        if (record && address(spynLeaderboard) != address(0)) {
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

        payable(msg.sender).transfer(amountB);
        uint256 burnAmount = amountA.mul(80).div(100);
        if (burnAmount > 0) {
            spyn.transfer(DEAD_WALLET, burnAmount);
        }
        uint256 remainingAmount = amountA.sub(burnAmount);
        if (remainingAmount > 0) {
            spyn.transfer(feeTreasury, remainingAmount);
        }
        // if(isReceiveBnb){
        //     // send as much as we can
        //     // doesn't guarantee enough $amount
        //     payable(msg.sender).transfer(swapSpynToBnb(amountA).add(amountB));
        // }else{
        //     spyn.transfer(msg.sender, amountA);
        //     payable(msg.sender).transfer(amountB);
        // }
        // update state
        userInfo[msg.sender].withdraw(lpAmountNeeded);
        totalSupply = totalSupply.sub(lpAmountNeeded);
        if (address(spynLeaderboard) != address(0)) {
            IUniswapV2Pair pair = getSwappingPair();
            spynLeaderboard.recordUnstaking(msg.sender, address(pair), lpAmountNeeded);
        }
        emit Withdraw(msg.sender, lpAmountNeeded);
    }

    function migrateTo(address account) external override updateReward(account) nonReentrant waitForCompound {
        require(userInfo[account].amount > 0, "INSUFFICIENT_LP");
        require(msg.sender == address(migrateToContract), "Invalid migration caller");

        uint256 lpAmount = userInfo[account].amount;
        
        masterchef.withdraw(farmPid, lpAmount);
        getSwappingPair().transfer(msg.sender, lpAmount);
        userInfo[account].withdraw(lpAmount);
        totalSupply = totalSupply.sub(lpAmount);
        require(totalSupply >= 0);
        /*
        // mistake deployed, avoid this record instead
        if (address(spynLeaderboard) != address(0)) {
            IUniswapV2Pair pair = getSwappingPair();
            spynLeaderboard.recordUnstaking(msg.sender, address(pair), lpAmount);
        }
        */
        emit MigratedTo(account, msg.sender, lpAmount);
    }

    function migrateFrom() external override updateReward(msg.sender) nonReentrant waitForCompound {
        IUniswapV2Pair pair = getSwappingPair();

        uint256 balanceOfPairBeforeTransfer = pair.balanceOf(address(this));
        migrateFromContract.migrateTo(msg.sender);
        uint256 amountPairReceived = pair.balanceOf(address(this)) - balanceOfPairBeforeTransfer;
        require (amountPairReceived > 0, "No amount migratable");
        _depositLP(msg.sender, amountPairReceived, false);
        emit MigratedFrom(msg.sender, address(migrateFromContract), amountPairReceived);
    }

    function harvest() external updateReward(msg.sender) nonReentrant noCallFromContract waitForCompound {
        // function to harvest rewards
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            uint256 poolBalance = spyn.balanceOf(address(this));
            require (reward <= poolBalance, "Not enough reward in the pool");
            userInfo[msg.sender].harvest(block.number);
            uint256 amountSpyn = reward;
            uint256 feeTaken = takeHarvestFee(msg.sender, amountSpyn, address(spyn));
            amountSpyn = amountSpyn.sub(feeTaken);
            spyn.transfer(msg.sender, amountSpyn);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function compound() external updateReward(address(0)) nonReentrant {
        // function to compound for pool
        bool _canCompound  = canCompound();
        if (_canCompound) {
            lastCompoundRewardPerToken = pendingRewardPerToken();
            // harvesting by deposit 0
            uint256 balanceBefore = spyn.balanceOf(address(this));
            depositStakingPool(0);
            uint256 amountCollected = spyn.balanceOf(address(this)).sub(balanceBefore);
            lastUpdatePoolPendingReward = 0;
            emit Compound(msg.sender, amountCollected);
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

    // take harvest fee
    function takeHarvestFee(address _user, uint256 _pending, address _token) internal returns (uint256 feeTaken) {
        uint256 referralFeeMissing;
        uint256 referralFeeTaken;

        // take referral fee
        if (address(spynReferral) != address(0)) {
            address[] memory referrersByLevel = spynReferral.getReferrersByLevel(_user, harvestReferralCommissionRates.length);

            uint256 commissionAmount;
            for (uint256 i = 0; i < harvestReferralCommissionRates.length; i ++) {
                commissionAmount = _pending.mul(harvestReferralCommissionRates[i]).div(10000);
                if (commissionAmount > 0 && referrersByLevel[i] != address(0)) {
                    referralFeeTaken = referralFeeTaken.add(commissionAmount);
                    if (address(spynLeaderboard) != address(0) && spynLeaderboard.hasStaking(referrersByLevel[i])) {
                        if (_token == address(0)) {
                            payable(referrersByLevel[i]).transfer(commissionAmount);
                            spynReferral.recordReferralCommission(referrersByLevel[i], _user, commissionAmount, address(0), 0, i);
                        } else {
                            IERC20(_token).transfer(referrersByLevel[i], commissionAmount);
                            spynReferral.recordReferralCommission(referrersByLevel[i], _user, commissionAmount, _token, 0, i);
                        }
                        emit HarvestReferralCommissionPaid(_user, referrersByLevel[i], i + 1, commissionAmount);
                    } else {
                        if (_token == address(0)) {
                            payable(treasury).transfer(commissionAmount);
                            spynReferral.recordReferralCommissionMissing(referrersByLevel[i], _user, commissionAmount, address(0), 0, i);
                        } else {
                            IERC20(_token).transfer(treasury, commissionAmount);
                            spynReferral.recordReferralCommissionMissing(referrersByLevel[i], _user, commissionAmount, _token, 0, i);
                        }
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

        // take harvest fee
        uint256 harvestFeeAmount = _pending.mul(harvestFee).div(10000);
        harvestFeeAmount = harvestFeeAmount.add(referralFeeMissing);
        if (harvestFeeAmount > 0) {
            if (_token == address(0)) {
                payable(feeTreasury).transfer(harvestFeeAmount);
            } else {
                IERC20(_token).transfer(feeTreasury, harvestFeeAmount);
            }
        }

        feeTaken = harvestFeeAmount.add(referralFeeTaken);
    }

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
                        if (_token == address(0)) {
                            payable(referrersByLevel[i]).transfer(commissionAmount);
                            spynReferral.recordReferralCommission(referrersByLevel[i], _user, commissionAmount, address(0), 1, i);
                        } else {
                            IERC20(_token).transfer(referrersByLevel[i], commissionAmount);
                            spynReferral.recordReferralCommission(referrersByLevel[i], _user, commissionAmount, _token, 1, i);
                        }
                        emit DepositReferralCommissionPaid(_user, referrersByLevel[i], i + 1, commissionAmount, _token);
                    } else {
                        if (_token == address(0)) {
                            payable(treasury).transfer(commissionAmount);
                            spynReferral.recordReferralCommissionMissing(referrersByLevel[i], _user, commissionAmount, address(0), 1, i);
                        } else {
                            IERC20(_token).transfer(treasury, commissionAmount);
                            spynReferral.recordReferralCommissionMissing(referrersByLevel[i], _user, commissionAmount, _token, 1, i);
                        }
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
            if (_token == address(0)) {
                payable(feeTreasury).transfer(depositFeeAmount);
            } else {
                IERC20(_token).transfer(feeTreasury, depositFeeAmount);
            }
        }

        feeTaken = depositFeeAmount.add(referralFeeTaken);
    }
    
    function _addLiquidity(uint256 amount0, uint256 amount1) internal returns (uint amountToken, uint amountETH, uint liquidity) {
        return router.addLiquidityETH{value: amount1}(
            address(spyn),
            amount0,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function swapBnbToSpyn(uint256 amountToSwap) internal returns (uint256 amountOut) {
        uint256 spynBalanceBefore = spyn.balanceOf(address(this));
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountToSwap}(
            0,
            getBnbToSpynRoute(),
            address(this),
            block.timestamp
        );
        amountOut = spyn.balanceOf(address(this)).sub(spynBalanceBefore);
    }

    function swapSpynToBnb(uint256 amountToSwap) internal returns (uint256 amountOut) {
        uint256 balanceBefore = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            getSpynToBnbRoute(),
            address(this),
            block.timestamp
        );
        amountOut = address(this).balance.sub(balanceBefore);
    }

    function removeLiquidity(uint256 lpAmount) internal returns (uint256 amountSpyn, uint256 amountBNB){
        uint256 spynBalanceBefore = spyn.balanceOf(address(this));
        (amountBNB) = router.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(spyn),
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
        address token0 = address(spyn) < address(weth) ? address(spyn) : address(weth);
        (uint reserve0, uint reserve1, ) = getSwappingPair().getReserves();
        (reserveA, reserveB) = address(spyn) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }


    function getBnbToSpynRoute() private view returns (address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(weth);
        paths[1] = address(spyn);
    }

    function getSpynToBnbRoute() private view returns (address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(spyn);
        paths[1] = address(weth);
    }
}