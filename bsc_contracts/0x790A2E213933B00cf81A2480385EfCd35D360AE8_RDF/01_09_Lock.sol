//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./DividendDistributor.sol";

contract RDF is IERC20, Ownable {
    using SafeMath for uint256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address public REWARD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    string constant _name = "Royalty Diplomat Finance";
    string constant _symbol = "$RDF";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1000000000 * (10**_decimals);

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isDividendExempt;
    // allowed users to do transactions before trading enable
    mapping(address => bool) isAuthorized;

    // buy fees
    uint256 public buyRewardFee = 7;
    uint256 public buyDevFee = 2;
    uint256 public buyLiquidityFee = 1;
    uint256 public buyBurnFee = 1;
    uint256 public buyJackpotFee = 1;
    uint256 public buyTotalFees = 12;
    // sell fees
    uint256 public sellRewardFee = 7;
    uint256 public sellDevFee = 2;
    uint256 public sellLiquidityFee = 1;
    uint256 public sellBurnFee = 1;
    uint256 public sellJackpotFee = 1;
    uint256 public sellTotalFees = 12;

    address public devFeeReceiver;

    // swap percentage
    uint256 public rewardSwap = 7;
    uint256 public devSwap = 2;
    uint256 public liquiditySwap = 1;
    uint256 public jackpotSwap = 1;
    uint256 public totalSwap = 11;

    IUniswapV2Router02 public router;
    address public pair;

    bool public tradingOpen = false;

    DividendDistributor public dividendTracker;

    uint256 distributorGas = 500000;

    /** Reward Biggest Buyer **/
    bool public isRewardBiggestBuyer = true;
    uint256 public biggestBuyerPeriod = 48 hours;
    uint256 public launchTime = block.timestamp;
    uint256 public totalBiggestBuyerPaid;
    mapping(uint256 => address) public biggestBuyer;
    mapping(uint256 => uint256) public biggestBuyerAmount;
    mapping(uint256 => uint256) public biggestBuyerPaid;

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event ChangeRewardTracker(address token);
    event IncludeInReward(address holder);
    event PayBiggestBuyer(
        address indexed account,
        uint256 indexed period,
        uint256 amount
    );

    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply * 2) / 10000; // 0.01% of supply

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = type(uint256).max;

        dividendTracker = new DividendDistributor(REWARD);

        isFeeExempt[msg.sender] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        isAuthorized[msg.sender] = true;

        devFeeReceiver = 0x05f3Ed48954e7674648C97087aA3BfEeaacdE5cE;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // tracker dashboard functions
    function getHolderDetails(address holder)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getHolderDetails(holder);
    }

    function getLastProcessedIndex() public view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfTokenHolders() public view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function totalDistributedRewards() public view returns (uint256) {
        return dividendTracker.totalDistributedRewards();
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (!isAuthorized[sender]) {
            require(tradingOpen, "Trading not open yet");
        }

        if (shouldSwapBack()) {
            swapBackInBnb();
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, amount, recipient)
            : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        // Dividend tracker
        if (!isDividendExempt[sender]) {
            try dividendTracker.setShare(sender, _balances[sender]) {} catch {}
        }

        if (!isDividendExempt[recipient]) {
            try
                dividendTracker.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        try dividendTracker.process(distributorGas) {} catch {}

        if (isRewardBiggestBuyer) {
            uint256 _periodAfterLaunch = getPeriod();

            if (sender == pair && !isContract(recipient)) {
                if (amount > biggestBuyerAmount[_periodAfterLaunch]) {
                    biggestBuyer[_periodAfterLaunch] = recipient;
                    biggestBuyerAmount[_periodAfterLaunch] = amount;
                }
            }

            _checkAndPayBiggestBuyer(_periodAfterLaunch);
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender, address to)
        internal
        view
        returns (bool)
    {
        if (isFeeExempt[sender] || isFeeExempt[to]) {
            return false;
        } else {
            return true;
        }
    }

    function takeFee(
        address sender,
        uint256 amount,
        address to
    ) internal returns (uint256) {
        uint256 feeAmount = 0;
        uint256 burnAmount = 0;

        if (to == pair) {
            feeAmount = amount.mul(sellTotalFees).div(100);

            if (sellBurnFee > 0)
                burnAmount = feeAmount.mul(sellBurnFee).div(sellTotalFees);
        } else {
            feeAmount = amount.mul(buyTotalFees).div(100);
            if (buyBurnFee > 0)
                burnAmount = feeAmount.mul(buyBurnFee).div(buyTotalFees);
        }

        if (burnAmount > 0) {
            _balances[DEAD] = _balances[DEAD].add(burnAmount);
            emit Transfer(sender, DEAD, burnAmount);
        }

        _balances[address(this)] = _balances[address(this)].add(
            feeAmount.sub(burnAmount)
        );
        emit Transfer(sender, address(this), feeAmount.sub(burnAmount));

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            tradingOpen &&
            _balances[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer((amountBNB * amountPercentage) / 100);
    }

    function getBep20Tokens(address _tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        require(
            _tokenAddress != address(this),
            "You can not withdraw native tokens"
        );
        require(
            IERC20(_tokenAddress).balanceOf(address(this)) >= amount,
            "No Enough Tokens"
        );
        IERC20(_tokenAddress).transfer(msg.sender, amount);
    }

    function updateBuyFees(
        uint256 reward,
        uint256 dev,
        uint256 liquidity,
        uint256 burn,
        uint256 jackpot
    ) public onlyOwner {
        buyRewardFee = reward;
        buyDevFee = dev;
        buyLiquidityFee = liquidity;
        buyBurnFee = burn;
        buyJackpotFee = jackpot;

        buyTotalFees = reward.add(dev).add(liquidity).add(burn).add(jackpot);

        require(
            buyTotalFees.add(sellTotalFees) <= 25,
            "Fees can not greater than 25%"
        );
    }

    function updateSellFees(
        uint256 reward,
        uint256 dev,
        uint256 liquidity,
        uint256 burn,
        uint256 jackpot
    ) public onlyOwner {
        sellRewardFee = reward;
        sellDevFee = dev;
        sellLiquidityFee = liquidity;
        sellBurnFee = burn;
        sellJackpotFee = jackpot;

        sellTotalFees = reward.add(dev).add(liquidity).add(burn).add(jackpot);

        require(
            buyTotalFees.add(sellTotalFees) <= 25,
            "Fees can not greater than 25%"
        );
    }

    // update swap percentages
    function updateSwapPercentages(
        uint256 reward,
        uint256 dev,
        uint256 liquidity,
        uint256 jackpot
    ) public onlyOwner {
        rewardSwap = reward;
        devSwap = dev;
        liquiditySwap = liquidity;
        jackpotSwap = jackpot;

        totalSwap = reward.add(dev).add(liquidity).add(jackpot);
    }

    // switch Trading
    function enableTrading() public onlyOwner {
        tradingOpen = true;
    }

    function whitelistPreSale(address _preSale) public onlyOwner {
        isFeeExempt[_preSale] = true;
        isDividendExempt[_preSale] = true;
        isAuthorized[_preSale] = true;
    }

    // manual claim for the greedy humans
    function ___claimRewards() public {
        dividendTracker.claimDividendTo(msg.sender);
    }

    // manually clear the queue
    function claimProcess() public {
        try dividendTracker.process(distributorGas) {} catch {}
    }

    function isRewardExclude(address _wallet) public view returns (bool) {
        return isDividendExempt[_wallet];
    }

    function isFeeExclude(address _wallet) public view returns (bool) {
        return isFeeExempt[_wallet];
    }

    function swapBackInBnb() internal swapping {
        uint256 contractTokenBalance = _balances[address(this)];
        uint256 tokensToLiquidity = contractTokenBalance.mul(liquiditySwap).div(
            totalSwap
        );
        uint256 tokensToSwapFee = totalSwap.sub(liquiditySwap);
        uint256 tokensToSwap = contractTokenBalance.sub(tokensToLiquidity);

        if (tokensToSwap > 0) {
            swapTokensForTokens(tokensToSwap, REWARD);

            uint256 swappedBusdBalance = IERC20(REWARD).balanceOf(
                address(this)
            );

            uint256 tokensToReward = swappedBusdBalance.mul(rewardSwap).div(
                tokensToSwapFee
            );

            uint256 tokensToDev = swappedBusdBalance.mul(devSwap).div(
                tokensToSwapFee
            );
            if (tokensToReward > 0) {
                IERC20(REWARD).transfer(
                    address(dividendTracker),
                    tokensToReward
                );
                try dividendTracker.deposit(tokensToReward) {} catch {}
            }

            if (tokensToDev > 0)
                IERC20(REWARD).transfer(devFeeReceiver, tokensToDev);
        }

        if (tokensToLiquidity > 0) {
            // add liquidity
            swapAndLiquify(tokensToLiquidity);
        }
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit AutoLiquify(newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokensForTokens(uint256 tokenAmount, address tokenToSwap)
        private
    {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WETH();
        path[2] = tokenToSwap;
        _approve(address(this), address(router), tokenAmount);
        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of tokens
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(DEAD),
            block.timestamp
        );
    }

    function setIsDividendExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            dividendTracker.setShare(holder, 0);
        } else {
            dividendTracker.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function addAuthorizedWallets(address holder, bool exempt)
        external
        onlyOwner
    {
        isAuthorized[holder] = exempt;
    }

    function setDevWallet(address _wallet) external onlyOwner {
        devFeeReceiver = _wallet;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        onlyOwner
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        dividendTracker.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getPeriod() public view returns (uint256) {
        uint256 secondsSinceLaunch = block.timestamp - launchTime;
        return 1 + (secondsSinceLaunch / biggestBuyerPeriod);
    }

    function changeBiigestBuyerTime(uint256 time) external onlyOwner {
        biggestBuyerPeriod = time;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function payBiggestBuyerOutside(uint256 _hour) external onlyOwner {
        _checkAndPayBiggestBuyer(_hour);
    }

    function _checkAndPayBiggestBuyer(uint256 _currentPeriod) private {
        uint256 _prevPeriod = _currentPeriod - 1;
        if (
            _currentPeriod > 1 &&
            biggestBuyerAmount[_prevPeriod] > 0 &&
            biggestBuyerPaid[_prevPeriod] == 0
        ) {
            uint256 _rewardAmount = IERC20(REWARD).balanceOf(address(this));
            if (_rewardAmount > 0) {
                IERC20(REWARD).transfer(
                    biggestBuyer[_prevPeriod],
                    _rewardAmount
                );

                totalBiggestBuyerPaid = totalBiggestBuyerPaid + _rewardAmount;
                biggestBuyerPaid[_prevPeriod] = _rewardAmount;

                emit PayBiggestBuyer(
                    biggestBuyer[_prevPeriod],
                    _prevPeriod,
                    _rewardAmount
                );
            }
        }
    }
}