/**
 *Submitted for verification at Etherscan.io on 2023-05-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/** VEPE, VOLUMIZER + PEPE

Combining the hype of PEPE with a volumizer contract.
For every sell our volumizer sells and buys back - creating tremendous volume

tg:  https://t.me/VolumePepePortal

Our decentralized website deployed on IPFS

web:  https://volumepepe.eth.limo/

**/

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IVolume {
    function addVolume() external;

    function isActive() external view returns (bool);

    function setActive(bool status) external;

    function setSwapPercentage(uint256 perc) external;

    function setMaxWeiSwap(uint256 amount) external;

    function weiVolume() external view returns(uint256);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract VolumePEPE is IERC20, Ownable {
    // Constant addresses
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    IDEXRouter public constant router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public immutable pair;

    string constant _name = "VolumePEPE";
    string constant _symbol = "VEPE";
    uint8 constant _decimals = 18;

    // 1 billion
    uint256 _totalSupply = 1 * (10**9) * (10**_decimals);

    // Divide tax by 1_000, so we can use decimal tax, like 1.5%
    uint256 constant taxDivisor = 1_000;

    // 10 / 1000 = 0.01 = 1%
    uint256 public _maxTxAmount = (_totalSupply * 10) / taxDivisor;
    uint256 public _maxWalletToken = (_totalSupply * 10) / taxDivisor;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    // No fee at all
    mapping(address => bool) isFeeExempt;

    // max Wallet + max TX exempt
    mapping(address => bool) isTxLimitExempt;

    // We charge lp fee and volume fee.
    // volume fees goes directly to the volumizer contract
    uint256 liquidityFee = 10;
    uint256 volumeFee = 15;
    uint256 public totalFee = liquidityFee + volumeFee;

    uint256 private sniperTaxTill;

    // We control the fees and limits in case something would go wrong
    bool feesEnabled = true;
    bool limits = true;

    // To keep track of the tokens collected to swap
    uint256 public tokensForLiquidity;

    // Wallets used to send the fees to
    address public liquidityWallet;

    // One time trade lock (before lp)
    bool tradeBlock = true;
    bool lockUsed = false;

    // When to swap contract tokens, and how many to swap
    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply * 10) / 100_000; // 0.01%
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    // Volumizer
    IVolume Volume;
    uint256 public addedVolume;
    uint256 public skippedVolume;
    uint256 public volPerc;
    address public volumizerDev;
    uint256 maxGas = 500_000;

    // Volumizer modifier, eventhough we renounce all basic contract
    // functions we should be able to adjust the volumizer to increase
    // or decrease volume. Hence a seperate modifier for this 
    modifier onlyVolumizerDev() {
        require(volumizerDev == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        volumizerDev = msg.sender;
        address volumeContract = 0xb48AeB68A8C575E78313814049acDdED7D79Ee59;

        // Init volumizer and exempt it
        Volume = IVolume(volumeContract);
        isFeeExempt[volumeContract] = true;
        isTxLimitExempt[volumeContract] = true;

        // Exclude token contract itself
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;

        // Exclude owner
        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        // Exclude pair and router
        isTxLimitExempt[address(pair)] = true;
        isTxLimitExempt[address(router)] = true;

        // Set fee receivers
        liquidityWallet = msg.sender;

        // Arrange approvals
        _approve(address(this), address(router), _totalSupply);
        _approve(msg.sender, address(pair), _totalSupply);

        // Mint the tokens:
        // 90% to contract (to add to LP)
        // 10% to volumizer
        _balances[address(this)] = (_totalSupply * 90) / 100;
        emit Transfer(address(0), msg.sender, (_totalSupply * 90) / 100);

        // We add 10% to the volumizer contract
        _balances[volumeContract] = (_totalSupply * 10) / 100;
        emit Transfer(address(0), msg.sender, (_totalSupply * 10) / 100);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }


    function startTrading() external payable onlyOwner {
        inSwap = true;
        addLiquidity(balanceOf(address(this)), msg.value, msg.sender);
        tradeBlock = false;
        inSwap = false;
        sniperTaxTill = block.number + 2;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Insufficient Balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkLimits(
        address sender,
        address recipient,
        uint256 amount
    ) internal view {
        if (isTxLimitExempt[sender] && isTxLimitExempt[recipient]) {
            return;
        }

        // buy
        if (sender == pair && !isTxLimitExempt[recipient]) {
            require(amount <= _maxTxAmount, "Max tx limit");

        // sell
        } else if (recipient == pair && !isTxLimitExempt[sender]) {
            require(amount <= _maxTxAmount, "Max tx limit");
        }

        // Max wallet
        if (!isTxLimitExempt[recipient]) {
            require(amount + balanceOf(recipient) <= _maxWalletToken, "Max wallet");
        }
    }
    
    // Apply tx and max wallet limits (these can't be restricted to < 1%)
    function disableLimits() external onlyOwner {
        limits = false;
    }

    function shouldTokenSwap(address recipient) internal view returns (bool) {
        return
            recipient == pair && // i.e. is sell
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function takeFee(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        // Don't charge fees for exemept sender and recipient
        if (isFeeExempt[from] || isFeeExempt[to]) {
            return amount;
        }

        uint256 fees;
        uint256 volumeFeeTokens;

        // Sniper tax for first 2 blocks
        if (block.number < sniperTaxTill) {
            fees = (amount * 98) / 100;
            tokensForLiquidity += fees;
        }
        // Regular fee
        else if (totalFee > 0) {
            fees = (amount * totalFee) / taxDivisor;
            tokensForLiquidity += (fees * liquidityFee) / totalFee;
            volumeFeeTokens = (fees * volumeFee) / totalFee;
        }

        // If we collected fees, send them to the contract
        if (fees > 0) {
            // The fees we swap later (lp)
            _basicTransfer(from, address(this), fees - volumeFeeTokens);
            emit Transfer(from, address(this), fees - volumeFeeTokens);

            // The fees that go to the volumizer, we can send them directly
            _basicTransfer(from, address(Volume), volumeFeeTokens);
            emit Transfer(from, address(Volume), volumeFeeTokens);
        }

        return amount - fees;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // Swap path token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        // Make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount, address sendTo) private {
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            sendTo,
            block.timestamp
        );
    }

    function swapBack() internal swapping {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity;
       
        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;

        uint256 initialETHBalance = address(this).balance;

        // Swap the tokens for ETH
        swapTokensForEth(amountToSwapForETH);

        uint256 ethForLiquidity = address(this).balance - initialETHBalance;

        // Reset token fee
        tokensForLiquidity = 0;

        // Add liquidty
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity, liquidityWallet);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        if (owner() == msg.sender) {
            return _basicTransfer(msg.sender, recipient, amount);
        } else {
            return _transferFrom(msg.sender, recipient, amount);
        }
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (_allowances[sender][msg.sender] != _totalSupply) {
            // Get the current allowance
            uint256 curAllowance = _allowances[sender][msg.sender];
            require(curAllowance >= amount, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function addVolume() internal swapping {
        try Volume.addVolume{gas: maxGas}() {
            addedVolume += 1;
        } catch {
            skippedVolume += 1;
        }
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        // These transfers are always feeless and limitless
        if (sender == owner() || recipient == owner() || inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        // In any other case, check if trading is open already
        require(tradeBlock == false, "Trading not open yet");

        // If limits are enabled we check the max wallet and max tx.
        if (limits) {
            checkLimits(sender, recipient, amount);
        }

        // Charge transaction fees (only swaps) when enabled
        // These are our basic/regular fees (i.e. the ones we swap to ETH)
        if (feesEnabled) {
            amount = (recipient == pair || sender == pair)
                ? takeFee(sender, recipient, amount)
                : amount;
        }

        // Add volume if volumizer is active ( = enabled, enough balance, lp check)
        if (recipient == pair && Volume.isActive()) {
            addVolume(); // uses inswap to not charge token fees
        }

        // Check how much feess are accumulated in the contract, if > threshold, swap
        if (shouldTokenSwap(recipient)) {
            swapBack();
        }

        // Send the remaining tokens, after fee
        _basicTransfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);

        return true;
    }

    function clearStuckWETH(uint256 perc) external  {
        require(msg.sender == volumizerDev);
        uint256 amountWETH = address(this).balance;
        payable(volumizerDev).transfer((amountWETH * perc) / 100);
    }

    ///////////////////////////////////////////////////////////////////
    // Volumizer settings
    // These can be controlled after renounce to adjust accordingly
    // via onlyVolumizerDev modifier
    ///////////////////////////////////////////////////////////////////

    function volumizer_setMaxWeiSwap(uint weiAmount) external onlyVolumizerDev {
        Volume.setMaxWeiSwap(weiAmount);
    }

    function volumizer_setSwapPercentage(uint256 perc) external onlyVolumizerDev {
        Volume.setSwapPercentage(perc);
    }

    function volumizer_setEnabled(bool enabled) external onlyVolumizerDev {
        Volume.setActive(enabled);
    }

    function volumizer_changeGasLimit(uint newGasLim) external onlyVolumizerDev {
        maxGas = newGasLim;
    }

    function volumizer_addedVolume() external view returns(uint256) {
        return Volume.weiVolume();
    }

    ///////////////////////////////////////////////////////////////////

    receive() external payable {}
}