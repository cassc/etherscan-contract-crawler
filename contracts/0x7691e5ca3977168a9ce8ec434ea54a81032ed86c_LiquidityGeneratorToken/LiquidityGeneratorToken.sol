/**
 *Submitted for verification at Etherscan.io on 2023-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

library SafeMath {
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
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function WETC() external pure returns (address);

    function WHT() external pure returns (address);

    function WROSE() external pure returns (address);

    function WAVAX() external pure returns (address);

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
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function addLiquidityAVAX(
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

    function addLiquidityETC(
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

    function addLiquidityROSE(
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

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETCSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForROSESupportingFeeOnTransferTokens(
        uint256 amountIn,
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

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

abstract contract BaseToken {
    event TokenCreated(
        address indexed owner,
        address indexed token,
        string tokenType,
        uint256 version
    );
}

abstract contract CoinscopeBuyback {
    address public constant COINSCOPE_ADDRESS =
        0xD41C4805A9A3128f9F7A7074Da25965371Ba50d5;

    IUniswapV2Router02 public constant BSC_PANCAKE_ROUTER =
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    event CoinscopeBuybackRejectedSwapBalance();
    event CoinscopeBuybackApproved(
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity,
        uint256 ownerAmountReceiveed
    );
    event CoinscopeBuybackRejectedLiquidity();
    event CoinscopeBuybackRejectedSwap();

    function coinscopeBuyback(
        address recepient,
        address platformFeeReceiver,
        uint8 feeShare
    ) internal {
        if (block.chainid != 56 || address(this).balance == 0 || feeShare > 100)
            return;

        address[] memory path = new address[](2);
        path[0] = BSC_PANCAKE_ROUTER.WETH();
        path[1] = COINSCOPE_ADDRESS;

        uint256 swapAmount = (address(this).balance * feeShare) / 100;

        try
            BSC_PANCAKE_ROUTER.swapExactETHForTokens{value: swapAmount}(
                0,
                path,
                address(this),
                block.timestamp
            )
        returns (uint256[] memory amounts) {
            uint256 coinscopeBalance = amounts[amounts.length - 1];

            if (coinscopeBalance == 0) {
                emit CoinscopeBuybackRejectedSwapBalance();
                return;
            }

            uint256 ownerTokens = coinscopeBalance / 100;

            IERC20 coinscopeToken = IERC20(COINSCOPE_ADDRESS);

            require(
                coinscopeToken.transfer(recepient, ownerTokens),
                "Coinscope tokens should transferred to owner"
            );

            coinscopeBalance = coinscopeToken.balanceOf(address(this));

            require(
                coinscopeToken.approve(
                    address(BSC_PANCAKE_ROUTER),
                    coinscopeBalance
                ),
                "Coinscope allowance should be approved"
            );

            try
                BSC_PANCAKE_ROUTER.addLiquidityETH{
                    value: address(this).balance
                }(
                    COINSCOPE_ADDRESS,
                    coinscopeBalance,
                    0,
                    0,
                    platformFeeReceiver,
                    block.timestamp
                )
            returns (
                uint256 amountToken,
                uint256 amountETH,
                uint256 liquidity
            ) {
                emit CoinscopeBuybackApproved(
                    amountToken,
                    amountETH,
                    liquidity,
                    ownerTokens
                );
            } catch {
                emit CoinscopeBuybackRejectedLiquidity();
            }
        } catch {
            emit CoinscopeBuybackRejectedSwap();
        }
    }
}

contract LiquidityGeneratorToken is
    IERC20,
    Ownable,
    BaseToken,
    CoinscopeBuyback
{
    using SafeMath for uint256;

    uint256 public constant VERSION = 3;

    mapping(address => uint256) private rOwned;
    mapping(address => uint256) private tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private isExcludedFromFee;
    mapping(address => bool) private isExcluded;
    address[] private excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private immutable tTotal;
    uint256 private rTotal;
    uint256 private tFeeTotal;

    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    uint256 public taxFee;
    uint256 private previousTaxFee;

    uint256 public liquidityFee;
    uint256 private previousLiquidityFee;

    uint256 public teamFee;
    uint256 private previousTeamFee;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public teamAddress;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;

    uint256 private numTokensSellToAddToLiquidity;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event UpdatedTokenSellToLiquify(uint256 amount, uint256 previousAmount);
    event UpdatedTaxFeePercent(uint256 value, uint256 previousValue);
    event UpdatedLiquidityFeePercent(uint256 value, uint256 previousValue);
    event UpdatedTeamFeePercent(uint256 value, uint256 previousValue);
    event UpdatedTeamAddress(address value, address previousValue);
    event Reflect(address sender, uint256 amount);
    event SwapError(uint256 amount);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        address router_,
        address teamAddress_,
        uint16 taxfeeTax_,
        uint16 liquidityFeeTax_,
        uint16 teamFeeTax_,
        address feeReceiver,
        uint8 feeShare
    ) payable {
        require(
            teamAddress_ != address(0),
            "teamAddress_ should not be the zero address"
        );

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        tTotal = totalSupply_;
        rTotal = (MAX - (MAX % tTotal));

        taxFee = taxfeeTax_;
        previousTaxFee = taxFee;

        liquidityFee = liquidityFeeTax_;
        previousLiquidityFee = liquidityFee;

        teamAddress = teamAddress_;
        teamFee = teamFeeTax_;
        previousTeamFee = teamFee;

        validateTaxes();

        numTokensSellToAddToLiquidity = (totalSupply_) / 10000; // 0.01%

        swapAndLiquifyEnabled = true;

        rOwned[owner()] = rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router_);

        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), getNativeCurrency());

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), owner(), tTotal);

        emit TokenCreated(
            owner(),
            address(this),
            "liquidityGenerator",
            VERSION
        );

        if (feeReceiver == address(0x0)) return;

        coinscopeBuyback(owner(), feeReceiver, feeShare);
        payable(feeReceiver).transfer(address(this).balance);
    }

    function getNativeCurrency() internal view returns (address) {
        if (block.chainid == 61) {
            //etc
            return uniswapV2Router.WETC();
        } else if (block.chainid == 128) {
            //heco chain
            return uniswapV2Router.WHT();
        } else if (block.chainid == 42262) {
            //oasis
            return uniswapV2Router.WROSE();
        } else if (block.chainid == 43114 || block.chainid == 43113) {
            //avalance
            return uniswapV2Router.WAVAX();
        } else {
            return uniswapV2Router.WETH();
        }
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (isExcluded[account]) return tOwned[account];
        return tokenFromReflection(rOwned[account]);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address account,
        address spender
    ) external view override returns (uint256) {
        return _allowances[account][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external virtual returns (bool) {
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
    ) external virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(
        address account
    ) external view returns (bool) {
        return isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return tFeeTotal;
    }

    function deliver(uint256 tAmount) external {
        address sender = _msgSender();
        require(
            !isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , , ) = _getValues(tAmount);
        rOwned[sender] = rOwned[sender] - rAmount;
        rTotal = rTotal - rAmount;
        tFeeTotal = tFeeTotal + tAmount;
    }

    function reflectionFromToken(
        uint256 tAmount,
        bool deductTransferFee
    ) external view returns (uint256) {
        require(tAmount <= tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) external onlyOwner {
        require(!isExcluded[account], "Account is already excluded");
        if (rOwned[account] > 0) {
            tOwned[account] = tokenFromReflection(rOwned[account]);
        }
        isExcluded[account] = true;
        excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(isExcluded[account], "Account is already excluded");

        for (uint256 i = 0; i < excluded.length; i++) {
            if (excluded[i] == account) {
                excluded[i] = excluded[excluded.length - 1];
                tOwned[account] = 0;
                isExcluded[account] = false;
                excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tTeam
        ) = _getValues(tAmount);
        tOwned[sender] = tOwned[sender] - tAmount;
        rOwned[sender] = rOwned[sender] - rAmount;
        tOwned[recipient] = tOwned[recipient] + tTransferAmount;
        rOwned[recipient] = rOwned[recipient] + rTransferAmount;
        _takeLiquidity(sender, tLiquidity);
        _takeTeamFee(sender, tTeam);
        _reflectFee(sender, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) external onlyOwner {
        isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFeeBps) external onlyOwner {
        emit UpdatedTaxFeePercent(taxFeeBps, taxFee);

        taxFee = taxFeeBps;

        validateTaxes();
    }

    function setLiquidityFeePercent(
        uint256 liquidityFeeBps
    ) external onlyOwner {
        emit UpdatedLiquidityFeePercent(liquidityFeeBps, liquidityFee);

        liquidityFee = liquidityFeeBps;

        validateTaxes();
    }

    function setTeamFeePercent(uint256 teamFeeBps) external onlyOwner {
        emit UpdatedTeamFeePercent(teamFeeBps, teamFee);

        teamFee = teamFeeBps;

        validateTaxes();
    }

    function setTeamAddress(address wallet) external onlyOwner {
        require(wallet != address(0x0));

        emit UpdatedTeamAddress(wallet, teamAddress);

        teamAddress = wallet;
    }

    function validateTaxes() internal view {
        require(
            taxFee + liquidityFee + teamFee <= 10 ** 4 / 5,
            "Total fee is over 20%"
        );
    }

    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }

    function setTokenSellToLiquify(uint256 amount) external onlyOwner {
        require(
            amount > tTotal / 10 ** 5 && amount <= tTotal / 10 ** 3,
            "Amount must be between 0.001% - 0.1% of total supply"
        );

        emit UpdatedTokenSellToLiquify(amount, numTokensSellToAddToLiquidity);

        numTokensSellToAddToLiquidity = amount;
    }

    receive() external payable {}

    function _getValues(
        uint256 tAmount
    )
        private
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tTeam
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tTeam,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity,
            tTeam
        );
    }

    function _getTValues(
        uint256 tAmount
    ) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTeamFee = calculateTeamFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee - tLiquidity - tTeamFee;
        return (tTransferAmount, tFee, tLiquidity, tTeamFee);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tTeam,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTeam = tTeam * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity - rTeam;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = rTotal;
        uint256 tSupply = tTotal;
        for (uint256 i = 0; i < excluded.length; i++) {
            if (rOwned[excluded[i]] > rSupply || tOwned[excluded[i]] > tSupply)
                return (rTotal, tTotal);
            rSupply = rSupply - rOwned[excluded[i]];
            tSupply = tSupply - tOwned[excluded[i]];
        }
        if (rSupply < rTotal / tTotal) return (rTotal, tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        if (tLiquidity == 0) return;

        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        rOwned[address(this)] = rOwned[address(this)] + rLiquidity;

        if (isExcluded[address(this)])
            tOwned[address(this)] = tOwned[address(this)] + tLiquidity;

        emit Transfer(sender, address(this), tLiquidity);
    }

    function _takeTeamFee(address sender, uint256 tTeam) private {
        if (tTeam == 0) return;

        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam * currentRate;
        rOwned[teamAddress] = rOwned[teamAddress] + rTeam;

        if (isExcluded[teamAddress])
            tOwned[teamAddress] = tOwned[teamAddress] + tTeam;

        emit Transfer(sender, teamAddress, tTeam);
    }

    function _reflectFee(address sender, uint256 rFee, uint256 tFee) private {
        if (tFee == 0) return;

        rTotal = rTotal - rFee;
        tFeeTotal = tFeeTotal + tFee;

        emit Reflect(sender, tFee);
    }

    function calculateTaxFee(uint256 amount) private view returns (uint256) {
        return (amount * taxFee) / (10 ** 4);
    }

    function calculateLiquidityFee(
        uint256 amount
    ) private view returns (uint256) {
        return (amount * liquidityFee) / (10 ** 4);
    }

    function calculateTeamFee(uint256 amount) private view returns (uint256) {
        return (amount * teamFee) / (10 ** 4);
    }

    function removeAllFee() private {
        previousTaxFee = taxFee;
        previousLiquidityFee = liquidityFee;
        previousTeamFee = teamFee;

        taxFee = 0;
        liquidityFee = 0;
        teamFee = 0;
    }

    function restoreAllFee() private {
        taxFee = previousTaxFee;
        liquidityFee = previousLiquidityFee;
        teamFee = previousTeamFee;
    }

    function getIsExcludedFromFee(address account) public view returns (bool) {
        return isExcludedFromFee[account];
    }

    function _approve(
        address account,
        address spender,
        uint256 amount
    ) private {
        require(account != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[account][spender] = amount;
        emit Approval(account, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = !isExcludedFromFee[from] && !isExcludedFromFee[to];

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance - initialBalance;

        if (newBalance == 0) return;

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = getNativeCurrency();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        if (block.chainid == 61) {
            //etc
            try
                uniswapV2Router
                    .swapExactTokensForETCSupportingFeeOnTransferTokens(
                        tokenAmount,
                        0, // accept any amount of ETH
                        path,
                        address(this),
                        block.timestamp
                    )
            {} catch {
                emit SwapError(tokenAmount);
            }
        } else if (block.chainid == 42262) {
            //oasis
            try
                uniswapV2Router
                    .swapExactTokensForROSESupportingFeeOnTransferTokens(
                        tokenAmount,
                        0, // accept any amount of ETH
                        path,
                        address(this),
                        block.timestamp
                    )
            {} catch {
                emit SwapError(tokenAmount);
            }
        } else if (block.chainid == 43114 || block.chainid == 43113) {
            //avalance
            try
                uniswapV2Router
                    .swapExactTokensForAVAXSupportingFeeOnTransferTokens(
                        tokenAmount,
                        0, // accept any amount of ETH
                        path,
                        address(this),
                        block.timestamp
                    )
            {} catch {
                emit SwapError(tokenAmount);
            }
        } else {
            try
                uniswapV2Router
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(
                        tokenAmount,
                        0, // accept any amount of ETH
                        path,
                        address(this),
                        block.timestamp
                    )
            {} catch {
                emit SwapError(tokenAmount);
            }
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        if (block.chainid == 61) {
            //etc
            uniswapV2Router.addLiquidityETC{value: ethAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                owner(),
                block.timestamp
            );
        } else if (block.chainid == 42262) {
            //oasis
            uniswapV2Router.addLiquidityROSE{value: ethAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                owner(),
                block.timestamp
            );
        } else if (block.chainid == 43114 || block.chainid == 43113) {
            //avalance
            uniswapV2Router.addLiquidityAVAX{value: ethAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                owner(),
                block.timestamp
            );
        } else {
            uniswapV2Router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                owner(),
                block.timestamp
            );
        }
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (isExcluded[sender] && !isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!isExcluded[sender] && isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!isExcluded[sender] && !isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (isExcluded[sender] && isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tTeam
        ) = _getValues(tAmount);
        rOwned[sender] = rOwned[sender] - rAmount;
        rOwned[recipient] = rOwned[recipient] + rTransferAmount;
        _takeLiquidity(sender, tLiquidity);
        _takeTeamFee(sender, tTeam);
        _reflectFee(sender, rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tTeam
        ) = _getValues(tAmount);
        rOwned[sender] = rOwned[sender] - rAmount;
        tOwned[recipient] = tOwned[recipient] + tTransferAmount;
        rOwned[recipient] = rOwned[recipient] + rTransferAmount;
        _takeLiquidity(sender, tLiquidity);
        _takeTeamFee(sender, tTeam);
        _reflectFee(sender, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tTeam
        ) = _getValues(tAmount);
        tOwned[sender] = tOwned[sender] - tAmount;
        rOwned[sender] = rOwned[sender] - rAmount;
        rOwned[recipient] = rOwned[recipient] + rTransferAmount;
        _takeLiquidity(sender, tLiquidity);
        _takeTeamFee(sender, tTeam);
        _reflectFee(sender, rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}