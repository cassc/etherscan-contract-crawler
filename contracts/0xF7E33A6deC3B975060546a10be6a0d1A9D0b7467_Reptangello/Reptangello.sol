/**
 *Submitted for verification at Etherscan.io on 2023-09-11
*/

/*
ZOGZ KILLERZ BY MATT FURIE

REPTANGELLO in the Killer team of
Red Hot Cock



website https://www.reptangello.com

telegram https://https://t.me/reptangello

twitter https://twitter.com/reptangello


*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
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

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
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

contract Reptangello is ERC20, Ownable {
    using Address for address payable;

    IRouter public router;
    address public pair;

    bool private swapping;
    bool public swapEnabled;
    bool public launched;

    event TransferForeignToken(address token, uint256 amount);
    event Launched();
    event SwapEnabled();
    event SwapThresholdUpdated();
    event BuyTaxesUpdated();
    event SellTaxesUpdated();
    event MarketingWalletUpdated();
    event DevWalletUpdated();
    event ExcludedFromFeesUpdated();
    event MaxTxAmountUpdated();
    event MaxWalletAmountUpdated();
    event StuckEthersCleared();

    uint256 public swapThreshold = 100000000 * 10**18; //0.1% of total supply
    uint256 public maxTxAmount = 1000000000 * 10**18;
    uint256 public maxWalletAmount = 1000000000 * 10**18;

    address public marketingWallet = 0x81E963Ee986bd0C313dFF07e2B18535B11F03f76;
    address public devWallet = 0xae335E31224f676A77E50a6D2BBF76026Ed05C60;

    struct Taxes {
        uint256 marketing;
        uint256 liquidity;
        uint256 dev;
    }

    Taxes public buyTaxes = Taxes(15, 0, 5);
    Taxes public sellTaxes = Taxes(15, 0, 5);
    uint256 private totBuyTax = 20;
    uint256 private totSellTax = 20;

    mapping(address => bool) public excludedFromFees;

    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }

    constructor() ERC20("Reptangello", "REPTANGELLO") {
        _mint(msg.sender, 100000000000 * 10**decimals());
        excludedFromFees[msg.sender] = true;

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;
        pair = _pair;
        excludedFromFees[address(this)] = true;
        excludedFromFees[marketingWallet] = true;
        excludedFromFees[devWallet] = true;
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
            require(launched, "Trading not active yet");
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
            if (recipient == pair) fee = (amount * totSellTax) / 100;
            else if (sender == pair) fee = (amount * totBuyTax) / 100;
            else fee = 0;
        }

        if (swapEnabled && !swapping && sender != pair && fee > 0)
            swapForFees();

        super._transfer(sender, recipient, amount - fee);
        if (fee > 0) super._transfer(sender, address(this), fee);
    }

    function swapForFees() private inSwap {
        uint256 contractBalance = balanceOf(address(this));

        if (contractBalance >= swapThreshold) {
            uint256 denominator = totSellTax * 2;
            uint256 tokensToAddLiquidityWith = (contractBalance *
                sellTaxes.liquidity) / denominator;
            uint256 toSwap = contractBalance - tokensToAddLiquidityWith;

            uint256 initialBalance = address(this).balance;

            swapTokensForETH(toSwap);

            uint256 deltaBalance = address(this).balance - initialBalance;
            uint256 unitBalance = deltaBalance /
                (denominator - sellTaxes.liquidity);
            uint256 ethToAddLiquidityWith = unitBalance * sellTaxes.liquidity;

            if (tokensToAddLiquidityWith > 0 && ethToAddLiquidityWith > 0) {
                // Add liquidity to dex
                addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
            }

            uint256 marketingAmt = unitBalance * 2 * sellTaxes.marketing;
            if (marketingAmt > 0) {
                payable(marketingWallet).sendValue(marketingAmt);
            }

            uint256 devAmt = unitBalance * 2 * sellTaxes.dev;
            if (devAmt > 0) {
                payable(devWallet).sendValue(devAmt);
            }
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function setSwapEnabled(bool state) external onlyOwner {
        // to be used only in case of dire emergency
        swapEnabled = state;
        emit SwapEnabled();
    }

    function setSwapThreshold(uint256 new_amount) external onlyOwner {
        require(
            new_amount >= 10000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            new_amount <= 30000000,
            "Swap amount cannot be higher than 3% total supply."
        );
        swapThreshold = new_amount * (10**18);
        emit SwapThresholdUpdated();
    }

    function launch() external onlyOwner {
        require(!launched, "Trading already active");
        launched = true;
        swapEnabled = true;
        emit Launched();
    }

    function setTaxes(
        uint256 _bmarketing,
        uint256 _bliquidity,
        uint256 _bdev,
        uint256 _smarketing,
        uint256 _sliquidity,
        uint256 _sdev
    ) external onlyOwner {
        buyTaxes = Taxes(_bmarketing, _bliquidity, _bdev);
        totBuyTax = _bmarketing + _bliquidity + _bdev;
        sellTaxes = Taxes(_smarketing, _sliquidity, _sdev);
        totSellTax = _smarketing + _sliquidity + _sdev;
        require(totBuyTax <= 26, "Total buy fees cannot be greater than 5%");
        require(totSellTax <= 26, "Total sell fees cannot be greater than 5%");
    }

    function updateMarketingWallet(address newWallet) external onlyOwner {
        excludedFromFees[marketingWallet] = false;
        require(
            newWallet != address(0),
            "Marketing Wallet cannot be zero address"
        );
        marketingWallet = newWallet;
        emit MarketingWalletUpdated();
    }

    function updateDevWallet(address newWallet) external onlyOwner {
        excludedFromFees[devWallet] = false;
        require(newWallet != address(0), "Dev Wallet cannot be zero address");
        devWallet = newWallet;
        emit DevWalletUpdated();
    }

    function updateExcludedFromFees(address _address, bool state)
        external
        onlyOwner
    {
        excludedFromFees[_address] = state;
        emit ExcludedFromFeesUpdated();
    }

    function updateMaxTxAmount(uint256 amount) external onlyOwner {
        require(amount >= 2500000, "Cannot set maxSell lower than 0.25%");
        maxTxAmount = amount * (10**18);
        emit MaxTxAmountUpdated();
    }

    function updateMaxWalletAmount(uint256 amount) external onlyOwner {
        require(amount >= 2500000, "Cannot set maxSell lower than 0.25%");
        maxWalletAmount = amount * (10**18);
        emit MaxWalletAmountUpdated();
    }

    function withdrawStuckTokens(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    function clearStuckEthers(uint256 amountPercentage) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer((amountETH * amountPercentage) / 100);
        emit StuckEthersCleared();
    }

    // fallbacks
    receive() external payable {}
}