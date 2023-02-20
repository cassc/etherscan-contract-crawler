/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

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

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Square is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee;

    uint8 private _decimals = 9;
    string private _name = "SquareChain";
    string private _symbol = "Qua";
    uint256 private _initSupply = 1_000_000_000;
    uint256 private _totalSupply = _initSupply * 10**_decimals;
    IUniswapV2Router02 public immutable _uniswapV2Router;
    address public immutable _uniswapV2Pair;

    bool private inSwapAndLiquify;
    uint256 private feeDenominator = 1000;
    bool public hasTax;
    bool public takeTax;
    address payable public treasuryWallet;
    address public liquidityWallet;
    uint256 public minFlushTokens;
    uint256 public lpAmount;
    uint256 public treasuryAmount;

    struct ITax {
        uint256 lpFee;
        uint256 treasuryFee;
        uint256 burnFee;
    }

    ITax public buyTax =
        ITax({
            lpFee: 10,
            treasuryFee: 50,
            burnFee: 0
        });

    ITax public sellTax =
        ITax({
            lpFee: 20,
            treasuryFee: 50,
            burnFee: 0
        });

    ITax public transferTax =
        ITax({
            lpFee: 10,
            treasuryFee: 50,
            burnFee: 0
        });

    modifier inSwapNLiquidity() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event ToTreasury(uint256 balance0);
    event ToLiquidity(uint256 balance0, uint256 balance1);
    event ToBurn(uint256 balance0);

    constructor(address _treasuryWallet) {
        treasuryWallet = payable(_treasuryWallet);
        liquidityWallet = _msgSender();

        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[treasuryWallet] = true;
        _isExcludedFromFee[liquidityWallet] = true;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        lpAmount = 0;
        treasuryAmount = 0;
        minFlushTokens = 1000000 * 10**_decimals; //0.1%
        hasTax = true;
        takeTax = true;

        _balances[address(this)] = 0;
        _balances[treasuryWallet] = 0;

        //IUniswapV2Router02 uniswapV2 = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //bsc-tesnet-pcs
        IUniswapV2Router02 uniswapV2 = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //bsc-mainnet-pcs

        _uniswapV2Pair = IUniswapV2Factory(uniswapV2.factory()).createPair(address(this), uniswapV2.WETH());
        _uniswapV2Router = uniswapV2;

        _approve(_msgSender(), address(uniswapV2), type(uint256).max);
        _approve(address(this), address(uniswapV2), type(uint256).max);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
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

    function transferFrom(address sender,address recipient,uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - (amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + (addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - (subtractedValue));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMinTokens(uint256 _newAmount) external onlyOwner {
        minFlushTokens = _newAmount * 10**_decimals;
    }
    
    function flushBalance() external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(treasuryWallet).transfer(amountETH);
    }

    function setWalletFromFee(address account, bool flag) public onlyOwner {
        _isExcludedFromFee[account] = flag;
    }

    function flushTreasuryAmount(uint256 tokenBalance) external onlyOwner {
        shouldTakeTreasury(tokenBalance);
    }

    function flushLiquidityAmount(uint256 tokenBalance) external onlyOwner {
        shouldTakeLiquidity(tokenBalance);
    }

    function setTreasuryWallet(address payable wallet) external onlyOwner {
        treasuryWallet = payable(wallet);
    }

    function setLiquidityWallet(address wallet) external onlyOwner {
        liquidityWallet = wallet;
    }

    function setHasTaxStatus(bool flag) public onlyOwner {
        hasTax = flag;
    }

    function setTakeTaxStatus(bool flag) public onlyOwner {
        takeTax = flag;
    }

    function setTaxBuy(uint256 liqFee, uint256 treasuryFee, uint256 burnFee) public onlyOwner {
        require(liqFee + treasuryFee + burnFee <= 150);
        buyTax = ITax({
            lpFee: liqFee,
            treasuryFee: treasuryFee,
            burnFee: burnFee
        });
    }

    function setTaxSell(uint256 liqFee, uint256 treasuryFee, uint256 burnFee) public onlyOwner {
        require(liqFee + treasuryFee + burnFee <= 150);
        sellTax = ITax({
            lpFee: liqFee,
            treasuryFee: treasuryFee,
            burnFee: burnFee
        });
    }

    function setTaxTransfer(uint256 liqFee, uint256 treasuryFee, uint256 burnFee) public onlyOwner {
        require(liqFee + treasuryFee + burnFee <= 150);
        transferTax = ITax({
            lpFee: liqFee,
            treasuryFee: treasuryFee,
            burnFee: burnFee
        });
    }

    function shouldTakeLiquidity(uint256 tokenBalance) private inSwapNLiquidity {
        if (tokenBalance > 0) {
            uint256 splittedBalance = tokenBalance / 2;
            uint256 initBalance = address(this).balance;
            swapTokensForEth(splittedBalance);
            uint256 currentBalance = address(this).balance;

            uint256 ethBalance = uint256(currentBalance - initBalance);
            if (ethBalance > 0) {
                addLiquidity(splittedBalance, ethBalance);
                emit ToLiquidity(splittedBalance, ethBalance);
                lpAmount -= tokenBalance;
            }
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        if(_allowances[address(this)][address(_uniswapV2Router)] < tokenAmount) {
            _approve(address(this), address(_uniswapV2Router), type(uint256).max);
        }

        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
    }

    function shouldTakeTreasury(uint256 tokenBalance) private inSwapNLiquidity {
        if (tokenBalance > 0) {
            uint256 initBalance = address(this).balance;
            swapTokensForEth(tokenBalance);
            uint256 currentBalance = address(this).balance;

            uint256 ethBalance = uint256(currentBalance - initBalance);
            if (ethBalance > 0) {
                treasuryWallet.transfer(ethBalance);
                emit ToTreasury(ethBalance);
                treasuryAmount -= tokenBalance;
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        if(_allowances[address(this)][address(_uniswapV2Router)] < tokenAmount) {
            _approve(address(this), address(_uniswapV2Router), type(uint256).max);
        }

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        require(amount > 0, "Transfer amount must be greater than zero");

        if(!inSwapAndLiquify && from != _uniswapV2Pair && hasTax) {
            if (treasuryAmount > minFlushTokens) {
                shouldTakeTreasury(minFlushTokens);
            }else{
                if (lpAmount > minFlushTokens) {
                    shouldTakeLiquidity(minFlushTokens);
                }
            }
        }

        bool shouldTakeFee = true;

        if(!takeTax) {
            shouldTakeFee = false;
        }else{
            if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                shouldTakeFee = false;
            }
        }

        _tokenTransfer(from, to, amount, shouldTakeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool shouldTakeFee) private {
        uint256 liqFee = 0;
        uint256 treasuryFee = 0;
        uint256 burnFee = 0;

        uint256 liqFeeAmount = 0;
        uint256 treasuryFeeAmount = 0;
        uint256 burnFeeAmount = 0;

        uint256 feeAmount = 0;

        if (shouldTakeFee) {
            if (sender == _uniswapV2Pair) {
                liqFee = buyTax.lpFee;
                treasuryFee = buyTax.treasuryFee;
                burnFee = buyTax.burnFee;
            } else if (recipient == _uniswapV2Pair) {
                liqFee = sellTax.lpFee;
                treasuryFee = sellTax.treasuryFee;
                burnFee = sellTax.burnFee;
            } else {
                liqFee = transferTax.lpFee;
                treasuryFee = transferTax.treasuryFee;
                burnFee = transferTax.burnFee;
            }

            uint256 total = (liqFee + treasuryFee + burnFee);

            feeAmount = (amount * total) / (feeDenominator);

            if (total > 0) {
                liqFeeAmount = feeAmount * liqFee / total;
                treasuryFeeAmount = feeAmount * treasuryFee / total;
                burnFeeAmount = feeAmount * burnFee / total;
            }

            lpAmount += liqFeeAmount;
            treasuryAmount += treasuryFeeAmount;
        }

        uint256 _totalWalletsFee = (liqFeeAmount + treasuryFeeAmount);

        _balances[sender] -= amount;
        _balances[address(this)] += _totalWalletsFee;
        emit Transfer(sender, address(this), _totalWalletsFee);

        uint256 finalAmount = amount - (liqFeeAmount + treasuryFeeAmount + burnFeeAmount);
        _balances[recipient] += finalAmount;
        emit Transfer(sender, recipient, finalAmount);

        if (burnFeeAmount > 0) {
            _balances[address(0xdead)] += burnFeeAmount;
            emit Transfer(sender, address(0xdead), burnFeeAmount);
            emit ToBurn(burnFeeAmount);
        }
    }

    receive() external payable {}
}