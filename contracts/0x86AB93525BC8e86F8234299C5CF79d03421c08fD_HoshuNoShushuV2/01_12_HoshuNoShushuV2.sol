// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract HoshuNoShushuV2 is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    struct Staker {
        uint256 round;
        uint256 roundETH;
        uint256 tokens;
        uint256 remainder;
        uint256 remainderETH;
        bool active;
    }

    mapping(address => Staker) public stakers;
    address[] public allStakers;

    uint256 public stakingFee;
    uint256 public unstakingFee;
    uint256 public multiplier;
    uint256 public staked;

    // dividends
    uint256 public round;
    uint256 public roundETH;

    // dividends KATANA
    uint256 public rewards;
    uint256 public dividends;
    uint256 public remainder;

    // dividends ETH
    uint256 public rewardsETH;
    uint256 public dividendsETH;
    uint256 public remainderETH;

    // payout store
    mapping(uint256 => uint256) public payouts;
    mapping(uint256 => uint256) public payoutsETH;

    // flags
    bool public claimable;
    bool public stakeable;
    bool public unstakeable;
    bool public restakeable;

    // staking token
    address public token;
    address public pair;
    IUniswapV2Router02 public router;

    // some events
    event Payout(address sender, uint256 amount, uint256 round);
    event PayoutETH(address sender, uint256 amountETH, uint256 round);
    event Staked(address sender, uint256 amount, uint256 fee);
    event Restaked(address sender, uint256 amount, uint256 fee);
    event Unstaked(address sender, uint256 amount, uint256 fee);
    event EmergencyUnstaked(address sender, uint256 amount);
    event Claimed(address sender, uint256 amount);
    event ClaimedETH(address sender, uint256 amount);

    // V2
    uint256 public rewardsETHCounter;

    function initialize() public payable initializer {
        // V2
        rewardsETHCounter = 0;

        // V1
        // stakingFee = 500;
        // unstakingFee = 500;
        // multiplier = 10**12;
        // claimable = true;
        // stakeable = true;
        // unstakeable = true;
        // restakeable = true;
        // round = 1;
        // roundETH = 1;
        // token = _token;
        // router = IUniswapV2Router02(_router);
        // pair = IUniswapV2Factory(router.factory()).getPair(
        //     _token,
        //     router.WETH()
        // );
        // require(pair != address(0), "no pair available");
        // __ReentrancyGuard_init();
        // __Pausable_init();
        // __Ownable_init();
        // _pause();
    }

    // -- receiving eth ---
    receive() external payable {}

    fallback() external payable {}

    // --- staking ---
    function stake(uint256 amount) public whenNotPaused nonReentrant {
        require(stakeable, "staking currently not possible");
        require(amount > 0, "not enough tokens");
        require(
            IERC20(token).transferFrom(_msgSender(), address(this), amount),
            "failed transfer while staking"
        );

        if (!isStaker(_msgSender())) {
            stakers[_msgSender()].active = true;
            allStakers.push(_msgSender());
        }

        // process fees
        uint256 stakeTokens = amount;
        uint256 feeTokens = 0;
        if (staked > 0) {
            (stakeTokens, feeTokens) = takeFeeOnStake(amount);
            processFeeOnStake(feeTokens);
        }

        uint256 _rewards = pendingReward(_msgSender());
        uint256 _rewardsETH = pendingRewardETH(_msgSender());

        stakers[_msgSender()].remainder += _rewards;
        stakers[_msgSender()].remainderETH += _rewardsETH;
        stakers[_msgSender()].round = round;
        stakers[_msgSender()].roundETH = roundETH;
        stakers[_msgSender()].tokens += stakeTokens;
        staked += stakeTokens;

        emit Staked(_msgSender(), stakeTokens, feeTokens);
    }

    function unstake(uint256 amount) external whenNotPaused nonReentrant {
        require(stakers[_msgSender()].active, "not allowed to unstake");
        require(
            stakers[_msgSender()].tokens >= amount && amount > 0,
            "wrong unstake amount"
        );

        payoutEthRewards(_msgSender());

        uint256 _rewards = pendingReward(_msgSender());

        stakers[_msgSender()].remainder += _rewards;
        stakers[_msgSender()].round = round;
        stakers[_msgSender()].tokens -= amount;
        staked -= amount;

        (uint256 unstakeTokens, uint256 feeTokens) = takeFeeOnUnstake(amount);

        require(
            IERC20(token).transfer(_msgSender(), unstakeTokens),
            "failed transfer while unstaking"
        );

        processFeeOnUnstake(feeTokens);

        claim();

        emit Unstaked(_msgSender(), unstakeTokens, feeTokens);
    }

    function emergencyUnstake() external whenPaused nonReentrant {
        require(stakers[_msgSender()].active, "not allowed to unstake");
        require(stakers[_msgSender()].tokens > 0, "wrong unstake amount");
        uint256 unstakeTokens = stakers[_msgSender()].tokens;
        stakers[_msgSender()].remainder = 0;
        stakers[_msgSender()].round = 0;
        stakers[_msgSender()].tokens = 0;
        staked -= unstakeTokens;
        require(
            IERC20(token).transfer(_msgSender(), unstakeTokens),
            "failed transfer while unstaking"
        );
        emit EmergencyUnstaked(_msgSender(), unstakeTokens);
    }

    // --- restake --
    function restake() external whenNotPaused nonReentrant {
        require(restakeable, "restaking currently not possible");
        require(stakers[_msgSender()].active, "not allowed to restake");
        require(stakers[_msgSender()].tokens > 0, "not enough tokens to claim");

        uint256 _rewards = pendingReward(_msgSender());
        _rewards += stakers[_msgSender()].remainder;
        if (_rewards > 0) {
            (uint256 restakeTokens, uint256 feeTokens) = takeFeeOnUnstake(
                _rewards
            );
            processFeeOnUnstake(feeTokens);
            payoutEthRewards(_msgSender());
            stakers[_msgSender()].remainder = 0;
            stakers[_msgSender()].round = round;
            stakers[_msgSender()].tokens += restakeTokens;
            staked += restakeTokens;
            rewards += restakeTokens;
            emit Restaked(_msgSender(), restakeTokens, feeTokens);
        }
    }

    function claim() public whenNotPaused {
        uint256 _rewards = pendingReward(_msgSender());
        _rewards += stakers[_msgSender()].remainder;
        if (_rewards > 0) {
            stakers[_msgSender()].remainder = 0;

            require(
                IERC20(token).transfer(_msgSender(), _rewards),
                "failed while claiming rewards"
            );

            rewards += _rewards;

            stakers[_msgSender()].round = round;
            emit Claimed(_msgSender(), _rewards);
        }
    }

    function claimETH() external whenNotPaused {
        require(claimable, "claiming currently not possible");
        require(stakers[_msgSender()].active, "not allowed to claim");
        require(stakers[_msgSender()].tokens > 0, "not enough tokens to claim");
        uint256 _rewards = payoutEthRewards(_msgSender());
        emit ClaimedETH(_msgSender(), _rewards);
    }

    // --- fees ---
    function takeFeeOnStake(uint256 amount)
        public
        view
        returns (uint256 updatedAmount, uint256 fee)
    {
        fee = onePercent(amount).mul(stakingFee).div(100);
        updatedAmount = amount.sub(fee);
    }

    function takeFeeOnUnstake(uint256 amount)
        public
        view
        returns (uint256 updatedAmount, uint256 fee)
    {
        fee = onePercent(amount).mul(unstakingFee).div(100);
        updatedAmount = amount.sub(fee);
    }

    function processFeeOnStake(uint256 amount) private {
        updateDividend(amount);
    }

    function processFeeOnUnstake(uint256 amount) private {
        if (amount > 0) {
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = router.WETH();
            IERC20(token).approve(address(router), amount);
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp
            );
            sync();
        }
    }

    // -- rewards --
    function updateDividend(uint256 amount) private {
        uint256 available = amount.mul(multiplier).add(remainder);
        uint256 dividendPerToken = available.div(staked);
        remainder = available.mod(staked);
        dividends = dividends.add(dividendPerToken);
        payouts[round] = payouts[round - 1].add(dividendPerToken);
        emit Payout(_msgSender(), available, round - 1);
        round++;
    }

    function injectRewards(uint256 amount) public whenNotPaused {
        require(
            IERC20(token).transferFrom(_msgSender(), address(this), amount),
            "not enough tokens"
        );
        if (staked > 0) updateDividend(amount);
    }

    function pendingReward(address addr) internal returns (uint256 _reward) {
        if (stakers[addr].tokens > 0 && stakers[addr].round > 0) {
            _reward =
                ((dividends - payouts[stakers[addr].round - 1]) *
                    stakers[addr].tokens) /
                multiplier;
            stakers[addr].remainder +=
                ((dividends - payouts[stakers[addr].round - 1]) *
                    stakers[addr].tokens) %
                multiplier;
        }
    }

    function pendingRewardEstimation(address addr)
        public
        view
        returns (uint256 _reward)
    {
        uint256 _stake = stakers[addr].tokens;
        if (_stake > 0) {
            uint256 _payout = payouts[stakers[addr].round - 1];
            _reward = ((dividends.sub(_payout)).mul(_stake)).div(multiplier);
            _reward += ((dividends.sub(_payout)).mul(_stake)) % multiplier;
            _reward += stakers[addr].remainder;
        }
    }

    // --- sync function called by ETH spending contract
    function sync() public whenNotPaused {
        uint256 _rewards = address(this).balance - rewardsETH;
        if (_rewards > 0 && staked > 0) {
            uint256 availableETH = _rewards.mul(multiplier).add(remainderETH);
            uint256 dividendPerTokenETH = availableETH.div(staked);
            rewardsETH += _rewards;
            remainderETH = availableETH.mod(staked);
            dividendsETH = dividendsETH.add(dividendPerTokenETH);
            payoutsETH[roundETH] = payoutsETH[roundETH - 1].add(
                dividendPerTokenETH
            );
            emit Payout(_msgSender(), availableETH, roundETH - 1);
            roundETH++;
        }
        if (staked == 0) {
            rewardsETH = 0;
        }
    }

    // --- rewards ETH
    function payoutEthRewards(address addr) public returns (uint256) {
        uint256 _rewardsETH = pendingRewardETH(addr) +
            stakers[addr].remainderETH;
        if (_rewardsETH > 0) {
            stakers[addr].remainderETH = 0;
            stakers[addr].roundETH = roundETH;
            if (_rewardsETH < rewardsETH) {
                rewardsETH -= _rewardsETH;
            } else {
                _rewardsETH = rewardsETH;
                rewardsETH = 0;
            }
            rewardsETHCounter += _rewardsETH;
            payable(addr).transfer(_rewardsETH);
            emit PayoutETH(addr, _rewardsETH, roundETH);
        }
        return _rewardsETH;
    }

    function pendingRewardETH(address addr) internal returns (uint256 _reward) {
        uint256 _stake = stakers[addr].tokens;
        if (_stake > 0 && stakers[addr].roundETH > 0) {
            uint256 _payout = payoutsETH[stakers[addr].roundETH - 1];
            _reward += ((dividendsETH - _payout) * _stake) / multiplier;
            stakers[addr].remainderETH +=
                ((dividendsETH - _payout) * _stake) %
                multiplier;
        }
    }

    function pendingRewardEstimationETH(address addr)
        external
        view
        returns (uint256 _reward)
    {
        uint256 _stake = stakers[addr].tokens;
        if (_stake > 0 && stakers[addr].roundETH > 0) {
            uint256 _payout = payoutsETH[stakers[addr].roundETH - 1];
            _reward += ((dividendsETH - _payout) * _stake) / multiplier;
            _reward += ((dividendsETH - _payout) * _stake) % multiplier;
            _reward += stakers[addr].remainderETH;
        }
    }

    function onePercent(uint256 _tokens) private pure returns (uint256) {
        uint256 roundValue = ((_tokens + 100 - 1) / 100) * 100;
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }

    // --- house keeping ---
    // it's very unlikely that this will ever be needed
    function claimDust() external onlyOwner {
        require(staked == 0, "tokens in stake");
        require(
            IERC20(token).balanceOf(address(this)) > 0,
            "no tokens available"
        );
        require(
            IERC20(token).transfer(
                owner(),
                IERC20(token).balanceOf(address(this))
            )
        );
    }

    // it's very unlikely that this will ever be needed
    function claimDustETH() external onlyOwner {
        require(staked == 0, "tokens in stake");
        require(address(this).balance > 0, "no eth available");
        rewardsETH = 0;
        payable(owner()).transfer(address(this).balance);
    }

    // --- checks ---
    function isStaker(address addr) public view returns (bool) {
        return stakers[addr].active;
    }

    // --- data ---
    function getStake(address addr) public view returns (uint256) {
        return stakers[addr].tokens;
    }

    function getStakeWithRewards(address addr) public view returns (uint256) {
        return stakers[addr].tokens.add(pendingRewardEstimation(addr));
    }

    function getInfo()
        public
        view
        returns (
            address stakedToken,
            uint256 totalStaked,
            uint256 totalStakers,
            uint256 currentRound,
            uint256 totalPendingRewards,
            uint256 totalPendingRewardsETH,
            uint256 totalRewards,
            uint256 totalRewardsETH
        )
    {
        stakedToken = token;
        totalStaked = staked;
        totalStakers = allStakers.length;
        currentRound = round;
        if (IERC20(token).balanceOf(address(this)) > staked) {
            totalPendingRewards = IERC20(token).balanceOf(address(this)).sub(
                staked
            );
        }
        if (address(this).balance > rewardsETH) {
            totalPendingRewardsETH = address(this).balance.sub(rewardsETH);
        }
        totalRewardsETH = rewardsETHCounter;
        totalRewards = rewards;
    }

    // --- settings ---
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function enableClaming() internal {
        claimable = true;
    }

    function disableClaming() internal {
        claimable = false;
    }

    function enableStaking() internal {
        stakeable = true;
    }

    function disableStaking() internal {
        stakeable = false;
    }

    function enableRestaking() internal {
        restakeable = true;
    }

    function disableRestaking() internal {
        restakeable = false;
    }
}