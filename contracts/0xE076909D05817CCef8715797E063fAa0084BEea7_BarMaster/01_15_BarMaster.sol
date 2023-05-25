// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./FarmToken.sol";
import "./GovToken.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswap.sol";
import "./interfaces/IWETH.sol";
import "./lib/ReentrancyGuard.sol";
import "./lib/Ownable.sol";
import "./lib/SafeMath.sol";
import "./lib/Math.sol";
import "./lib/Address.sol";
import "./lib/SafeERC20.sol";
import "./lib/FeeHelpers.sol";

// File: contracts/BarMaster.sol
contract BarMaster is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    address public weth;
    FarmToken public farmToken;
    GovToken public govToken;
    address payable public treasury;
    bool public treasuryDisabled = false;
    uint256 public constant HALVING_DURATION = 14 days;
    uint256 public rewardAllocation = 2000 * 10 ** 18;
    uint256 public halvingTimestamp = 0;
    uint256 public lastUpdateTimestamp = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardHalvingPercent = 25;
    uint256 public withdrawalLimitPercent = 25;
    uint256 public bloodyMaryExitFeePercent = 3;
    uint256 public farmingOpen = 1610211600;
    bool public farmingStarted = false;
    uint256 private constant STAKING_POOL_ID = 0;
    uint256 private constant ETH_LP_POOL_ID = 1;
    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address constant ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 public constant LIMITBUY_DURATION = 30 minutes;
    struct AccountInfo {
        uint256 index;
        uint256 balance;
        uint256 maxBalance;
        uint256 lastWithdrawTimestamp;
        uint256 lastStakedTimestamp;
        uint256 reward;
        uint256 rewardPerTokenPaid;
        uint256 lpEthReward;
        uint256 lpEthRewardPaid;
        uint256 lpCktlReward;
        uint256 lpCktlRewardPaid;
    }
    uint256 public unstakeLPFeePercent = 2;
    uint256 public unstakeTreasuryFeePercent = 2;
    uint256 public unstakeBurnFeePercent = 1;
    mapping(uint256 => mapping(address => AccountInfo)) public accountInfos;
    mapping(uint256 => address payable[]) public accountInfosIndex;
    struct PoolInfo {
        IERC20 pairAddress;
        IERC20 otherToken;
        uint256 rewardAllocation;
        uint256 totalSupply;
        uint256 borrowedSupply;
        uint256 rewardPerTokenStored;
    }
    PoolInfo[] public poolInfo;
    uint256 public claimBurnFee = 1;
    uint256 public claimTreasuryFeePercent = 2;
    uint256 public claimLPFeePercent = 2;
    uint256 public claimLiquidBalancePercent = 95;
    event Staked(address indexed from, uint256 amount, uint256 amountLP);
    event Withdrawn(address indexed to, uint256 poolId, uint256 amount, uint256 amountLP);
    event Claimed(address indexed to, uint256 poolId, uint256 amount);
    event ClaimedAndStaked(address indexed to, uint256 poolId, uint256 amount);
    event Halving(uint256 amount);
    event Received(address indexed from, uint256 amount);
    event EmergencyWithdraw(address indexed to, uint256 poolId, uint256 amount);
    event ClaimedLPReward(address indexed to, uint256 poolId, uint256 lpEthReward, uint256 lpCktlReward);
    constructor(address payable _treasury) public {
        farmToken = new FarmToken(address(this), farmingOpen.add(LIMITBUY_DURATION));
        govToken = new GovToken(address(this));
        router = IUniswapV2Router02(ROUTER_ADDRESS);
        factory = IUniswapV2Factory(router.factory());
        weth = router.WETH();
        treasury = _treasury;
        rewardRate = rewardAllocation.div(HALVING_DURATION);
        poolInfo.push(PoolInfo({
            pairAddress: farmToken,
            otherToken: farmToken,
            rewardAllocation: rewardAllocation.mul(30).div(100),
            borrowedSupply: 0,
            totalSupply: 0,
            rewardPerTokenStored: 0
        }));
        poolInfo.push(PoolInfo({
            pairAddress: IERC20(address(0)),
            otherToken: IERC20(weth),
            rewardAllocation: rewardAllocation.mul(70).div(100),
            borrowedSupply: 0,
            totalSupply: 0,
            rewardPerTokenStored: 0
        }));
    }
    function _checkRewards(uint256 _poolId) internal {
        PoolInfo storage pool = poolInfo[_poolId];
        pool.rewardPerTokenStored = rewardPerToken(_poolId);
        lastUpdateTimestamp = lastRewardTimestamp();
        if (msg.sender != address(0)) {
            accountInfos[_poolId][msg.sender].reward = rewardEarned(_poolId, msg.sender);
            accountInfos[_poolId][msg.sender].rewardPerTokenPaid = pool.rewardPerTokenStored;
        }
    }
    function _checkHalving() internal {
        if (block.timestamp >= halvingTimestamp) {
            rewardAllocation = rewardAllocation
                .sub(rewardAllocation.mul(rewardHalvingPercent).div(100));
            
            for (uint256 pid = 0; pid < poolInfo.length; pid++) {
                poolInfo[pid].rewardAllocation = poolInfo[pid].rewardAllocation
                    .sub(poolInfo[pid].rewardAllocation.mul(rewardHalvingPercent).div(100));
            }
            
            rewardRate = rewardAllocation.div(HALVING_DURATION);
            halvingTimestamp = halvingTimestamp.add(HALVING_DURATION);

            emit Halving(rewardAllocation);
        }
    }
    function _checkFarming() internal {
        require(farmingOpen <= block.timestamp, 'Farming not yet started.');
        if (!farmingStarted) {
            farmingStarted = true;
            halvingTimestamp = block.timestamp.add(HALVING_DURATION);
            lastUpdateTimestamp = block.timestamp;
        }
    }
    function init() external onlyOwner {
        if (factory.getPair(address(farmToken), weth) == address(0)) {
            poolInfo[ETH_LP_POOL_ID].pairAddress = IERC20(factory.createPair(address(farmToken), weth));
            farmToken.mint(treasury, 250 * 1e18);
        }
    }
    function stake(uint256 _poolId, uint256 _amount) external payable nonReentrant {
        _checkFarming();
        _checkHalving();
        _checkRewards(_poolId);
        if (_poolId == ETH_LP_POOL_ID) {
            _amount = msg.value;
        }
        require(_amount > 0, 'Invalid amount');
        require(!address(msg.sender).isContract() || address(msg.sender) == address(this), 'Invalid user');
        require(_poolId < poolInfo.length, 'Invalid pool');
        require(_poolId > STAKING_POOL_ID, 'Use staking pool');
        PoolInfo storage pool = poolInfo[_poolId];
        AccountInfo storage account = accountInfos[_poolId][msg.sender];
        uint256 boughtCktl = 0;
        if (_poolId == ETH_LP_POOL_ID) {
            if (pool.totalSupply > 0) {
                address[] memory swapPath = new address[](2);
                swapPath[0] = address(pool.otherToken);
                swapPath[1] = address(farmToken);
                IERC20(pool.otherToken).safeApprove(address(router), 0);
                IERC20(pool.otherToken).safeApprove(address(router), _amount.div(50));
                uint256[] memory amounts = router.swapExactETHForTokens{ value: _amount.div(50) }
                    (uint(0), swapPath, address(this), block.timestamp + 1 days);
                boughtCktl = amounts[amounts.length - 1];
                _amount = _amount.sub(_amount.div(50));
            } else {
                require(_amount >= (5 * 1e18), "Stake 5+ ETH to init pool");
            }
        }
        uint256 cktlTokenAmount = IERC20(farmToken).balanceOf(address(pool.pairAddress));
        uint256 otherTokenAmount = IERC20(pool.otherToken).balanceOf(address(pool.pairAddress));
        uint256 amountCktlTokenDesired = 0;
        if (_poolId == ETH_LP_POOL_ID) {
            amountCktlTokenDesired = (otherTokenAmount == 0) ? 
                _amount * 4 : _amount.mul(cktlTokenAmount).div(otherTokenAmount);
        } else {
            require(otherTokenAmount > 0, "Pool not started");
            amountCktlTokenDesired = _amount.mul(cktlTokenAmount).div(otherTokenAmount);
        }
        farmToken.mint(address(this), amountCktlTokenDesired.sub(boughtCktl));
        pool.borrowedSupply = pool.borrowedSupply.add(amountCktlTokenDesired);
        IERC20(farmToken).approve(address(router), amountCktlTokenDesired);
        uint256 liquidity;
        if (_poolId == ETH_LP_POOL_ID) {
            (,, liquidity) = router.addLiquidityETH{value : _amount}(
                address(farmToken), amountCktlTokenDesired, 0, 0, address(this), block.timestamp + 1 days);
        } else {
            IERC20(pool.otherToken).approve(address(router), _amount);
            (,, liquidity) = router.addLiquidity(
                address(pool.otherToken), address(farmToken), 
                _amount, amountCktlTokenDesired, 0, 0, address(this), block.timestamp + 1 days);
        }
        pool.totalSupply = pool.totalSupply.add(liquidity);
        account.balance = account.balance.add(liquidity);
        if (account.balance > account.maxBalance) {
            account.maxBalance = account.balance;
        }
        if (account.index == 0) {
            accountInfosIndex[_poolId].push(msg.sender);
            account.index = accountInfosIndex[_poolId].length;
        }
        account.lastStakedTimestamp = block.timestamp;
        if (account.lastWithdrawTimestamp == 0) {
            account.lastWithdrawTimestamp = block.timestamp;
        }
        emit Staked(msg.sender, _amount, liquidity);
    }
    function addToStakingPool(uint256 _amount, bool _claimAndStakeRewards) public nonReentrant {
        _checkFarming();
        _checkHalving();
        _checkRewards(STAKING_POOL_ID);
        PoolInfo storage pool = poolInfo[STAKING_POOL_ID];
        AccountInfo storage account = accountInfos[STAKING_POOL_ID][msg.sender];
        if (_claimAndStakeRewards) {
            uint256 rewardsDue = account.reward;
            for (uint256 pid = 1; pid < poolInfo.length; pid++) {
                if (accountInfos[pid][msg.sender].reward > 0) {
                    rewardsDue = rewardsDue.add(accountInfos[pid][msg.sender].reward);
                    accountInfos[pid][msg.sender].reward = 0;
                }
            }
            if (rewardsDue > 0) {
                farmToken.mint(address(this), rewardsDue);
                govToken.mint(msg.sender, rewardsDue);
                emit ClaimedAndStaked(msg.sender, STAKING_POOL_ID, rewardsDue);
                account.balance = account.balance.add(rewardsDue);
                if (account.balance > account.maxBalance) {
                    account.maxBalance = account.balance;
                }
                account.lastStakedTimestamp = block.timestamp;
                if (account.index == 0) {
                    accountInfosIndex[STAKING_POOL_ID].push(msg.sender);
                    account.index = accountInfosIndex[STAKING_POOL_ID].length;
                }
                pool.totalSupply = pool.totalSupply.add(rewardsDue);
                if (account.reward > 0) {
                    account.reward = 0;
                }
            }
        }
        if (_amount > 0) {
            require(farmToken.balanceOf(msg.sender) >= _amount, 'Invalid balance');
            farmToken.transferFrom(msg.sender, address(this), _amount);
            pool.totalSupply = pool.totalSupply.add(_amount);
            account.balance = account.balance.add(_amount);
            if (account.balance > account.maxBalance) {
                account.maxBalance = account.balance;
            }
            account.lastStakedTimestamp = block.timestamp;
            if (account.index == 0) {
                accountInfosIndex[STAKING_POOL_ID].push(msg.sender);
                account.index = accountInfosIndex[STAKING_POOL_ID].length;
            }
            govToken.mint(msg.sender, _amount);
            emit Staked(msg.sender, _amount, 0);
        }
    }
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    function claim(uint256 _poolId) external nonReentrant {
        _checkFarming();
        _checkHalving();
        _checkRewards(_poolId);
        require(_poolId < poolInfo.length, 'Invalid pool');
        PoolInfo storage pool = poolInfo[_poolId];
        AccountInfo storage account = accountInfos[_poolId][msg.sender];
        uint256 reward = account.reward;
        require(reward > 0, 'No rewards');
        if (reward > 0) {
            account.reward = 0;
            farmToken.mint(BURN_ADDRESS, reward.div(FeeHelpers.getClaimBurnFee(account.lastStakedTimestamp, claimBurnFee)));
            farmToken.mint(msg.sender, reward.div(FeeHelpers.getClaimLiquidBalancePcnt(account.lastStakedTimestamp, claimLiquidBalancePercent)));
            farmToken.mint(address(treasury), reward.div(FeeHelpers.getClaimTreasuryFee(account.lastStakedTimestamp, claimTreasuryFeePercent)));
            if (accountInfosIndex[_poolId].length > 0 && pool.totalSupply > 0) {
                for (uint256 i = 0; i < accountInfosIndex[_poolId].length; i ++) {
                    AccountInfo storage lpAccount = accountInfos[_poolId][accountInfosIndex[_poolId][i]];
                    if (lpAccount.balance > 0 && accountInfosIndex[_poolId][i] != msg.sender) {
                        lpAccount.lpCktlReward = lpAccount.lpCktlReward.add(lpAccount.balance
                            .mul(reward.div(FeeHelpers.getClaimLPFee(account.lastStakedTimestamp, claimLPFeePercent)))
                            .div(pool.totalSupply));
                    }
                }
            }
            uint256[] memory rewardAmounts = new uint256[](2);
            rewardAmounts[0] = reward
                .sub(reward.div(FeeHelpers.getClaimBurnFee(account.lastStakedTimestamp, claimBurnFee)))
                .sub(reward.div(FeeHelpers.getClaimLiquidBalancePcnt(account.lastStakedTimestamp, claimLiquidBalancePercent)))
                .sub(reward.div(FeeHelpers.getClaimTreasuryFee(account.lastStakedTimestamp, claimTreasuryFeePercent)))
                .sub(reward.div(FeeHelpers.getClaimLPFee(account.lastStakedTimestamp, claimLPFeePercent)));
            rewardAmounts[1] = rewardAmounts[0].div(2);
            farmToken.mint(address(this), rewardAmounts[0]);
            address[] memory swapPath = new address[](2);
            swapPath[0] = address(farmToken);
            swapPath[1] = address(weth);
            IERC20(farmToken).safeApprove(address(router), 0);
            IERC20(farmToken).safeApprove(address(router), rewardAmounts[1]);
            uint256[] memory swappedTokens = router.swapExactTokensForETH(rewardAmounts[1], uint(0), swapPath, address(this), block.timestamp + 1 days);
            uint256[] memory totalLp = new uint256[](3);
            IERC20(farmToken).safeApprove(address(router), 0);
            IERC20(farmToken).safeApprove(address(router), rewardAmounts[1]);
            (totalLp[0], totalLp[1], totalLp[2]) = router.addLiquidityETH{value: swappedTokens[swappedTokens.length - 1]}
                (address(farmToken), rewardAmounts[1], 0, 0, address(this), block.timestamp + 5 minutes);
            if (rewardAmounts[1].sub(totalLp[0]) > 0) {
                farmToken.mint(treasury, rewardAmounts[1].sub(totalLp[0]));
            }
            if (swappedTokens[swappedTokens.length - 1].sub(totalLp[1]) > 0) {
                treasury.transfer(swappedTokens[swappedTokens.length - 1].sub(totalLp[1]));
            }
            PoolInfo storage lpPool = poolInfo[ETH_LP_POOL_ID];
            AccountInfo storage lpAccount = accountInfos[ETH_LP_POOL_ID][msg.sender];
            lpPool.totalSupply = lpPool.totalSupply.add(totalLp[2]);
            lpPool.borrowedSupply = lpPool.borrowedSupply.add(totalLp[0]);
            lpAccount.balance = lpAccount.balance.add(totalLp[2]);
            if (lpAccount.index == 0) {
                accountInfosIndex[ETH_LP_POOL_ID].push(msg.sender);
                lpAccount.index = accountInfosIndex[ETH_LP_POOL_ID].length;
            }
            emit Claimed(msg.sender, _poolId, reward);
        }
    }
    function withdraw(uint256 _poolId) external nonReentrant {
        _checkFarming();
        _checkHalving();
        _checkRewards(_poolId);
        require(_poolId < poolInfo.length, 'Invalid pool');
        PoolInfo storage pool = poolInfo[_poolId];
        AccountInfo storage account = accountInfos[_poolId][msg.sender];
        require(account.lastWithdrawTimestamp + 12 hours <= block.timestamp, 'Invalid withdraw time');
        require(account.balance > 0, 'Invalid balance');
        uint256 _amount = account.maxBalance.mul(withdrawalLimitPercent).div(100);
        if (account.balance < _amount) {
            _amount = account.balance;
        }
        pool.totalSupply = pool.totalSupply.sub(_amount);
        account.balance = account.balance.sub(_amount);
        account.lastWithdrawTimestamp = block.timestamp;
        uint256[] memory totalToken = new uint256[](2);
        uint256 otherTokenAmountMinusFees = 0;
        if (_poolId == STAKING_POOL_ID) {
            totalToken[1] = _amount;
            govToken.burn(msg.sender, _amount);
            uint256 burnFee = _amount.div(FeeHelpers.getUnstakeBurnFee(account.lastStakedTimestamp, unstakeBurnFeePercent)); // calculate fee
            farmToken.burn(BURN_ADDRESS, burnFee);
            otherTokenAmountMinusFees = _amount.sub(burnFee);
        } else {
            IERC20(pool.pairAddress).approve(address(router), _amount);
            if (_poolId == ETH_LP_POOL_ID) {
                (uint256 cktlTokenAmount, uint256 otherTokenAmount) = router.removeLiquidityETH(address(farmToken), _amount, 0, 0, address(this), block.timestamp + 1 days);
                totalToken[0] = cktlTokenAmount;
                totalToken[1] = otherTokenAmount;
            } else {
                (uint256 cktlTokenAmount, uint256 otherTokenAmount) = router.removeLiquidity(address(farmToken), address(pool.otherToken), _amount, 0, 0, address(this), block.timestamp + 1 days);
                totalToken[0] = cktlTokenAmount;
                totalToken[1] = otherTokenAmount;
            }
            farmToken.burn(address(this), totalToken[0]);
            pool.borrowedSupply = pool.borrowedSupply.sub(totalToken[0]);
        }
        uint256 treasuryFee = 0;
        if (_poolId == ETH_LP_POOL_ID) {
            treasuryFee = FeeHelpers.getBloodyMaryExitFee(bloodyMaryExitFeePercent);
            treasuryFee = totalToken[1].div(treasuryFee);
            treasury.transfer(treasuryFee);
        } else {
            treasuryFee = FeeHelpers.getUnstakeTreasuryFee(account.lastStakedTimestamp, unstakeTreasuryFeePercent);
            treasuryFee = totalToken[1].div(treasuryFee);
            pool.otherToken.transfer(treasury, treasuryFee);
        }
        if (_poolId == STAKING_POOL_ID) {
            otherTokenAmountMinusFees = otherTokenAmountMinusFees.sub(treasuryFee);
        } else {
            otherTokenAmountMinusFees = totalToken[1].sub(treasuryFee);
        }
        if (accountInfosIndex[_poolId].length > 0 && pool.totalSupply > 0) {
            uint256 lpFee = 0;
            if (_poolId == ETH_LP_POOL_ID) {
                lpFee = FeeHelpers.getBloodyMaryExitFee(bloodyMaryExitFeePercent);
            } else {
                lpFee = FeeHelpers.getUnstakeLPFee(account.lastStakedTimestamp, unstakeLPFeePercent);
            }
            lpFee = totalToken[1].div(lpFee);
            for (uint256 i = 0; i < accountInfosIndex[_poolId].length; i ++) {
                AccountInfo storage lpAccount = accountInfos[_poolId][accountInfosIndex[_poolId][i]];
                if (lpAccount.balance > 0 && accountInfosIndex[_poolId][i] != msg.sender) {
                    if (_poolId == ETH_LP_POOL_ID) {
                        lpAccount.lpEthReward = lpAccount.lpEthReward.add(lpAccount.balance.mul(lpFee).div(pool.totalSupply));
                    } else {
                        lpAccount.lpCktlReward = lpAccount.lpCktlReward.add(lpAccount.balance.mul(lpFee).div(pool.totalSupply));
                    }
                }
            }
            otherTokenAmountMinusFees = otherTokenAmountMinusFees.sub(lpFee);
        }
        totalToken[1] = otherTokenAmountMinusFees;
        if (_poolId == ETH_LP_POOL_ID) {
            msg.sender.transfer(totalToken[1]);
        } else {
            pool.otherToken.transfer(msg.sender, totalToken[1]);
        }
        if (account.balance == 0 && account.index > 0 && account.index <= accountInfosIndex[_poolId].length) {
            uint256 accountIndex = account.index - 1;
            accountInfos[_poolId][accountInfosIndex[_poolId][accountInfosIndex[_poolId].length - 1]].index = accountIndex + 1; // Give it my index
            accountInfosIndex[_poolId][accountIndex] = accountInfosIndex[_poolId][accountInfosIndex[_poolId].length - 1]; // Give it my address
            accountInfosIndex[_poolId].pop();
            account.index = 0;
        }
        emit Withdrawn(msg.sender, _poolId, _amount, totalToken[1]);
    }
    function claimLP(uint256 _poolId) external {
        AccountInfo storage account = accountInfos[_poolId][msg.sender];
        require (account.lpEthReward > 0 || account.lpCktlReward > 0, 'No LP rewards');
        emit ClaimedLPReward(msg.sender, _poolId, account.lpEthReward, account.lpCktlReward);
        if (account.lpEthReward > 0) {
            account.lpEthRewardPaid = account.lpEthRewardPaid.add(account.lpEthReward);
            msg.sender.transfer(account.lpEthReward);
            account.lpEthReward = 0;
        }
        if (account.lpCktlReward > 0) {
            account.lpCktlRewardPaid = account.lpCktlRewardPaid.add(account.lpCktlReward);
            farmToken.mint(msg.sender, account.lpCktlReward);
            account.lpCktlReward = 0;
        }
    }
    function burn(uint256 amount) external {
        farmToken.burn(msg.sender, amount);
    }
    function set(uint256 _poolId, uint256 _rewardAllocation) external onlyOwner {
        require (_rewardAllocation <= 100, "Invalid allocation");
        uint256 totalAllocation = rewardAllocation.sub(poolInfo[_poolId].rewardAllocation).add(
            rewardAllocation.mul(_rewardAllocation).div(100)
        );
        require (totalAllocation <= rewardAllocation, "Allocation exceeded");
        if (poolInfo[_poolId].rewardAllocation != rewardAllocation.mul(_rewardAllocation).div(100)) {
            poolInfo[_poolId].rewardAllocation = rewardAllocation.mul(_rewardAllocation).div(100);
        }
    }
    function add(
        uint256 _rewardAllocation, 
        IERC20 _pairAddress, 
        IERC20 _otherToken
        ) external onlyOwner {
        require (_rewardAllocation <= 100, "Invalid allocation");
        uint256 _totalAllocation = rewardAllocation.mul(_rewardAllocation).div(100);
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            _totalAllocation = _totalAllocation.add(poolInfo[pid].rewardAllocation);
        }
        require (_totalAllocation <= rewardAllocation, "Allocation exceeded");
        poolInfo.push(PoolInfo({
            pairAddress: _pairAddress,
            otherToken: _otherToken,
            rewardAllocation: rewardAllocation.mul(_rewardAllocation).div(100),
            borrowedSupply: 0,
            totalSupply: 0,
            rewardPerTokenStored: 0
        }));
    }
    function disableSendToTreasury() external onlyOwner {
        require(!treasuryDisabled, "Already disabled");
        treasuryDisabled = true;
    }
    function sendToTreasury() external onlyOwner {
        require(!treasuryDisabled, "Invalid operation");
        treasury.transfer(address(this).balance);
    }
    function balanceOfPool(uint256 _poolId) external view returns (uint256, uint256) {
        require(_poolId < poolInfo.length, 'Invalid pool');
        PoolInfo storage pool = poolInfo[_poolId];
        uint256 otherTokenAmount = IERC20(pool.otherToken).balanceOf(address(pool.pairAddress));
        uint256 cktlTokenAmount = IERC20(farmToken).balanceOf(address(pool.pairAddress));
        return (otherTokenAmount, cktlTokenAmount);
    }
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    function burnedTokenAmount() external view returns (uint256) {
        return farmToken.balanceOf(BURN_ADDRESS);
    }
    function rewardPerToken(uint256 _poolId) public view returns (uint256) {
        require(_poolId < poolInfo.length, 'Invalid pool');
        PoolInfo storage pool = poolInfo[_poolId];
        if (pool.totalSupply == 0) {
            return pool.rewardPerTokenStored;
        }
        return pool.rewardPerTokenStored
        .add(
            lastRewardTimestamp()
            .sub(lastUpdateTimestamp)
            .mul(pool.rewardAllocation.mul(rewardRate).div(rewardAllocation))
            .mul(1e18)
            .div(pool.totalSupply)
        );
    }
    function lastRewardTimestamp() public view returns (uint256) {
        return Math.min(block.timestamp, halvingTimestamp);
    }
    function rewardEarned(uint256 _poolId, address account) public view returns (uint256) {
        return accountInfos[_poolId][account].balance.mul(
            rewardPerToken(_poolId).sub(accountInfos[_poolId][account].rewardPerTokenPaid)
        )
        .div(1e18)
        .add(accountInfos[_poolId][account].reward);
    }
    function tokenPrice(uint256 _poolId) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_poolId];
        uint256 ethAmount = IERC20(weth).balanceOf(address(pool.pairAddress));
        uint256 tokenAmount = IERC20(farmToken).balanceOf(address(pool.pairAddress));
        return tokenAmount > 0 ? ethAmount.mul(1e18).div(tokenAmount) : (uint256(1e18).div(4));
    }
    function accountInfosByIndex(uint256 _poolId, uint256 _index) 
        external view returns (
            uint256 index,uint256 balance,uint256 lastWithdrawTimestamp,
            uint256 lastStakedTimestamp,uint256 reward,uint256 rewardPerTokenPaid,
            uint256 lpEthReward,uint256 lpEthRewardPaid,uint256 lpCktlReward,
            uint256 lpCktlRewardPaid, address ethAddress) {
        require(_poolId < poolInfo.length, 'Invalid pool');
        ethAddress = accountInfosIndex[_poolId][_index];
        AccountInfo memory account = accountInfos[_poolId][ethAddress];
        return (account.index, account.balance, account.lastWithdrawTimestamp,
            account.lastStakedTimestamp, account.reward, account.rewardPerTokenPaid,
            account.lpEthReward, account.lpEthRewardPaid, account.lpCktlReward,
            account.lpCktlRewardPaid,ethAddress);
    }
    function accountInfosLength(uint256 _poolId) external view returns (uint256) {
        require(_poolId < poolInfo.length, 'Invalid pool');
        return accountInfosIndex[_poolId].length;
    }
    function setGoverningParameters(uint256[] memory _parameters) external onlyOwner {
        require(_parameters[0] >= 5 && _parameters[0] <= 50, "Invalid range");
        require(_parameters[1] >= 10 && _parameters[1] <= 50, "Invalid range");
        require(_parameters[2] >= 1 && _parameters[2] <= 5, "Invalid range");
        require(_parameters[3] >= 1 && _parameters[3] <= 5, "Invalid range");
        require(_parameters[4] >= 1 && _parameters[4] <= 5, "Invalid range");
        require(_parameters[5] >= 25 && _parameters[5] <= 95, "Invalid range");
        require(_parameters[6] >= 1 && _parameters[6] <= 5, "Invalid range");
        require(_parameters[7] >= 1 && _parameters[7] <= 5, "Invalid range");
        require(_parameters[8] >= 1 && _parameters[8] <= 5, "Invalid range");
        require(_parameters[9] >= 2 && _parameters[9] <= 10, "Invalid range");
        require(_parameters[2].add(_parameters[3]).add(_parameters[4]).add(_parameters[5])==100, 'Invalid claim fees');
        rewardHalvingPercent = _parameters[0];
        withdrawalLimitPercent = _parameters[1];
        claimBurnFee = _parameters[2];
        claimTreasuryFeePercent = _parameters[3];
        claimLPFeePercent = _parameters[4];
        claimLiquidBalancePercent = _parameters[5];
        unstakeBurnFeePercent = _parameters[6];
        unstakeTreasuryFeePercent = _parameters[7];
        unstakeLPFeePercent = _parameters[8];
        bloodyMaryExitFeePercent = _parameters[9];
        farmToken.setMaxSupply(_parameters[10]);
    }
}