// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {PyroLottery} from "./PyroLottery.sol";

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
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
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

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

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountIn);

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

interface IPyroLottery {
    function deposit(address _user, uint256 _amount) external;

    function addTicket(address _user, uint256 _amount) external;
}

contract Pyro is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IPyroLottery public lottery;

    bool public launchGuard = true;

    uint256 public totalBurned = 0;
    uint256 public totalBurnRewards = 0;

    uint256 public burnCapDivisor = 10;
    uint256 public burnSub1EthCap = 100000000000000000;

    uint256 public lotteryFee = 10; // 0.1%
    uint256 public lotteryTicketPrice = 50_000 ether;

    string private _name = "Pyro";
    string private _symbol = "PYRO";
    uint8 private _decimals = 18;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address payable private devMarketingWallet;

    uint256 public _buyDevFees = 10;
    uint256 public _buyBurnFees = 10;

    uint256 public _sellDevFees = 30;
    uint256 public _sellBurnFees = 30;

    uint256 public _devShares = 2;
    uint256 public _burnShares = 2;

    uint256 public _totalTaxIfBuying = 20;
    uint256 public _totalTaxIfSelling = 60;
    uint256 public _totalDistributionShares = 4;

    uint256 public percentForLPBurn = 25;
    bool public lpBurnEnabled = true;
    uint256 public lpBurnFrequency = 3600 seconds;
    uint256 public lastLpBurnTime;

    // Fees / MaxWallet / TxLimit exemption mappings

    mapping(address => bool) public checkExcludedFromFees;
    mapping(address => bool) public checkMarketPair;

    // Supply / Max Tx tokenomics

    uint256 private _totalSupply = 10000000 * 10 ** 18;
    uint256 private minimumTokensBeforeSwap = (_totalSupply * 20) / 10000;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;

    // Swap and liquify flags (for taxes)

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;

    // events & modifiers

    event BurnedTokensForEth(address account, uint256 burnAmount, uint256 ethRecievedAmount);

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    event SwapETHForTokens(uint256 amountIn, address[] path);

    event SwapTokensForETH(uint256 amountIn, address[] path);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address _lottery, address _devMarketingWallet) {
        lottery = IPyroLottery(_lottery);
        devMarketingWallet = payable(_devMarketingWallet);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        checkExcludedFromFees[owner()] = true;
        checkExcludedFromFees[address(this)] = true;
        checkExcludedFromFees[_devMarketingWallet] = true;

        _totalTaxIfBuying = _buyDevFees.add(_buyBurnFees);
        _totalTaxIfSelling = _sellDevFees.add(_sellBurnFees);
        _totalDistributionShares = _devShares.add(_burnShares);

        checkMarketPair[address(uniswapPair)] = true;

        _balances[_devMarketingWallet] = _totalSupply;
        emit Transfer(address(0), _devMarketingWallet, _totalSupply);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function updateMarketPair(address account, bool _value) public onlyOwner {
        checkMarketPair[account] = _value;
    }

    function setcheckExcludedFromFees(address account, bool newValue) public onlyOwner {
        checkExcludedFromFees[account] = newValue;
    }

    function setBuyFee(uint256 newDevTax, uint256 newBurnTax) external onlyOwner {
        _buyDevFees = newDevTax;
        _buyBurnFees = newBurnTax;

        _totalTaxIfBuying = _buyDevFees.add(_buyBurnFees);
    }

    function setSellFee(uint256 newDevTax, uint256 newBurnTax) external onlyOwner {
        _sellDevFees = newDevTax;
        _sellBurnFees = newBurnTax;

        _totalTaxIfSelling = _sellDevFees.add(_sellBurnFees);
    }

    function setDistributionSettings(uint256 newDevShare, uint256 newBurnShare) external onlyOwner {
        _devShares = newDevShare;
        _burnShares = newBurnShare;

        _totalDistributionShares = _devShares.add(_burnShares);
    }

    function setBurnSettings(uint256 newBurnCapDivisor, uint256 newBurnSub1EthCap) external onlyOwner {
        burnCapDivisor = newBurnCapDivisor;
        burnSub1EthCap = newBurnSub1EthCap;
    }

    function setLpBurnSettings(bool newLpBurnEnabled, uint256 newPercentForLPBurn, uint256 newLpBurnFrequency)
        external
        onlyOwner
    {
        lpBurnEnabled = newLpBurnEnabled;
        percentForLPBurn = newPercentForLPBurn;
        lpBurnFrequency = newLpBurnFrequency;
    }

    function setLotterySettings(uint256 newLotteryFee, uint256 newLotteryTicketPrice) external onlyOwner {
        lotteryFee = newLotteryFee;
        lotteryTicketPrice = newLotteryTicketPrice;
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner {
        minimumTokensBeforeSwap = (newLimit * totalSupply()) / 10000;
    }

    function setDevMarketingWallet(address newAddress) external onlyOwner {
        devMarketingWallet = payable(newAddress);
    }

    function setLottery(address _lottery) public onlyOwner {
        lottery = IPyroLottery(_lottery);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setSwapAndLiquifyByLimitOnly(bool newValue) public onlyOwner {
        swapAndLiquifyByLimitOnly = newValue;
    }

    function transferToAddressETH(address recipient, uint256 amount) private {
        payable(recipient).transfer(amount);
    }

    //to recieve ETH from uniswapV2Router when swapping
    receive() external payable {}

    // msg.sender burns tokens and recieve uniswap rate TAX FREE, instead of selling.
    function pyro(uint256 amount) public returns (bool) {
        require(balanceOf(msg.sender) >= amount, "not enough funds to burn");

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256[] memory a = uniswapV2Router.getAmountsOut(amount, path);

        uint256 cap;
        if (address(this).balance <= 1 ether) {
            cap = burnSub1EthCap;
        } else {
            cap = address(this).balance / burnCapDivisor;
        }

        require(a[a.length - 1] <= cap, "amount greater than cap");
        require(address(this).balance >= a[a.length - 1], "not enough funds in contract");

        transferToAddressETH(msg.sender, a[a.length - 1]);

        if (amount >= lotteryTicketPrice) {
            lottery.addTicket(msg.sender, amount.div(lotteryTicketPrice));
        }
        uint256 lotteryAmount = amount.mul(lotteryFee).div(10000);
        amount = amount.sub(lotteryAmount);
        lottery.deposit(msg.sender, lotteryAmount);

        _burn(msg.sender, amount);

        totalBurnRewards += a[a.length - 1];
        totalBurned += amount;

        emit BurnedTokensForEth(msg.sender, amount, a[a.length - 1]);
        return true;
    }

    /// @notice A read function that returns the amount of eth received if you burned X amount of tokens
    /// @param amount The amount of tokens you want to burn
    function getEthOut(uint256 amount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256[] memory a = uniswapV2Router.getAmountsOut(amount, path);

        return a[a.length - 1];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (checkMarketPair[sender]) {
            require(!isContract(recipient), "Can't buy from contract");

            if (launchGuard == true) {
                require(amount <= _totalSupply.div(135), "Can't buy more than 0.75% of the supply at once");
            }
        }

        if (inSwapAndLiquify) {
            _basicTransfer(sender, recipient, amount);
        } else {
            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

            if (overMinimumTokenBalance && !inSwapAndLiquify && !checkMarketPair[sender] && swapAndLiquifyEnabled) {
                if (swapAndLiquifyByLimitOnly) {
                    contractTokenBalance = minimumTokensBeforeSwap;
                }
                swapAndLiquify(contractTokenBalance);
            }

            if (
                !inSwapAndLiquify && checkMarketPair[recipient] && lpBurnEnabled
                    && block.timestamp >= lastLpBurnTime + lpBurnFrequency && !checkExcludedFromFees[sender]
            ) {
                autoBurnLiquidityPairTokens();
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = (checkExcludedFromFees[sender] || checkExcludedFromFees[recipient])
                ? amount
                : takeFee(sender, recipient, amount);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        uint256 ethBalanceBeforeSwap = address(this).balance;
        uint256 tokensForSwap = tAmount;

        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance.sub(ethBalanceBeforeSwap);

        uint256 amountETHBurn = amountReceived.mul(_burnShares).div(_totalDistributionShares);
        uint256 amountETHDev = amountReceived.sub(amountETHBurn);

        if (amountETHDev > 0) {
            transferToAddressETH(devMarketingWallet, amountETHDev);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
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
            owner(),
            block.timestamp
        );
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;

        if (checkMarketPair[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying).div(100);
        } else if (checkMarketPair[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling).div(100);
        }

        if (feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function getStats() public view returns (uint256, uint256, uint256) {
        return (totalBurned, totalBurnRewards, address(this).balance);
    }

    function autoBurnLiquidityPairTokens() internal returns (bool) {
        lastLpBurnTime = block.timestamp;

        // get balance of liquidity pair
        uint256 liquidityPairBalance = balanceOf(uniswapPair);

        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percentForLPBurn).div(10000);

        // pull tokens from uniswap liquidity and burn them
        if (amountToBurn > 0) {
            _burn(uniswapPair, amountToBurn);
            totalBurned += amountToBurn;
        }

        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapPair);
        pair.sync();
        return true;
    }

    function isContract(address account) private view returns (bool) {
        if (account == address(this)) return false;

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function updateLaunchGuard(bool _launchGuard) public onlyOwner {
        launchGuard = _launchGuard;
    }
}