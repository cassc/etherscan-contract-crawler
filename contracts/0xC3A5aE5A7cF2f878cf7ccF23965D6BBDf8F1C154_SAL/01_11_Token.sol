// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**

https://t.me/CryptoSailn

*/

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory}  from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair}     from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IERC20}             from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20}              from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable}            from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath}           from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SAL is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public maxSupply; // what the total supply can reach and not go beyond

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    bool private _swapping;

    address private _swapFeeReceiver;
    address private _swapFeeValidator;
    
    uint256 public maxTransactionAmount;
    uint256 public maxWallet;

    uint256 public swapTokensThreshold;
        
    bool public limitsInEffect = true;

    uint256 public totalFees;
    uint256 private _marketingFee;
    uint256 private _liquidityFee;
    uint256 private _validatorFee;
    
    uint256 private _tokensForMarketing;
    uint256 private _tokensForLiquidity;
    uint256 private _tokensForValidator;
    
    // staking vars
    uint256 public totalStaked;
    address public stakingToken;
    address public rewardToken;

    bool public autoAPREnabled = true;
    uint256 public apr;

    bool public stakingEnabled = false;
    uint256 public totalClaimed;

    struct Validator {
        uint256 creationTime;
        uint256 staked;
    }

    struct Staker {
        address staker;
        uint256 start;
        uint256 staked;
        uint256 earned;
    }

    struct ClaimHistory {
        uint256[] dates;
        uint256[] amounts;
    }

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;

    // store addresses that are automatic market maker pairs
    mapping (address => bool) private _automatedMarketMakerPairs;

    // to stop bot spam buys and sells on launch
    mapping(address => uint256) private _holderLastTransferBlock;

    // stake data
    mapping(address => mapping(uint256 => Staker)) private _stakers;
    mapping(address => ClaimHistory) private _claimHistory;
    Validator[] public validators;

    /**
     * @dev Throws if called by any account other than the _swapFeeReceiver
     */
    modifier teamOROwner() {
        require(_swapFeeReceiver == _msgSender() || owner() == _msgSender(), "Caller is not the _swapFeeReceiver address nor owner.");
        _;
    }

    modifier isStakingEnabled() {
        require(stakingEnabled, "Staking is not enabled.");
        _;
    }

    constructor() ERC20("Crypto Sailing", "SAL") payable {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        _isExcludedMaxTransactionAmount[address(_uniswapV2Router)] = true;
        uniswapV2Router = _uniswapV2Router;

        uint256 marketingFee = 0;
        uint256 liquidityFee = 0;
        uint256 validatorFee = 0;

        uint256 totalSupply = 5e8 * 10 ** decimals();
        maxSupply           = 1e9 * 10 ** decimals();

        maxTransactionAmount = totalSupply * 1 / 100;
        maxWallet = totalSupply * 1 / 100;
        swapTokensThreshold = totalSupply * 4 / 1000;
        
        _marketingFee = marketingFee;
        _liquidityFee = liquidityFee;
        _validatorFee = validatorFee;
        totalFees = _marketingFee + _liquidityFee + _validatorFee;

        _swapFeeReceiver = owner();
        _swapFeeValidator = owner();

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        
        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[address(0xdead)] = true;
        
        stakingToken = address(this);
        rewardToken = address(this);

        if (autoAPREnabled && totalSupply <= maxSupply) {
            apr = 100 * (maxSupply - totalSupply) / maxSupply;
        } else {
            apr = 50;
        }

        _mint(address(this), totalSupply.sub(1e8 * 10 ** decimals()));
        _mint(msg.sender, 1e8 * 10 ** decimals());
    }

    /**
    * @dev Once live, can never be switched off
    */
    function startTrading() external teamOROwner {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;
        _automatedMarketMakerPairs[address(uniswapV2Pair)] = true;

        _approve(address(this), address(uniswapV2Router), balanceOf(address(this)));
        uniswapV2Router.addLiquidityETH{value: address(this).balance} (
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    /**
    * @dev Remove limits after token is somewhat stable
    */
    function removeLimits() external teamOROwner {
        limitsInEffect = false;
    }

    /**
    * @dev Exclude from fee calculation
    */
    function excludeFromFees(address account, bool excluded) public teamOROwner {
        _isExcludedFromFees[account] = excluded;
    }
    
    /**
    * @dev Update token fees (max set to initial fee)
    */
    function updateFees(uint256 marketingFee, uint256 liquidityFee, uint256 validatorFee) external teamOROwner {
        _marketingFee = marketingFee;
        _liquidityFee = liquidityFee;
        _validatorFee = validatorFee;

        totalFees = _marketingFee + _liquidityFee + _validatorFee;

        require(totalFees <= 12, "Must keep fees at 12% or less");
    }

    /**
    * @dev Update wallets that receives fees and newly added LP
    */
    function updateFeeWallets(address newReceiverWallet, address newValidatorWallet) external teamOROwner {
        _swapFeeReceiver = newReceiverWallet;
        _swapFeeValidator = newValidatorWallet;
    }

    /**
    * @dev Very important function. 
    * Updates the threshold of how many tokens that must be in the contract calculation for fees to be taken
    */
    function updateSwapTokensThreshold(uint256 newThreshold) external teamOROwner returns (bool) {
          require(newThreshold >= totalSupply() * 1 / 100000, "Swap threshold cannot be lower than 0.001% total supply.");
          require(newThreshold <= totalSupply() * 5 / 1000, "Swap threshold cannot be higher than 0.5% total supply.");
          swapTokensThreshold = newThreshold;
          return true;
      }

    /**
    * @dev Check if an address is excluded from the fee calculation
    */
    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // all to secure a smooth launch
        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0xdead) &&
                !_swapping
            ) {
                if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                    require(_holderLastTransferBlock[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                    _holderLastTransferBlock[tx.origin] = block.number;
                }

                // on buy
                if (_automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "_transfer:: Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "_transfer:: Max wallet exceeded");
                }
                
                // on sell
                else if (_automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "_transfer:: Sell transfer amount exceeds the maxTransactionAmount.");
                }
                else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "_transfer:: Max wallet exceeded");
                }
            }
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensThreshold;
        if (
            canSwap &&
            !_swapping &&
            !_automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            _swapping = true;
            swapBack();
            _swapping = false;
        }

        bool takeFee = !_swapping;

        // if any addy belongs to _isExcludedFromFee or isn't a swap then remove the fee
        if (
            _isExcludedFromFees[from] || 
            _isExcludedFromFees[to] || 
            (!_automatedMarketMakerPairs[from] && !_automatedMarketMakerPairs[to])
        ) takeFee = false;
        
        uint256 fees = 0;
        if (takeFee) {
            fees = amount.mul(totalFees).div(100);
            _tokensForLiquidity += fees * _liquidityFee / totalFees;
            _tokensForValidator += fees * _validatorFee / totalFees;
            _tokensForMarketing += fees * _marketingFee / totalFees;
            
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _swapFeeReceiver,
            block.timestamp
        );
    }

    function swapBack() internal {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _tokensForLiquidity + _tokensForMarketing + _tokensForValidator;
        
        if (contractBalance == 0 || totalTokensToSwap == 0) return;
        if (contractBalance > swapTokensThreshold) contractBalance = swapTokensThreshold;
        
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * _tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(amountToSwapForETH);
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(_tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForValidator = ethBalance.mul(_tokensForValidator).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForValidator;
        
        _tokensForLiquidity = 0;
        _tokensForMarketing = 0;
        _tokensForValidator = 0;

        payable(_swapFeeReceiver).transfer(ethForMarketing);
        payable(_swapFeeValidator).transfer(ethForValidator);
                
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
        }
    }

    /**
    * @dev Transfer eth stuck in contract
    */
    function withdrawContractETH(address to, uint256 ethAmount) external teamOROwner {
        payable(to).transfer(ethAmount);
    }

    /**
    * @dev Transfer tokens stuck in contract
    */
    function withdrawContractToken(address to, uint256 tokenAmount, address tokenAddress) external teamOROwner {
        IERC20(tokenAddress).transfer(to, tokenAmount);
    }

    /**
    * @dev In case swap wont do it and sells/buys might be blocked
    */
    function forceSwap() external teamOROwner {
        _swapTokensForEth(balanceOf(address(this)));
    }

    /**
        *
        * @dev Staking part starts here
        *
    */

    /**
    * @dev Checks if holder is staking
    */
    function isStaking(address stakerAddr, uint256 validator) public view returns (bool) {
        return _stakers[stakerAddr][validator].staker == stakerAddr;
    }

    /**
    * @dev Returns how much staker is staking
    */
    function userStaked(address staker, uint256 validator) public view returns (uint256) {
        return _stakers[staker][validator].staked;
    }

    /**
    * @dev Returns how much staker has claimed over time
    */
    function userClaimHistory(address staker) public view returns (ClaimHistory memory) {
        return _claimHistory[staker];
    }

    /**
    * @dev Returns how much staker has earned
    */
    function userEarned(address staker, uint256 validator) public view returns (uint256) {
        uint256 currentlyEarned = _userEarned(staker, validator);
        uint256 previouslyEarned = _stakers[msg.sender][validator].earned;

        if (previouslyEarned > 0) return currentlyEarned.add(previouslyEarned);
        return currentlyEarned;
    }

    function _userEarned(address staker, uint256 validator) private view returns (uint256) {
        require(isStaking(staker, validator), "User is not staking.");

        uint256 staked = userStaked(staker, validator);
        uint256 stakersStartInSeconds = _stakers[staker][validator].start.div(1 seconds);
        uint256 blockTimestampInSeconds = block.timestamp.div(1 seconds);
        uint256 secondsStaked = blockTimestampInSeconds.sub(stakersStartInSeconds);

        uint256 earn = staked.mul(apr).div(100);
        uint256 rewardPerSec = earn.div(365).div(24).div(60).div(60);
        uint256 earned = rewardPerSec.mul(secondsStaked);

        return earned;
    }
 
    /**
    * @dev Stake tokens in validator
    */
    function stake(uint256 stakeAmount, uint256 validator) external isStakingEnabled {
        require(totalSupply() + totalStaked <= maxSupply, "There are no more rewards left to be claimed.");

        // Check user is registered as staker
        if (isStaking(msg.sender, validator)) {
            _stakers[msg.sender][validator].staked += stakeAmount;
            _stakers[msg.sender][validator].earned += _userEarned(msg.sender, validator);
            _stakers[msg.sender][validator].start = block.timestamp;
        } else {
            _stakers[msg.sender][validator] = Staker(msg.sender, block.timestamp, stakeAmount, 0);
        }

        validators[validator].staked += stakeAmount;
        totalStaked += stakeAmount;
        _burn(msg.sender, stakeAmount);
    }
    
    /**
    * @dev Claim earned tokens from stake in validator
    */
    function claim(uint256 validator) external isStakingEnabled {
        require(isStaking(msg.sender, validator), "You are not staking!?");
        require(totalSupply() + totalStaked <= maxSupply, "There are no more rewards left to be claimed.");

        uint256 earned = userEarned(msg.sender, validator);
        uint256 reward = totalSupply() + totalStaked + earned <= maxSupply ?  earned : maxSupply - totalSupply() - totalStaked;
        require(reward > 0, "There are no more rewards left to be claimed.");

        _claimHistory[msg.sender].dates.push(block.timestamp);
        _claimHistory[msg.sender].amounts.push(reward);
        totalClaimed += reward;

        _mint(msg.sender, reward);

        _stakers[msg.sender][validator].start = block.timestamp;
        _stakers[msg.sender][validator].earned = 0;

        if (autoAPREnabled) {
            apr = 100 * (maxSupply - totalSupply() - totalStaked) / maxSupply;
        }
    }

    /**
    * @dev Claim earned and staked tokens from validator
    */
    function unstake(uint256 validator) external {
        require(isStaking(msg.sender, validator), "You are not staking!?");

        uint256 earned = userEarned(msg.sender, validator);
        uint256 reward = 0;

        if (stakingEnabled && totalSupply() + totalStaked <= maxSupply) {
            reward = totalSupply() + totalStaked + earned <= maxSupply ?  earned : maxSupply - totalSupply() - totalStaked;
        }

        if (reward > 0) {
            _claimHistory[msg.sender].dates.push(block.timestamp);
            _claimHistory[msg.sender].amounts.push(reward);
            totalClaimed += reward;
        }

        _mint(msg.sender, _stakers[msg.sender][validator].staked.add(reward));

        validators[validator].staked -= _stakers[msg.sender][validator].staked;
        totalStaked -= _stakers[msg.sender][validator].staked;

        delete _stakers[msg.sender][validator];

        if (autoAPREnabled && totalSupply() + totalStaked <= maxSupply) {
            apr = 100 * (maxSupply - totalSupply() - totalStaked) / maxSupply;
        } else if (autoAPREnabled) {
            apr = 0;
        }
    }

    /**
    * @dev Creates validator 
    */
    function createValidator() external teamOROwner {
        Validator memory validator = Validator(block.timestamp, 0);
        validators.push(validator);
    }

    /**
    * @dev Returns amount of validators
    */
    function amountOfValidators() public view returns (uint256) {
        return validators.length;
    }

    /**
    * @dev Enables/disables staking
    */
    function setStakingState(bool onoff) external teamOROwner {
        stakingEnabled = onoff;
    }

    /**
    * @dev Update staking apr
    */
    function updateStakingAPR(uint256 newAPR, bool onoff) external teamOROwner {
        apr = newAPR;
        autoAPREnabled = onoff;
    }

    receive() external payable {}
}