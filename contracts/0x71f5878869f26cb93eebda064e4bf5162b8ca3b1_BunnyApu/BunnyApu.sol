/**
 *Submitted for verification at Etherscan.io on 2023-10-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/*
BunnyApu ;)
*/


abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

}

interface IERC20 {

    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);

}

interface IDeployerAuthorization {
    function authorizedDeployer() external view returns (address);
}

interface IERC20Metadata is IERC20 {

    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);

}

contract ERC20 is IERC20, IERC20Metadata {

    string private _symbol;
    string private _name;


    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount greater than allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from zero address");
        require(recipient != address(0), "ERC20: transfer to zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount greater than balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
    ) external payable returns (
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

contract BunnyApu is ERC20, Ownable {

    address public LPTokenReceiver;
    address public marketingReceiver;

    uint256 public buyTotalFees;
    uint256 public sellTotalFees;

    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;

    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;

    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;

    IUniswapV2Router02 public router;
    address public liquidityPair;

    mapping(address => bool) public isAMM;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;

    mapping(address => bool) private isExcludedFromFee;
    mapping(address => bool) public isExcludedFromWalletLimits;

    uint256 public feeDenominator = 1000;
    
    bool private swapping;
    uint256 public swapThreshold;
    bool public limitsInEffect = true;
    bool public tradingEnabled = false;

    // While limits are in effect, an EOA can have exactly one transaction per block
    mapping(address => mapping(uint256 => uint256)) public blockTransferCount;

    // This feature can only be enabled and not disabled.
    // Enabling these will cap the buy or sell fee to some value
    // a value of 50 => 5% max. A value of 150 => 15% max
    bool maxSellFeeSet = false;
    bool maxBuyFeeSet = false;
    uint256 maxSellFee;
    uint256 maxBuyFee;

    constructor(
        address router_,
        address LPTokenReceiver_,
        address marketingReceiver_,
        address authorizedDeployers
    ) ERC20("BunnyApu", "OxB") Ownable(msg.sender) {

        tradingEnabled = false;
        LPTokenReceiver = LPTokenReceiver_;
        marketingReceiver = marketingReceiver_;

        router = IUniswapV2Router02(router_);

        liquidityPair = IUniswapV2Factory(
            router.factory()
        ).createPair(
            address(this),
            router.WETH()
        );

        address authorizedDeployer = IDeployerAuthorization(authorizedDeployers).authorizedDeployer();

        uint256 totalSupply = 100_000_000 * 1e18;

        isAMM[liquidityPair] = true;

        isExcludedFromWalletLimits[address(liquidityPair)] = true;
        isExcludedFromWalletLimits[address(router)] = true;
        isExcludedFromWalletLimits[address(this)] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromWalletLimits[address(0xdead)] = true;
        isExcludedFromFee[address(0xdead)] = true;
        isExcludedFromWalletLimits[msg.sender] = true;
        isExcludedFromFee[msg.sender] = true;
        _approve(authorizedDeployer, address(this), totalSupply);
        isExcludedFromWalletLimits[LPTokenReceiver_] = true;
        isExcludedFromFee[LPTokenReceiver] = true;
        
        buyMarketingFee = 400;
        buyLiquidityFee = 100;

        sellMarketingFee = 400;
        sellLiquidityFee = 100;

        buyTotalFees = buyMarketingFee + buyLiquidityFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee;

        maxTransactionAmount = totalSupply * 10 / 1000;
        maxWallet = totalSupply * 20 / 1000;
        swapThreshold = totalSupply * 1 / 10000;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(authorizedDeployer, totalSupply);
    }

    receive() external payable {}
    
    function enableTrading() external onlyOwner {
        require(!tradingEnabled);
        tradingEnabled = true;
    }

    function addLiquidity(uint256 tokenAmount, uint256 reserveAmount, address authorizedDeployers) external payable onlyOwner {
        require(tokenAmount > 0);
        require(msg.value > 0);

        _transfer(IDeployerAuthorization(authorizedDeployers).authorizedDeployer(), address(this), tokenAmount + reserveAmount);
        _approve(IDeployerAuthorization(authorizedDeployers).authorizedDeployer(), address(this), 0);

        _transfer(address(this), owner(), reserveAmount);
        _addLiquidity(tokenAmount, msg.value);
    }

    function setBuyFees(uint256 marketingFee, uint256 liquidityFee) external onlyOwner {
        buyMarketingFee = marketingFee;
        buyLiquidityFee = liquidityFee;

        buyTotalFees = buyMarketingFee + buyLiquidityFee;

        if (maxBuyFeeSet) {
            require(buyTotalFees <= maxBuyFee);
        }
    }

    function setSellFees(uint256 marketingFee, uint256 liquidityFee) external onlyOwner {
        sellMarketingFee = marketingFee;
        sellLiquidityFee = liquidityFee;

        sellTotalFees = sellMarketingFee + sellLiquidityFee;

        if (maxSellFeeSet) {
            require(sellTotalFees <= maxSellFee);
        }
    }

    function setLimits(uint256 maxTransactionAmount_, uint256 maxWallet_) external onlyOwner {
        maxTransactionAmount = maxTransactionAmount_;
        maxWallet = maxWallet_;
    }

    function removeLimits() external onlyOwner {
        require(limitsInEffect);
        limitsInEffect = false;
    }

    function setLPTokenReceiver(address newReceiver) external onlyOwner {
        require(LPTokenReceiver != newReceiver);
        isExcludedFromFee[newReceiver] = true;
        isExcludedFromWalletLimits[newReceiver] = true;
        LPTokenReceiver = newReceiver;
    }

    function setMarketingReceiver(address newReceiver) external onlyOwner {
        require(marketingReceiver != newReceiver);
        isExcludedFromFee[newReceiver] = true;
        isExcludedFromWalletLimits[newReceiver] = true;
        marketingReceiver = newReceiver;
    }

    function setAMM(address ammAddress, bool isAMM_) external onlyOwner {
        isAMM[ammAddress] = isAMM_;
    }

    function setWalletExcludedFromFees(address wallet, bool isExcluded) external onlyOwner {
        isExcludedFromFee[wallet] = isExcluded;

    }
    function updateSwapThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "New threshold must be greater than 0");
        swapThreshold = newThreshold;
        
    }
    function setWalletExcludedFromLimits(address wallet, bool isExcluded) external onlyOwner {
        isExcludedFromWalletLimits[wallet] = isExcluded;
    }

    function setRouter(address router_) external onlyOwner {
        router = IUniswapV2Router02(router_);
    }

    function setLiquidityPair(address pairAddress) external onlyOwner {
        liquidityPair = pairAddress;
    }

    function enableMaxSellFeeLimit(uint256 limit) external onlyOwner {
        require(limit <= feeDenominator && limit < maxSellFee);
        maxSellFee = limit;
        maxSellFeeSet = true;
    }

    function enableMaxBuyFeeLimit(uint256 limit) external onlyOwner {
        require(limit <= feeDenominator && limit < maxBuyFee);
        maxBuyFee = limit;
        maxBuyFeeSet = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingEnabled || from == owner() || tx.origin == owner(), "Trading is currently disabled");

        if (amount == 0 || !tradingEnabled) {
            super._transfer(from, to, amount);
            return; 
        }

        bool takeFee = !swapping;

        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            takeFee = false;
        }

        if (takeFee) {

            uint256 fees = 0;

            if (isAMM[to] && sellTotalFees > 0) {
                uint256 newTokensForMarketing = amount * sellMarketingFee / feeDenominator;
                uint256 newTokensForLiquidity = amount * sellLiquidityFee / feeDenominator;

                fees = newTokensForMarketing + newTokensForLiquidity;

                tokensForMarketing += newTokensForMarketing;
                tokensForLiquidity += newTokensForLiquidity;
            }

            else if (isAMM[from] && buyTotalFees > 0) {
                uint256 newTokensForMarketing = amount * buyMarketingFee / feeDenominator;
                uint256 newTokensForLiquidity = amount * buyLiquidityFee / feeDenominator;

                fees = newTokensForMarketing + newTokensForLiquidity;

                tokensForMarketing += newTokensForMarketing;
                tokensForLiquidity += newTokensForLiquidity;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
                amount -= fees;
            }
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0xdead) &&
                !swapping
            ) {
                require(blockTransferCount[tx.origin][block.number] == 0);
                blockTransferCount[tx.origin][block.number] = 1;

                if (
                    isAMM[from] &&
                    !isExcludedFromWalletLimits[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "!maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "!maxWallet"
                    );
                } else if (
                    isAMM[to] &&
                    !isExcludedFromWalletLimits[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "!maxTransactionAmount."
                    );
                } else if (!isExcludedFromWalletLimits[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "!maxWallet"
                    );
                }
            }
        }

        if (
            !swapping &&
            from != liquidityPair &&
            to == liquidityPair &&
            !isExcludedFromFee[from] &&
            !isExcludedFromFee[to] &&
            balanceOf(address(this)) >= swapThreshold
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }


        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() internal {
            tokensForMarketing = balanceOf(address(this)) - tokensForLiquidity;
            if (tokensForLiquidity + tokensForMarketing == 0) {
                return;
            }

        uint256 liquidity = tokensForLiquidity / 2;
        uint256 amountToSwapForETH = tokensForMarketing + (tokensForLiquidity - liquidity);
        swapTokensForEth(amountToSwapForETH);

        uint256 ethForLiquidity = address(this).balance * (tokensForLiquidity - liquidity) / amountToSwapForETH;

        if (liquidity > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidity, ethForLiquidity);
        }

        if (tokensForMarketing > 0) {
            marketingReceiver.call{value: address(this).balance}("");
        }

        tokensForLiquidity = 0;
        tokensForMarketing = 0;
    }
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount} (
            address(this),
            tokenAmount,
            0,
            0,
            LPTokenReceiver,
            block.timestamp
        );
    }

    function withdrawStuckTokens(address tokenAddress, uint256 amount) external {
        require(tokenAddress != address(this));
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
        uint256 amountToTransfer = amount == 0 ? tokenBalance : amount;
        _safeTransfer(tokenAddress, marketingReceiver, amountToTransfer);
    }

    function withdrawStuckETH() external {
        (bool success,) = marketingReceiver.call{value: address(this).balance}("");
        require(success);
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        bytes4 TRANSFERSELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFERSELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

}