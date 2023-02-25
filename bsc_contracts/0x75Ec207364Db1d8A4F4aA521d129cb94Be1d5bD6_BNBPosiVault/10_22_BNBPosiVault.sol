pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@positionex/posi-token/contracts/VestingScheduleLogic.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IPosiStakingManager.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./library/UserInfo.sol";
import "./library/SwapMath.sol";
import "./library/TwapLogic.sol";
import "./interfaces/IPositionReferral.sol";
import "./interfaces/IVaultReferralTreasury.sol";
import "./interfaces/ISpotHouse.sol";
import "./modules/IBNBVaultLogic.sol";

/*
A vault that helps users stake in POSI farms and pools more simply.
Supporting auto compound in Single Staking Pool.
*/

contract BNBPosiVault is
Initializable,
ReentrancyGuardUpgradeable,
OwnableUpgradeable,
VestingScheduleLogic
{
    using SafeMath for uint256;
    using UserInfo for UserInfo.Data;
    using TwapLogic for TwapLogic.ReserveSnapshot[];

    IERC20 public posi;
    IERC20 public weth;
    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;
    IPosiStakingManager public posiStakingManager;
    IPositionReferral public positionReferral;
    uint256 public constant POSI_BNB_PID = 2;
    //
    //    // TESTNET
    //    IERC20 public posi = IERC20(0xb228359B5D83974F47655Ee41f17F3822A1fD0DD);
    //    IERC20 public busd = IERC20(0x787cF64b9F6E3d9E120270Cb84e8Ba1Fe8C1Ae09);
    //    IUniswapV2Router02 public router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    //    IUniswapV2Factory public factory = IUniswapV2Factory(0x6725F303b657a9451d8BA641348b6761A6CC7a17);
    //    IPosiStakingManager public posiStakingManager = IPosiStakingManager(0xD0A6C46316f789Ba3bdC320ebCC9AFdaE752fd73);
    //    IPositionReferral public positionReferral;
    //    uint256 public constant POSI_BNB_PID = 2;

    uint256 public constant MAX_INT =
    115792089237316195423570985008687907853269984665640564039457584007913129639935;

    mapping(address => UserInfo.Data) public userInfo;
    uint256 public totalSupply;
    uint256 public pendingRewardPerTokenStored;
    uint256 public lastUpdatePoolPendingReward;
    uint256 public lastCompoundRewardPerToken;

    uint256 public referralCommissionRate;
    uint256 public percentFeeForCompounding;

    IVaultReferralTreasury public vaultReferralTreasury;

    ISpotHouse public spotHouse;
    IPairManager public pairManager;
    mapping(address => mapping(VestingFrequencyHelper.Frequency => VestingData[]))
    public vestingSchedule;
    TwapLogic.ReserveSnapshot[] public reserveSnapshots;
    TwapLogic.ReserveSnapshot[] public res0Snapshots;

    IBNBVaultLogic public vaultLogic;

    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event Harvest(address account, uint256 amount);
    event Compound(address caller, uint256 reward);
    event RewardPaid(address account, uint256 reward);
    event ReferralCommissionPaid(
        address indexed user,
        address indexed referrer,
        uint256 commissionAmount
    );

    modifier noCallFromContract() {
        // due to flashloan attack
        // we don't like contract calls to our vault
        require(tx.origin == msg.sender, "no contract call");
        _;
    }

    modifier updateReward(address account) {
        pendingRewardPerTokenStored = pendingRewardPerToken();
        if (pendingRewardPerTokenStored != 0) {
            lastUpdatePoolPendingReward = totalPoolPendingRewards();
        }

        if (account != address(0)) {
            if (
                lastCompoundRewardPerToken >=
                userInfo[account].pendingRewardPerTokenPaid
            ) {
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

    modifier waitForCompound() {
        require(!canCompound(), "Call compound first");
        _;
    }

    // receive BNB
    fallback() external payable {}

    // receive BNB
    receive() external payable {}

    function initialize(
        address _posi,
        address _router,
        address _factory,
        address _posiStakingManager,
        address _vaultReferralTreasury
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        /*
        MAINNET
        posi = IERC20(0x5CA42204cDaa70d5c773946e69dE942b85CA6706);
        busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        factory = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
        posiStakingManager = IPosiStakingManager(0x0C54B0b7d61De871dB47c3aD3F69FEB0F2C8db0B);
        */
        posi = IERC20(_posi);
        router = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(_factory);
        weth = IERC20(router.WETH());
        posiStakingManager = IPosiStakingManager(_posiStakingManager);
        vaultReferralTreasury = IVaultReferralTreasury(_vaultReferralTreasury);
        percentFeeForCompounding = 50;
        //default 5%
    }

    function canCompound() public view returns (bool) {
        return posiStakingManager.canHarvest(POSI_BNB_PID, address(this));
    }

    function nearestCompoundingTime() public view returns (uint256 time) {
        (,,, time) = posiStakingManager.userInfo(POSI_BNB_PID, address(this));
    }

    function balanceOf(address user) public view returns (uint256) {
        return getReserveInAmount1ByLP(userInfo[user].amount);
    }

    function lpOf(address user) public view returns (uint256) {
        return userInfo[user].amount;
    }

    function totalPoolPendingRewards() public view returns (uint256) {
        // minus 1% RFI fee on transferring token
        return
        posiStakingManager
        .pendingPosition(POSI_BNB_PID, address(this))
        .mul(99)
        .div(100)
        .add(vaultLogic.boostedRewards());
    }

    // total user's rewards: pending + earned
    function pendingEarned(address account) public view returns (uint256) {
        UserInfo.Data memory _userInfo = userInfo[account];
        uint256 _pendingRewardPerToken = pendingRewardPerToken();
        if (lastCompoundRewardPerToken >= _userInfo.pendingRewardPerTokenPaid) {
            // only count for the next change
            return
            lpOf(account)
            .mul(_pendingRewardPerToken.sub(lastCompoundRewardPerToken))
            .div(1e18);
        } else {
            return
            lpOf(account)
            .mul(
                _pendingRewardPerToken.sub(
                    _userInfo.pendingRewardPerTokenPaid
                )
            )
            .div(1e18)
            .add(_userInfo.pendingRewards);
        }
    }

    // total user's rewards ready to withdraw
    function earned(address account) public view returns (uint256) {
        UserInfo.Data memory _userInfo = userInfo[account];
        // save gas
        if (lastCompoundRewardPerToken < _userInfo.pendingRewardPerTokenPaid)
            return _userInfo.rewards;
        return
        lpOf(account)
        .mul(
            lastCompoundRewardPerToken.sub(
                _userInfo.pendingRewardPerTokenPaid
            )
        )
        .div(1e18)
        .add(_userInfo.pendingRewards)
        .add(_userInfo.rewards);
    }

    function pendingRewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return 0;
        }
        return
        pendingRewardPerTokenStored.add(
            totalPoolPendingRewards()
            .sub(lastUpdatePoolPendingReward)
            .mul(1e18)
            .div(totalSupply)
        );
    }

    function getSwappingPair() internal view returns (IUniswapV2Pair) {
        return IUniswapV2Pair(factory.getPair(address(posi), address(weth)));
    }

    function updatePositionReferral(
        IPositionReferral _positionReferral
    ) external onlyOwner {
        positionReferral = _positionReferral;
    }

    function updateReferralCommissionRate(uint256 _rate) external onlyOwner {
        require(_rate <= 2000, "max 20%");
        referralCommissionRate = _rate;
    }

    function updatePercentFeeForCompounding(uint256 _rate) external onlyOwner {
        require(_rate <= 100, "max 10%");
        percentFeeForCompounding = _rate;
    }

    function approve() public {
        posi.approve(address(posiStakingManager), MAX_INT);
        posi.approve(address(router), MAX_INT);
        getSwappingPair().approve(address(posiStakingManager), MAX_INT);
        getSwappingPair().approve(address(router), MAX_INT);
        _approveRewardTokenForSpotHouse();
    }

    function getReserveInAmount1ByLP(
        uint256 lp
    ) public view returns (uint256 amount) {
        IUniswapV2Pair pair = getSwappingPair();
        uint256 balance0 = posi.balanceOf(address(pair));
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
     * once remove liquidity, 10 LP will get back 500 BUSD and an amount in POSI corresponding to 500 BUSD
     */
    function getLPTokenByAmount1(
        uint256 amount
    ) internal view returns (uint256 lpNeeded) {
        (, uint256 res1,) = getSwappingPair().getReserves();
        lpNeeded = amount.mul(getSwappingPair().totalSupply()).div(res1).div(2);
    }

    /**
     * return lp Needed to get back total amount in amount 0
     * exp. amount = 1000 POSI
     * lpNeeded returns 10
     * once remove liquidity, 10 LP will get back 500 POSI and an amount in BUSD corresponding to 500 POSI
     */
    function getLPTokenByAmount0(
        uint256 amount
    ) public view returns (uint256 lpNeeded) {
        (uint256 res0, ,) = getSwappingPair().getReserves();
        lpNeeded = amount.mul(getSwappingPair().totalSupply()).div(res0).div(2);
    }

    // function to deposit BNB
    function deposit(
        address referrer
    )
    external
    payable
    updateReward(msg.sender)
    nonReentrant
    noCallFromContract
    waitForCompound
    {
        uint256 amount = msg.value;
        (, uint256 res1,) = getSwappingPair().getReserves();
        uint256 amountToSwap = SwapMath.calculateSwapInAmount(res1, amount);
        uint256 posiOut = swapBnbToPosi(amountToSwap);
        uint256 amountLeft = amount.sub(amountToSwap);
        (, uint256 amountBNB, uint256 liquidityAmount) = _addLiquidity(
            posiOut,
            amountLeft
        );
        _depositLP(msg.sender, liquidityAmount, referrer);
        // transfer back amount left
        if (amount > amountBNB + amountToSwap) {
            payable(msg.sender).transfer(amount - (amountBNB + amountToSwap));
        }
    }

    function depositTokenPair(
        uint256 amountPosi,
        address referrer
    )
    external
    payable
    updateReward(msg.sender)
    nonReentrant
    noCallFromContract
    waitForCompound
    {
        uint256 amountBNB = msg.value;
        uint256 balanceOfPosiBeforeTrasnfer = posi.balanceOf(address(this));
        posi.transferFrom(msg.sender, address(this), amountPosi);
        uint256 amountPosiReceived = posi.balanceOf(address(this)) -
        balanceOfPosiBeforeTrasnfer;
        // note posiAdded is might reduced by ~1%
        (
        uint256 posiAdded,
        uint256 bnbAdded,
        uint256 liquidityAmount
        ) = _addLiquidity(amountPosiReceived, amountBNB);
        // transfer back amount that didn't add to the pool
        if (amountPosiReceived.mul(99).div(100) > posiAdded) {
            uint256 amountLeft = amountPosiReceived.mul(99).div(100) -
            posiAdded;
            if (posi.balanceOf(address(this)) >= amountLeft)
                posi.transfer(msg.sender, amountLeft);
        }
        if (amountBNB > bnbAdded) {
            payable(msg.sender).transfer(amountBNB - bnbAdded);
        }
        _depositLP(msg.sender, liquidityAmount, referrer);
    }

    function depositLP(
        uint256 amount,
        address referrer
    )
    external
    updateReward(msg.sender)
    nonReentrant
    noCallFromContract
    waitForCompound
    {
        getSwappingPair().transferFrom(msg.sender, address(this), amount);
        _depositLP(msg.sender, amount, referrer);
    }

    function _depositLP(
        address account,
        uint256 liquidityAmount,
        address referrer
    ) internal {
        if (
            address(positionReferral) != address(0) &&
            referrer != address(0) &&
            referrer != account
        ) {
            positionReferral.recordReferral(account, referrer);
        }
        //stake in farms
        depositStakingPool(liquidityAmount);
        //set state
        userInfo[account].deposit(liquidityAmount);
        totalSupply = totalSupply.add(liquidityAmount);
        emit Deposit(account, liquidityAmount);
    }

    function withdraw(
        uint256 amount,
        bool isReceiveBnb
    )
    external
    updateReward(msg.sender)
    nonReentrant
    noCallFromContract
    waitForCompound
    {
        uint256 lpAmountNeeded;
        if (amount >= balanceOf(msg.sender)) {
            // withdraw all
            lpAmountNeeded = lpOf(msg.sender);
        } else {
            //calculate LP needed that corresponding with amount
            lpAmountNeeded = getLPTokenByAmount1(amount);
            if (lpAmountNeeded >= lpOf(msg.sender)) {
                // if >= current lp, use all lp
                lpAmountNeeded = lpOf(msg.sender);
            }
        }
        //withdraw from farm then remove liquidity
        posiStakingManager.withdraw(POSI_BNB_PID, lpAmountNeeded);
        (uint256 amountA, uint256 amountB) = removeLiquidity(lpAmountNeeded);
        if (isReceiveBnb) {
            // send as much as we can
            // doesn't guarantee enough $amount
            payable(msg.sender).transfer(swapPosiToBnb(amountA).add(amountB));
        } else {
            posi.transfer(msg.sender, amountA);
            payable(msg.sender).transfer(amountB);
        }
        // update state
        userInfo[msg.sender].withdraw(lpAmountNeeded);
        totalSupply = totalSupply.sub(lpAmountNeeded);
        emit Withdraw(msg.sender, lpAmountNeeded);
    }

    function withdrawLP(
        uint256 lpAmount
    ) external updateReward(msg.sender) nonReentrant waitForCompound {
        require(userInfo[msg.sender].amount >= lpAmount, "INSUFFICIENT_LP");
        posiStakingManager.withdraw(POSI_BNB_PID, lpAmount);
        getSwappingPair().transfer(msg.sender, lpAmount);
        userInfo[msg.sender].withdraw(lpAmount);
        emit Withdraw(msg.sender, lpAmount);
    }

    // emergency only! withdraw don't care about rewards
    function emergencyWithdraw(
        uint256 lpAmount
    ) external nonReentrant waitForCompound {
        require(userInfo[msg.sender].amount >= lpAmount, "INSUFFICIENT_LP");
        posiStakingManager.withdraw(POSI_BNB_PID, lpAmount);
        getSwappingPair().transfer(msg.sender, lpAmount);
        userInfo[msg.sender].withdraw(lpAmount);
        emit Withdraw(msg.sender, lpAmount);
    }

    function harvest(
        bool isReceiveBnb
    )
    external
    updateReward(msg.sender)
    nonReentrant
    noCallFromContract
    waitForCompound
    {
        // function to harvest rewards
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            userInfo[msg.sender].harvest(block.number);
            // convert reward token to POSI
            reward = _convertEarnedTokenToPOSI(reward);
            //get corresponding amount in LP
            uint256 lpNeeded = getLPTokenByAmount0(reward);
            if (isReceiveBnb) {
                // send 5% only
                // then lock 95%
                _addSchedules(msg.sender, lpNeeded.mul(95).div(100));
                lpNeeded = lpNeeded.mul(5).div(100);
            }
            posiStakingManager.withdraw(POSI_BNB_PID, lpNeeded);
            (uint256 amountPosi, uint256 amountBNB) = removeLiquidity(lpNeeded);
            if (isReceiveBnb) {
                payable(msg.sender).transfer(
                    swapPosiToBnb(amountPosi).add(amountBNB)
                );
            } else {
                posi.transfer(
                    msg.sender,
                    swapBnbToPosi(amountBNB).add(amountPosi)
                );
            }
            payReferralCommission(msg.sender, reward);
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
            uint256 rewardBalance = rewardToken().balanceOf(address(this));
            _convertRewardTokenToPosi(rewardBalance);
            uint256 _posiBalance = posi.balanceOf(address(this));
            uint256 amountCollected = (_posiBalance * 99) /
            100;
            // genesis balance
            if(_posiBalance == 100000000000000){
                amountCollected = 0;
            }
            uint256 rewardForPool;
            if(amountCollected > 0){
                uint256 rewardForCaller = amountCollected
                .mul(percentFeeForCompounding)
                .div(1000);
                rewardForPool = amountCollected.sub(rewardForCaller);
                // swap -> add liquidity -> stake back to pool
                (uint256 res0, ,) = getSwappingPair().getReserves();
                uint256 posiAmountToSwap = SwapMath.calculateSwapInAmount(
                    res0,
                    rewardForPool
                );
                uint256 busdOut = swapPosiToBnb(posiAmountToSwap);

                (res0,,) = getSwappingPair().getReserves();
                res0Snapshots.addReserveSnapshot(uint128(res0));

                (, , uint256 liquidityAmount) = _addLiquidity(
                    rewardForPool.sub(posiAmountToSwap),
                    busdOut
                );
                depositStakingPool(liquidityAmount);
                posi.transfer(msg.sender, rewardForCaller);
            }

            lastUpdatePoolPendingReward = 0;
            emit Compound(msg.sender, rewardForPool);
        } else {
            revert("not time to compound");
        }
    }

    function pendingPositionNextCompound() public view returns (uint256) {
        return
        posiStakingManager
        .pendingPosition(POSI_BNB_PID, address(this))
        .mul(5)
        .div(100);
    }

    function rewardForCompounder() external view returns (uint256) {
        return
        pendingPositionNextCompound().mul(percentFeeForCompounding).div(
            1000
        );
    }

    function payReferralCommission(address _user, uint256 _pending) internal {
        if (
            address(positionReferral) != address(0) &&
            referralCommissionRate > 0
        ) {
            address referrer = positionReferral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(
                10000
            );
            if (referrer != address(0) && commissionAmount > 0) {
                if (
                    vaultReferralTreasury.payReferralCommission(
                        referrer,
                        commissionAmount
                    )
                )
                    emit ReferralCommissionPaid(
                        _user,
                        referrer,
                        commissionAmount
                    );
            }
        }
    }

    function _addLiquidity(
        uint256 amount0,
        uint256 amount1
    ) internal returns (uint amountToken, uint amountETH, uint liquidity) {
        (bytes memory data) = _forwardCall(
            abi.encodeWithSignature(
                "addLiquidityETH(address,address,uint256,uint256)",
                address(posi),
                address(router),
                amount0,
                amount1
            )
        );
        (amountToken, amountETH, liquidity) = abi.decode(data, (uint256, uint256, uint256));
    }


    function swapBnbToPosi(
        uint256 amountToSwap
    ) internal returns (uint256 amountOut) {
        (bytes memory data) = _forwardCall(
            abi.encodeWithSignature(
                "swapBnbToPosi(address,uint256)",
                address(router),
                amountToSwap
            )
        );
        return abi.decode(data, (uint256));
    }

    function swapPosiToBnb(
        uint256 amountToSwap
    ) internal returns (uint256 amountOut) {
        (bytes memory data) = _forwardCall(
            abi.encodeWithSignature(
                "swapPosiToBnb(address,uint256)",
                address(router),
                amountToSwap
            )
        );
        (amountOut) = abi.decode(data, (uint256));
    }

    function _forwardCall(bytes memory _data) internal returns (bytes memory) {
        (,bytes memory ipmlData)= address(vaultLogic).call(
            abi.encodeWithSignature("ipml()")
        );
        address _ipmlAddress = abi.decode(ipmlData, (address));
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool success, bytes memory data) = _ipmlAddress.delegatecall(_data);
        if(!success){
            revert(_getRevertMsg(data));
        }
        return data;
    }

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function removeLiquidity(
        uint256 lpAmount
    ) internal returns (uint256 amountPosi, uint256 amountBNB) {
        (bytes memory data) = _forwardCall(
            abi.encodeWithSignature(
                "removeLiquidityETH(address,uint256,uint256,uint256)",
                address(router),
                lpAmount,
                0,
                0
            )
        );
        return abi.decode(data, (uint256, uint256));
    }

    function depositStakingPool(uint256 amount) internal {
        _forwardCall(
            abi.encodeWithSignature(
                "depositStakingPool(uint256,uint256,address,address)",
                POSI_BNB_PID,
                amount,
                address(posiStakingManager),
                address(vaultReferralTreasury)
            )
        );
    }

    function changeSpotHouse(address newSpotHouse,address newSpotManager) external onlyOwner {
        __SpotManagerModule_init(newSpotHouse, newSpotManager);
        _approveRewardTokenForSpotHouse();
    }

    function init_v2(
        address newSpotHouse,
        address newSpotManager,
        address newStakingManager
    ) public onlyOwner {
        __SpotManagerModule_init(newSpotHouse, newSpotManager);
        posiStakingManager = IPosiStakingManager(newStakingManager);
        _approveRewardTokenForSpotHouse();
        reserveSnapshots.add(
            pairManager.getCurrentPip(),
            uint64(block.timestamp),
            uint64(block.number)
        );
        (uint256 res0, ,) = getSwappingPair().getReserves();
        res0Snapshots.add(
            uint128(res0),
            uint64(block.timestamp),
            uint64(block.number)
        );
    }

    function init_v3(address _vaultLogic) external onlyOwner {
        vaultLogic = IBNBVaultLogic(_vaultLogic);
    }

    function correctReserves(
        uint256 fromIndex,
        uint256 toIndex,
        uint256[] memory pips
    ) public onlyOwner {
        uint256 j = 0;
        for (uint256 i = fromIndex; i < toIndex; i++) {
            reserveSnapshots[i].pip = uint128(pips[j]);
            j++;
        }
    }

    function migrateFarm() public onlyOwner {
        IPosiStakingManager oldStakingManager = IPosiStakingManager(
            0x0C54B0b7d61De871dB47c3aD3F69FEB0F2C8db0B
        );
        (uint256 stakingAmount, , ,) = oldStakingManager.userInfo(
            POSI_BNB_PID,
            address(this)
        );
        // withdraw old one
        oldStakingManager.withdraw(POSI_BNB_PID, stakingAmount);
        // deposit new one
        posiStakingManager.deposit(
            POSI_BNB_PID,
            stakingAmount,
            address(vaultReferralTreasury)
        );
    }

    function init_reserve() public onlyOwner {
        reserveSnapshots.add(
            pairManager.getCurrentPip(),
            uint64(block.timestamp),
            uint64(block.number)
        );
        (uint256 res0, ,) = getSwappingPair().getReserves();
        res0Snapshots.add(
            uint128(res0),
            uint64(block.timestamp),
            uint64(block.number)
        );
    }

    function claimVesting(
        VestingFrequencyHelper.Frequency freq,
        uint256 index
    ) public override nonReentrant {
        super.claimVesting(freq, index);
    }

    function claimVestingBatch(
        VestingFrequencyHelper.Frequency[] memory freqs,
        uint256[] memory index
    ) public override nonReentrant {
        super.claimVestingBatch(freqs, index);
    }

    function rewardToken() public view returns (IERC20) {
        return pairManager.baseAsset();
    }

    // @dev Approve reward token for spot house
    // in order to open market order
    function _approveRewardTokenForSpotHouse() private {
        IERC20 _rewardToken = rewardToken();
        _rewardToken.approve(address(spotHouse), type(uint256).max);
    }

    function getTwapPip(uint256 itv) public view returns (uint256) {
        return reserveSnapshots.getReserveTwapPrice(itv);
    }

    function getTwapRes0(uint256 itv) public view returns (uint256) {
        return res0Snapshots.getReserveTwapPrice(itv);
    }

    function __SpotManagerModule_init(
        address _spotHouse,
        address _pairManager
    ) internal {
        spotHouse = ISpotHouse(_spotHouse);
        pairManager = IPairManager(_pairManager);
    }

    function _sellRewardTokenForPOSI(
        uint256 _amount
    ) internal returns (uint256 posiAmount) {
        IERC20 _posi = pairManager.quoteAsset();
        uint256 _balanceBefore = _posi.balanceOf(address(this));
        spotHouse.openMarketOrder(pairManager, ISpotHouse.Side.SELL, _amount);
        uint128 _pipAfter = pairManager.getCurrentPip();
        reserveSnapshots.addReserveSnapshot(10000);
        uint256 _balanceAfter = _posi.balanceOf(address(this));
        posiAmount = _balanceAfter - _balanceBefore;
    }

    function _convertRewardTokenToPosi(
        uint256 rewardAmount
    ) private returns (uint256 posiAmount) {
        if (rewardAmount == 0) return 0;
        // sell market reward token for posi
        return _sellRewardTokenForPOSI(rewardAmount);
    }

    function _transferLockedToken(
        address _to,
        uint192 _amount
    ) internal override {
        posiStakingManager.withdraw(POSI_BNB_PID, _amount);
        (uint256 amountPosi, uint256 amountBNB) = removeLiquidity(_amount);
        payable(msg.sender).transfer(swapPosiToBnb(amountPosi).add(amountBNB));
    }

    function _getVestingSchedules(
        address user,
        VestingFrequencyHelper.Frequency freq
    ) internal view override returns (VestingData[] memory) {
        return vestingSchedule[user][freq];
    }

    // override by convert amount to token 1
    function getVestingSchedules(
        address user,
        VestingFrequencyHelper.Frequency freq
    ) public view override returns (VestingData[] memory) {
        VestingData[] memory data = vestingSchedule[user][freq];
        for (uint i = 0; i < data.length; i++) {
            data[i].amount = uint192(
                getReserveInAmount1ByLP(uint256(data[i].amount))
            );
        }
        return data;
    }

    // Vesting override

    function _removeFirstSchedule(
        address user,
        VestingFrequencyHelper.Frequency freq
    ) internal override {
        _popFirstSchedule(vestingSchedule[user][freq]);
    }

    function _lockVestingSchedule(
        address _to,
        VestingFrequencyHelper.Frequency _freq,
        uint256 _amount
    ) internal override {
        vestingSchedule[_to][_freq].push(_newVestingData(_amount, _freq));
    }

    // use for mocking test
    function _setVestingTime(
        address user,
        uint8 freq,
        uint256 index,
        uint256 timestamp
    ) internal {
        vestingSchedule[user][VestingFrequencyHelper.Frequency(freq)][index]
        .vestingTime = uint64(timestamp);
    }

    function _convertEarnedTokenToPOSI(
        uint256 _baseAmount
    ) private view returns (uint256) {
        uint128 _basisPoint = pairManager.basisPoint();
        // Twap 3 days
        uint256 _twapPip = getTwapPip(259200);
        return
        uint256((uint128(_baseAmount) * uint128(_twapPip)) / _basisPoint);
    }
}