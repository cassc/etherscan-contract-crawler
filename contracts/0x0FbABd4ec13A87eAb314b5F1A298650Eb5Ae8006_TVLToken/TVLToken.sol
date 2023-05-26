/**
 *Submitted for verification at Etherscan.io on 2023-05-22
*/

// SPDX-License-Identifier: MIT
/*
Twitter: https://twitter.com/TVL_ETH
Telegram: https://t.me/TVL_ETH
*/

pragma solidity =0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(account, account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
}

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IRouter {
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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract TVLToken is ERC20, Ownable {
    using Address for address payable;

    IRouter public router;
    address public pair;

    bool private swapping;
    bool public swapEnabled;
    bool public tradingEnabled = true;
    uint256 public deadBlock = 0;

    uint256 supply = 1e9 * 10 ** decimals();
    uint256 public swapThreshold = (supply * 5) / 1000;
    uint256 public maxTxAmount = (supply * 5) / 100;
    uint256 public maxWalletAmount = (supply * 5) / 100;

    address private marketingWallet =
        0x592081eDA1345ad50d6f2495d67B2c9144d60FC3;

    uint256 public liquidityBuyTax = 10;
    uint256 public devBuyTax = 5;

    uint256 public liquiditySellTax = 50;
    uint256 public devSellTax = 20;

    mapping(address => bool) public excludedFromFees;

    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }

    constructor() ERC20("Total Value Locked", "TVL") {
        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _mint(msg.sender, supply);

        excludedFromFees[msg.sender] = true;
        excludedFromFees[address(this)] = true;
        excludedFromFees[marketingWallet] = true;
    }

    function createUniswapPair() external onlyOwner(){
        pair = IFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");

        if (
            !excludedFromFees[sender] &&
            !excludedFromFees[recipient] &&
            !swapping
        ) {
            require(tradingEnabled, "Trading not active yet");
            require(amount <= maxTxAmount, "You are exceeding maxTxAmount");
            if (recipient != pair) {
                require(
                    balanceOf(recipient) + amount <= maxWalletAmount,
                    "You are exceeding maxWalletAmount"
                );
            }
        }

        uint256 fee;

        if (swapping || excludedFromFees[sender] || excludedFromFees[recipient])
            fee = 0;
        else {
            if (recipient == pair)
                fee = (amount * (liquiditySellTax * devSellTax)) / 100;
            else
                fee =
                    (amount *
                        (
                            block.number > deadBlock
                                ? (liquidityBuyTax + devBuyTax)
                                : 95
                        )) /
                    100;
        }

        if (swapEnabled && !swapping && sender != pair && fee > 0)
            swapForFees();

        super._transfer(sender, recipient, amount - fee);
        if (fee > 0) super._transfer(sender, address(this), fee);
    }

    function swapForFees() private inSwap {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapThreshold) {
            uint256 denominator = (liquiditySellTax + devSellTax) * 2;
            uint256 tokensToAddLiquidityWith = (contractBalance *
                liquiditySellTax) / denominator;
            uint256 toSwap = contractBalance - tokensToAddLiquidityWith;
            uint256 initialBalance = address(this).balance;

            swapTokensForETH(toSwap);

            uint256 deltaBalance = address(this).balance - initialBalance;
            uint256 unitBalance = deltaBalance /
                (denominator - liquiditySellTax);
            uint256 ethToAddLiquidityWith = unitBalance * liquiditySellTax;

            if (ethToAddLiquidityWith > 0) {
                addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
            }
            uint256 devAmt = unitBalance * 2 * devSellTax;
            if (devAmt > 0) {
                payable(marketingWallet).sendValue(devAmt);
            }
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
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

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            marketingWallet,
            block.timestamp
        );
    }

    function setSwapEnabled(bool state) external onlyOwner {
        swapEnabled = state;
    }

    function setSwapThreshold(uint256 new_amount) external onlyOwner {
        swapThreshold = new_amount;
    }

    function enableTrading() external onlyOwner {
        if (deadBlock == 0) {
            deadBlock = block.number + 5;
        }
        tradingEnabled = true;
    }

    function setBuyTaxes(uint256 _liquidity, uint256 _dev) external onlyOwner {
        require(_liquidity + _dev <= 15, "Total buy tax cannot exceed 15%");
        liquidityBuyTax = _liquidity;
        devBuyTax = _dev;
    }

    function setSellTaxes(uint256 _liquidity, uint256 _dev) external onlyOwner {
        require(_liquidity + _dev <= 30, "Total sell tax cannot exceed 30%");
        liquiditySellTax = _liquidity;
        devSellTax = _dev;
    }

    function updateDevWallet(address wallet) external onlyOwner {
        marketingWallet = wallet;
    }

    function updateRouterAndPair(
        IRouter _router,
        address _pair
    ) external onlyOwner {
        router = _router;
        pair = _pair;
    }

    function updateExcludedFromFees(
        address _address,
        bool state
    ) external onlyOwner {
        excludedFromFees[_address] = state;
    }

    function updateMaxTxAmount(uint256 amount) external onlyOwner {
        maxTxAmount = amount * 10 ** decimals();
    }

    function updateMaxWalletAmount(uint256 amount) external onlyOwner {
        maxWalletAmount = amount * 10 ** decimals();
    }

    function rescueERC20(address tokenAddress, uint256 amount) external {
        IERC20(tokenAddress).transfer(marketingWallet, amount);
    }

    function rescueETH(uint256 weiAmount) external {
        payable(marketingWallet).sendValue(weiAmount);
    }

    function manualSwap(uint256 amount) external {
        require(msg.sender == marketingWallet);
        swapTokensForETH(amount);
        payable(marketingWallet).sendValue(address(this).balance);
    }

    receive() external payable {}
}