/*
   _____ __  ______  ______     ___________   _____    _   ______________
  / ___// / / / __ \/ ____/    / ____/  _/ | / /   |  / | / / ____/ ____/
  \__ \/ / / / /_/ / /_       / /_   / //  |/ / /| | /  |/ / /   / __/   
 ___/ / /_/ / _, _/ __/  _   / __/ _/ // /|  / ___ |/ /|  / /___/ /___   
/____/\____/_/ |_/_/    (_) /_/   /___/_/ |_/_/  |_/_/ |_/\____/_____/  

Website: https://surf.finance
Created by Proof and sol_dev, with help from Zoma and Mr Fahrenheit
Audited by Aegis DAO and Sherlock Security

*/

pragma solidity ^0.6.12;

import './Ownable.sol';
import './SafeMath.sol';
import './SafeERC20.sol';
import './IERC20.sol';
import './IUniswapV2Router02.sol';
import './SURF.sol';
import './Tito.sol';

// The Whirlpool staking contract becomes active after the max supply it hit, and is where SURF-ETH LP token stakers will continue to receive dividends from other projects in the SURF ecosystem
contract Whirlpool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user
    struct UserInfo {
        uint256 staked; // How many SURF-ETH LP tokens the user has staked
        uint256 rewardDebt; // Reward debt. Works the same as in the Tito contract
        uint256 claimed; // Tracks the amount of SURF claimed by the user
    }

    // The SURF TOKEN!
    SURF public surf;
    // The Tito contract
    Tito public tito;
    // The SURF-ETH Uniswap LP token
    IERC20 public surfPool;
    // The Uniswap v2 Router
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // WETH
    IERC20 public weth;

    // Info of each user that stakes SURF-ETH LP tokens
    mapping (address => UserInfo) public userInfo;
    // The amount of SURF sent to this contract before it became active
    uint256 public initialSurfReward = 0;
    // 1% of the initialSurfReward will be rewarded to stakers per day for 100 days
    uint256 public initialSurfRewardPerDay;
    // How often the initial 1% payouts can be processed
    uint256 public constant INITIAL_PAYOUT_INTERVAL = 24 hours;
    // The unstaking fee that is used to increase locked liquidity and reward Whirlpool stakers (1 = 0.1%). Defaults to 10%
    uint256 public unstakingFee = 100;
    // The amount of SURF-ETH LP tokens kept by the unstaking fee that will be converted to SURF and distributed to stakers (1 = 0.1%). Defaults to 50%
    uint256 public unstakingFeeConvertToSurfAmount = 500;
    // When the first 1% payout can be processed (timestamp). It will be 24 hours after the Whirlpool contract is activated
    uint256 public startTime;
    // When the last 1% payout was processed (timestamp)
    uint256 public lastPayout;
    // The total amount of pending SURF available for stakers to claim
    uint256 public totalPendingSurf;
    // Accumulated SURFs per share, times 1e12.
    uint256 public accSurfPerShare;
    // The total amount of SURF-ETH LP tokens staked in the contract
    uint256 public totalStaked;
    // Becomes true once the 'activate' function called by the Tito contract when the max SURF supply is hit
    bool public active = false;

    event Stake(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 surfAmount);
    event Withdraw(address indexed user, uint256 amount);
    event SurfRewardAdded(address indexed user, uint256 surfReward);
    event EthRewardAdded(address indexed user, uint256 ethReward);

    constructor(SURF _surf, Tito _tito) public {
        tito = _tito;
        surf = _surf;
        surfPool = IERC20(tito.surfPoolAddress());
        weth = IERC20(uniswapRouter.WETH());
    }

    receive() external payable {
        emit EthRewardAdded(msg.sender, msg.value);
    }

    function activate() public {
        require(active != true, "already active");
        require(surf.maxSupplyHit() == true, "too soon");

        active = true;

        // Now that the Whirlpool staking contract is active, reward 1% of the initialSurfReward per day for 100 days
        startTime = block.timestamp + INITIAL_PAYOUT_INTERVAL; // The first payout can be processed 24 hours after activation
        lastPayout = startTime;
        initialSurfRewardPerDay = initialSurfReward.div(100);
    }

    // The _transfer function in the SURF contract calls this to let the Whirlpool contract know that it received the specified amount of SURF to be distributed to stakers 
    function addSurfReward(address _from, uint256 _amount) public {
        require(msg.sender == address(surf), "not surf contract");
        require(tito.surfPoolActive() == true, "no surf pool");
        require(_amount > 0, "no surf");

        if (active != true || totalStaked == 0) {
            initialSurfReward = initialSurfReward.add(_amount);
        } else {
            totalPendingSurf = totalPendingSurf.add(_amount);
            accSurfPerShare = accSurfPerShare.add(_amount.mul(1e12).div(totalStaked));
        }

        emit SurfRewardAdded(_from, _amount);
    }

    // Allows external sources to add ETH to the contract which is used to buy and then distribute SURF to stakers
    function addEthReward() public payable {
        require(tito.surfPoolActive() == true, "no surf pool");

        // We will purchase SURF with all of the ETH in the contract in case some was sent directly to the contract instead of using addEthReward
        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "no eth");

        // Use the ETH to buyback SURF which will be distributed to stakers
        _buySurf(ethBalance);

        // The _transfer function in the SURF contract calls the Whirlpool contract's updateSurfReward function so we don't need to update the balances after buying the SURF
        emit EthRewardAdded(msg.sender, msg.value);
    }

    // Internal function to buy back SURF with the amount of ETH specified
    function _buySurf(uint256 _amount) internal {
        uint256 deadline = block.timestamp + 5 minutes;
        address[] memory surfPath = new address[](2);
        surfPath[0] = address(weth);
        surfPath[1] = address(surf);
        uniswapRouter.swapExactETHForTokens{value: _amount}(0, surfPath, address(this), deadline);
    }

    // Handles paying out the initialSurfReward over 100 days
    function _processInitialPayouts() internal {
        if (active != true || block.timestamp < startTime || initialSurfReward == 0 || totalStaked == 0) return;

        // How many days since last payout?
        uint256 daysSinceLastPayout = (block.timestamp - lastPayout) / INITIAL_PAYOUT_INTERVAL;

        // If less than 1, don't do anything
        if (daysSinceLastPayout == 0) return;

        // Work out how many payouts have been missed
        uint256 nextPayoutNumber = (block.timestamp - startTime) / INITIAL_PAYOUT_INTERVAL;
        uint256 previousPayoutNumber = nextPayoutNumber - daysSinceLastPayout;

        // Calculate how much additional reward we have to hand out
        uint256 surfReward = rewardAtPayout(nextPayoutNumber) - rewardAtPayout(previousPayoutNumber);
        if (surfReward > initialSurfReward) surfReward = initialSurfReward;
        initialSurfReward = initialSurfReward.sub(surfReward);

        // Payout the surfReward to the stakers
        totalPendingSurf = totalPendingSurf.add(surfReward);
        accSurfPerShare = accSurfPerShare.add(surfReward.mul(1e12).div(totalStaked));

        // Update lastPayout time
        lastPayout += (daysSinceLastPayout * INITIAL_PAYOUT_INTERVAL);
    }

    // Handles claiming the user's pending SURF rewards
    function _claimReward(address _user) internal {
        UserInfo storage user = userInfo[_user];
        if (user.staked > 0) {
            uint256 pendingSurfReward = user.staked.mul(accSurfPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingSurfReward > 0) {
                totalPendingSurf = totalPendingSurf.sub(pendingSurfReward);
                user.claimed += pendingSurfReward;
                _safeSurfTransfer(_user, pendingSurfReward);
                emit Claim(_user, pendingSurfReward);
            }
        }
    }

    // Stake SURF-ETH LP tokens to get rewarded with more SURF
    function stake(uint256 _amount) public {
        stakeFor(msg.sender, _amount);
    }

    // Stake SURF-ETH LP tokens on behalf of another address
    function stakeFor(address _user, uint256 _amount) public {
        require(active == true, "not active");
        require(_amount > 0, "stake something");

        _processInitialPayouts();

        // Claim any pending SURF
        _claimReward(_user);

        surfPool.safeTransferFrom(address(msg.sender), address(this), _amount);

        UserInfo storage user = userInfo[_user];
        totalStaked = totalStaked.add(_amount);
        user.staked = user.staked.add(_amount);
        user.rewardDebt = user.staked.mul(accSurfPerShare).div(1e12);
        emit Stake(_user, _amount);
    }

    // Claim earned SURF. Claiming won't work until active == true
    function claim() public {
        require(active == true, "not active");
        UserInfo storage user = userInfo[msg.sender];
        require(user.staked > 0, "no stake");
        
        _processInitialPayouts();

        // Claim any pending SURF
        _claimReward(msg.sender);

        user.rewardDebt = user.staked.mul(accSurfPerShare).div(1e12);
    }

    // Unstake and withdraw SURF-ETH LP tokens and any pending SURF rewards. There is a 10% unstaking fee, meaning the user will only receive 90% of their LP tokens back.
    // For the LP tokens kept by the unstaking fee, 50% will get locked forever in the SURF contract, and 50% will get converted to SURF and distributed to stakers.
    function withdraw(uint256 _amount) public {
        require(active == true, "not active");
        UserInfo storage user = userInfo[msg.sender];
        require(_amount > 0 && user.staked >= _amount, "withdraw: not good");
        
        _processInitialPayouts();

        uint256 unstakingFeeAmount = _amount.mul(unstakingFee).div(1000);
        uint256 remainingUserAmount = _amount.sub(unstakingFeeAmount);

        // Half of the LP tokens kept by the unstaking fee will be locked forever in the SURF contract, the other half will be converted to SURF and distributed to stakers
        uint256 lpTokensToConvertToSurf = unstakingFeeAmount.mul(unstakingFeeConvertToSurfAmount).div(1000);
        uint256 lpTokensToLock = unstakingFeeAmount.sub(lpTokensToConvertToSurf);

        // Remove the liquidity from the Uniswap SURF-ETH pool and buy SURF with the ETH received
        // The _transfer function in the SURF.sol contract automatically calls whirlpool.addSurfReward() so we don't have to in this function
        if (lpTokensToConvertToSurf > 0) {
            surfPool.safeApprove(address(uniswapRouter), lpTokensToConvertToSurf);
            uniswapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(address(surf), lpTokensToConvertToSurf, 0, 0, address(this), block.timestamp + 5 minutes);
            addEthReward();
        }

        // Permanently lock the LP tokens in the SURF contract
        if (lpTokensToLock > 0) surfPool.transfer(address(surf), lpTokensToLock);

        // Claim any pending SURF
        _claimReward(msg.sender);

        totalStaked = totalStaked.sub(_amount);
        user.staked = user.staked.sub(_amount);
        surfPool.safeTransfer(address(msg.sender), remainingUserAmount);
        user.rewardDebt = user.staked.mul(accSurfPerShare).div(1e12);
        emit Withdraw(msg.sender, remainingUserAmount);
    }

    // Internal function to safely transfer SURF in case there is a rounding error
    function _safeSurfTransfer(address _to, uint256 _amount) internal {
        uint256 surfBal = surf.balanceOf(address(this));
        if (_amount > surfBal) {
            surf.transfer(_to, surfBal);
        } else {
            surf.transfer(_to, _amount);
        }
    }

    // Sets the unstaking fee. Can't be higher than 50%. _convertToSurfAmount is the % of the LP tokens from the unstaking fee that will be converted to SURF and distributed to stakers.
    // unstakingFee - unstakingFeeConvertToSurfAmount = The % of the LP tokens from the unstaking fee that will be permanently locked in the SURF contract
    function setUnstakingFee(uint256 _unstakingFee, uint256 _convertToSurfAmount) public onlyOwner {
        require(_unstakingFee <= 500, "over 50%");
        require(_convertToSurfAmount <= 1000, "bad amount");
        unstakingFee = _unstakingFee;
        unstakingFeeConvertToSurfAmount = _convertToSurfAmount;
    }

    // Function to recover ERC20 tokens accidentally sent to the contract.
    // SURF and SURF-ETH LP tokens (the only 2 ERC2O's that should be in this contract) can't be withdrawn this way.
    function recoverERC20(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(surf) && _tokenAddress != address(surfPool));
        IERC20 token = IERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(msg.sender, tokenBalance);
    }

    function payoutNumber() public view returns (uint256) {
        if (block.timestamp < startTime) return 0;

        uint256 payout = (block.timestamp - startTime).div(INITIAL_PAYOUT_INTERVAL);
        if (payout > 100) return 100;
        else return payout;
    }

    function timeUntilNextPayout() public view returns (uint256) {
        if (initialSurfReward == 0) return 0;
        else {
            uint256 payout = payoutNumber();
            uint256 nextPayout = startTime.add((payout + 1).mul(INITIAL_PAYOUT_INTERVAL));
            return nextPayout - block.timestamp;
        }
    }

    function rewardAtPayout(uint256 _payoutNumber) public view returns (uint256) {
        if (_payoutNumber == 0) return 0;
        return initialSurfRewardPerDay * _payoutNumber;
    }

    function getAllInfoFor(address _user) external view returns (bool isActive, uint256[12] memory info) {
        isActive = active;
        info[0] = surf.balanceOf(address(this));
        info[1] = initialSurfReward;
        info[2] = totalPendingSurf;
        info[3] = startTime;
        info[4] = lastPayout;
        info[5] = totalStaked;
        info[6] = surf.balanceOf(_user);
        if (tito.surfPoolActive()) {
            info[7] = surfPool.balanceOf(_user);
            info[8] = surfPool.allowance(_user, address(this));
        }
        info[9] = userInfo[_user].staked;
        info[10] = userInfo[_user].staked.mul(accSurfPerShare).div(1e12).sub(userInfo[_user].rewardDebt);
        info[11] = userInfo[_user].claimed;
    }

}