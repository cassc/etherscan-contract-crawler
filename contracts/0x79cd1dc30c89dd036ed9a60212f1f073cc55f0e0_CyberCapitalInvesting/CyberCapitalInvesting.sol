/**
 *Submitted for verification at Etherscan.io on 2023-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Pair {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}



contract CyberCapitalInvesting is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private constant _totalSupply = 100000 * 10**18;
    string private constant _name = "Cyber Capital Investing";
    string private constant _symbol = "CCI";
    uint8 private constant _decimals = 18;

    uint256 private _maxTransactionAmount = (_totalSupply * 2) / 100; // 2% of total supply
    uint256 private _maxWalletAmount = (_totalSupply * 2) / 100; // 2% of total supply
    uint256 private _buyFee = 5; // 5% buy tax
    uint256 private _sellFee = 5; // 5% sell tax

    address private _marketingWallet;
    bool private _isSwapEnabled = false;

    IUniswapV2Router02 private _uniswapRouter;
    IUniswapV2Pair private _uniswapPair;

    event BuyFeesUpdated(uint256 newBuyFee);
    event SellFeesUpdated(uint256 newSellFee);
    event SwapEnabledUpdated(bool newSwapEnabled);

    constructor(address marketingWalletAddress, address uniswapRouterAddress) {
        _marketingWallet = marketingWalletAddress;
        _uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function removeLimits() external onlyOwner {
        _maxTransactionAmount = _totalSupply;
        _maxWalletAmount = _totalSupply;
    }

    function updateBuyFees(uint256 newBuyFee) external onlyOwner {
        require(newBuyFee <= 100, "Buy fee must be between 0 and 100");
        _buyFee = newBuyFee;
        emit BuyFeesUpdated(newBuyFee);
    }

    function updateSellFees(uint256 newSellFee) external onlyOwner {
        require(newSellFee <= 100, "Sell fee must be between 0 and 100");
        _sellFee = newSellFee;
        emit SellFeesUpdated(newSellFee);
    }

    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        require(newMarketingWallet != address(0), "Marketing wallet cannot be the zero address");
        _marketingWallet = newMarketingWallet;
    }

    function updateMaxTxnAmount(uint256 newMaxTxnAmount) external onlyOwner {
        require(newMaxTxnAmount > 0, "Max transaction amount must be greater than zero");
        _maxTransactionAmount = newMaxTxnAmount;
    }

    function updateSwapEnable(bool newSwapEnabled) external onlyOwner {
        _isSwapEnabled = newSwapEnabled;
        emit SwapEnabledUpdated(newSwapEnabled);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (sender != owner() && recipient != owner()) {
            require(amount <= _maxTransactionAmount, "Transfer amount exceeds the maximum transaction limit");
            require(
                _balances[recipient] + amount <= _maxWalletAmount,
                "Recipient wallet balance exceeds the maximum wallet limit"
            );
        }

        uint256 taxAmount;
        if (_isSwapEnabled && sender != owner()) {
            if (sender == address(_uniswapPair)) {
                taxAmount = (amount * _buyFee) / 100;
            } else if (recipient == address(_uniswapPair)) {
                taxAmount = (amount * _sellFee) / 100;
            }
        }

        uint256 transferAmount = amount - taxAmount;

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[_marketingWallet] += taxAmount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, _marketingWallet, taxAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}