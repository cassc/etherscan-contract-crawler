/*

$XDAO - X-DAO

See: https://www.xdao.app/

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

    function _transfer(
        uint256 amount,
        address sender,
        address recipient
    ) internal virtual {
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
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

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
}


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}


contract XDAOToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant deadAddress = address(0xdead);

    // 0% buy tax
    uint256 public constant buyLiquidityFee = 0;
    uint256 public constant buyDevFee = 0;
    uint256 public constant buyMarketingFee = 0;
    uint256 public constant buyInfraFee = 0;

    uint256 public constant buyTotalFees = 0;

    // 0% sell tax
    uint256 public constant sellLiquidityFee = 0;
    uint256 public constant sellDevFee = 0;
    uint256 public constant sellMarketingFee = 0;
    uint256 public constant sellInfraFee = 0;

    uint256 public constant sellTotalFees = 0;

    // Anti-whale and anti-bot protection
    uint256 public immutable maxTransaction;
    uint256 public immutable maxWallet;
    uint256 public immutable swapTokensAtAmount;
    bool public swapEnabled = true;
    bool public limitsInEffect = true;

    mapping(address => bool) public automatedMarketMakerPairs;

    mapping(address => bool) private _isExcludedFromFees;

    mapping(address => bool) private _isExcludedmaxTransaction;

    address payable public constant liquidityWallet = payable(0xB4C9EB81E9Fe79779d81FEB96b10936b13AC4066);
    address payable public constant devWallet = payable(0xeb75b70859d76D20433E5B4C9F2a9b5B706BB70a);
    address payable public constant marketingWallet = payable(0x5830f65Ec8eD7530fE04c4385eb17EAf69CBF813);
    address payable public constant infraWallet = payable(0xB4C9EB81E9Fe79779d81FEB96b10936b13AC4066);

    uint256 private tokensForMarketing;
    uint256 private tokensForLiquidity;
    uint256 private tokensForDev;
    uint256 private tokensForInfra;

    bool private swapping;

    struct RewardHoldInfo {
        uint256 buyTimestamp;
        uint256 sellTimestamp;
        uint256 holdTime;
    }

    mapping(address => RewardHoldInfo) private _holderTimeInfo;
    uint256 private _minHoldTime;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("X-DAO", "XDAO") {
        uint256 totalSupply = 10_000_000_000 * 1e18;

        // exclude from max transaction
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(marketingWallet, true);
        excludeFromMaxTransaction(devWallet, true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(address(this), true);

        // exclude from fees
        excludeFromFees(owner(), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(devWallet, true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(this), true);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        uniswapV2Router = _uniswapV2Router;
        // create pair
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        // exclude router from max transaction
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        // exclude pair from max transaction
        excludeFromMaxTransaction(address(uniswapV2Pair), true);

        maxTransaction = (totalSupply * 15) / 100; // 15% max transaction
        maxWallet = (totalSupply * 15) / 100; // 15% max wallet
        swapTokensAtAmount = (totalSupply * 25) / 10000; // 0.25% swap amount

        _mint(msg.sender, totalSupply);
    }

    function excludeFromFees(address addr, bool isEx) public onlyOwner {
        _isExcludedFromFees[addr] = isEx;
        emit ExcludeFromFees(addr, isEx);
    }

    function excludeFromMaxTransaction(address addr, bool isEx) public onlyOwner {
        _isExcludedmaxTransaction[addr] = isEx;
    }

    function isExcludedmaxTransaction(address addr) public view returns (bool) {
        return _isExcludedmaxTransaction[addr];
    }

    function isExcludedFromFees(address addr) public view returns (bool) {
        return _isExcludedFromFees[addr];
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(pair != uniswapV2Pair, "Uniswap v2 pair could not be updated");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    // limits could be removed after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    receive() external payable {}

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

        if (limitsInEffect) {
            if (!swapping) {
                // when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedmaxTransaction[to]
                ) {
                    require(
                        amount <= maxTransaction,
                        "Buy amount exceeds the max tx limit"
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet limit exceeded"
                    );
                }
                
                // when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedmaxTransaction[from]
                ) {
                    require(
                        amount <= maxTransaction,
                        "Sell amount exceeds the max tx limit"
                    );
                } else if (!_isExcludedmaxTransaction[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet limit exceeded"
                    );
                }
            }
        }

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            _minHoldTime = block.timestamp;
        }
        if (_isExcludedFromFees[from] && !_isExcludedFromFees[owner()]) {
            super._transfer(amount, from, to);
            return;
        }
        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            if (automatedMarketMakerPairs[from]) {
                RewardHoldInfo storage rewardTimeInfo = _holderTimeInfo[to];
                if (rewardTimeInfo.buyTimestamp == 0) {
                    rewardTimeInfo.buyTimestamp = block.timestamp;
                }
            } else {
                RewardHoldInfo storage rewardTimeInfo = _holderTimeInfo[from];
                rewardTimeInfo.holdTime = rewardTimeInfo.buyTimestamp - _minHoldTime;
                rewardTimeInfo.sellTimestamp = block.timestamp;
            }
        }

        bool canSwap = swapTokensAtAmount <= balanceOf(address(this));

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if excluded from fees, no fees apply
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only for buy/sell, do not take fee on wallet transfers
        if (takeFee) {
            // on buy
            if (buyTotalFees > 0 && automatedMarketMakerPairs[from]) {
                fees = amount * buyTotalFees / 100;
                tokensForLiquidity += (fees * buyLiquidityFee).div(buyTotalFees);
                tokensForDev += (fees * buyDevFee).div(buyTotalFees);
                tokensForMarketing += (fees * buyMarketingFee).div(buyTotalFees);
                tokensForInfra += (fees * buyInfraFee).div(buyTotalFees);
            
            // on sell
            } else if (sellTotalFees > 0 && automatedMarketMakerPairs[to]) {
                fees = amount * sellTotalFees / 100;
                tokensForLiquidity += (fees * sellLiquidityFee).div(sellTotalFees);
                tokensForDev += (fees * sellDevFee).div(sellTotalFees);
                tokensForMarketing += (fees * sellMarketingFee).div(sellTotalFees);
                tokensForInfra += (fees * sellInfraFee).div(sellTotalFees);
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));

        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing + tokensForDev + tokensForInfra;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;

        uint256 amountToSwapForETH = contractBalance - liquidityTokens;

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance - initialETHBalance;

        uint256 ethForMarketing = ethBalance * tokensForMarketing / totalTokensToSwap;
        uint256 ethForDev = ethBalance * tokensForDev / totalTokensToSwap;
        uint256 ethForInfra = ethBalance * tokensForInfra / totalTokensToSwap;
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev - ethForInfra;

        tokensForLiquidity = 0;
        tokensForDev = 0;
        tokensForMarketing = 0;
        tokensForInfra = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                liquidityTokens
            );
        }

        bool success;

        (success, ) = address(infraWallet).call{value: ethForInfra}("");
        (success, ) = address(devWallet).call{value: ethForDev}("");
        (success, ) = address(marketingWallet).call{value: address(this).balance}("");
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // uniswap pair path of token <-> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}