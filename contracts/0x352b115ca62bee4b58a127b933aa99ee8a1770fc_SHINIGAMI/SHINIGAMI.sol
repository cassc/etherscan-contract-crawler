/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
contract ERC20Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "ERC20Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ERC20Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
contract SHINIGAMI is Context, IERC20, ERC20Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isMaxWalletExclude;
    mapping (address => bool) private _isBot;
	mapping(address => bool) public boughtEarly;
    address dead = 0x000000000000000000000000000000000000dEaD;
    address[] private _excluded;
    address payable public marketingAddress;
    address payable public giveAwayAddress;
    IUniswapV2Router02 private uniV2Router;
    address private uniV2Pair;
    bool inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true;
    bool private _initLaunch = true;
    bool private _antiSnipe = false;
    bool private _buyLimits = false;
    bool private _maxWalletOn = false;
    uint256 public tradingActiveBlock = 0;
    uint256 public earlyBuyPenaltyEnd;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e14 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _maxWalletSize = 2000000000000 * 10**18;
    uint256 private minTokensBeforeSwap;
    uint256 private tokensForLiquidityToSwap;
    uint256 private tokensForMarketingToSwap;
    uint256 private tokensForGiveAwayToSwap;

    string private constant _nomen = "SHINIGAMI";
    string private constant _symbo = "SHINIGAMI";
    uint8 private constant _decim = 18;

    //DEFAULT PLACE HOLDERS | OVERRIDDEN EACH TXN
    uint private _marTax = 6; // tax for marketing
    uint private _previousMarTax = _marTax;
    uint private _giveAwayTax = 2; // tax for GiveAways
    uint private _previousGiveAwayTax = _giveAwayTax;
    uint private _liqTax = 3; // tax for liquidity
    uint private _previousLiqTax = _liqTax;
    uint private _refTax = 0; //tax for reflections
    uint private _previousRefTax = _refTax;
    uint private _liqDiv = _marTax + _giveAwayTax + _liqTax;

    //MAIN TAX VALUES FOR BUY | CHANGEBLE WITH functon setBuyF()
    uint private _buyMarTax = 6;
    uint private _preBuyMarTax = _buyMarTax;
    uint private _buyGiveAwayTax = 2;
    uint private _preBuyGiveAwayTax = _buyGiveAwayTax;
    uint private _buyLiqTax = 3;
    uint private _preBuyLiqTax = _buyLiqTax;
    uint private _buyRefTax = 0;
    uint private _preBuyRefTax = _buyRefTax;

    //MAIN TAX VALUES FOR SELL | CHANGEBLE WITH functon setSellF()
    uint private _sellMarTax = 6;
    uint private _preSellMarTax = _sellMarTax;
    uint private _sellGiveAwayTax = 2;
    uint private _preSellGiveAwayTax = _sellGiveAwayTax;
    uint private _sellLiqTax = 3;
    uint private _preSellLiqTax = _sellLiqTax;
    uint private _sellRefTax = 0;
    uint private _preSellRefTax = _sellRefTax;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event UpdatedMarketingAddress(address marketing);
    event UpdatedGiveAwayAddress(address giveAwayAddress);
    event BoughtEarly(address indexed sniper);
    event RemovedSniper(address indexed notsniper);
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        marketingAddress = payable(0xAd32B5c3aaA19e6c42FDFF2832Cb47978a4b03CD);
        giveAwayAddress = payable(0x625Eee4A87C9743fB94D299eaAa68Fa918b5bf11);
        minTokensBeforeSwap = _tTotal.mul(5).div(10000);
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(marketingAddress)] = true;
        _isExcludedFromFee[address(giveAwayAddress)] = true;
        _isMaxWalletExclude[address(this)] = true;
        _isMaxWalletExclude[_msgSender()] = true;
        _isMaxWalletExclude[address(dead)] = true;
        _isMaxWalletExclude[address(marketingAddress)] = true;
        _isMaxWalletExclude[address(giveAwayAddress)] = true;
		addBot(0x41B0320bEb1563A048e2431c8C1cC155A0DFA967);
        addBot(0x91B305F0890Fd0534B66D8d479da6529C35A3eeC);
        addBot(0x7F5622afb5CEfbA39f96CA3b2814eCF0E383AAA4);
        addBot(0xfcf6a3d7eb8c62a5256a020e48f153c6D5Dd6909);
        addBot(0x74BC89a9e831ab5f33b90607Dd9eB5E01452A064);
        addBot(0x1F53592C3aA6b827C64C4a3174523182c52Ece84);
        addBot(0x460545C01c4246194C2e511F166D84bbC8a07608);
        addBot(0x2E5d67a1d15ccCF65152B3A8ec5315E73461fBcd);
        addBot(0xb5aF12B837aAf602298B3385640F61a0fF0F4E0d);
        addBot(0xEd3e444A30Bd440FBab5933dCCC652959DfCB5Ba);
        addBot(0xEC366bbA6266ac8960198075B14FC1D38ea7de88);
        addBot(0x10Bf6836600D7cFE1c06b145A8Ac774F8Ba91FDD);
        addBot(0x44ae54e28d082C98D53eF5593CE54bB231e565E7);
        addBot(0xa3e820006F8553d5AC9F64A2d2B581501eE24FcF);
		addBot(0x2228476AC5242e38d5864068B8c6aB61d6bA2222);
		addBot(0xcC7e3c4a8208172CA4c4aB8E1b8B4AE775Ebd5a8);
		addBot(0x5b3EE79BbBDb5B032eEAA65C689C119748a7192A);
		addBot(0x4ddA45d3E9BF453dc95fcD7c783Fe6ff9192d1BA);
        addBot(0x0160A15f0f13608F041376a59882Bdd44909b59E);
        addBot(0x859E94401bA176A7ab9AAFE5f5dEb52f8D2C76Dc);
        addBot(0xD49e21e8380220252D6138790d403af81ADf11F5);
        addBot(0xAF00960b562769b5826eFD8D37F2016b5b154FF7);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    receive() external payable {}
    function name() public pure override returns (string memory) {
        return _nomen;
    }
    function symbol() public pure override returns (string memory) {
        return _symbo;
    }
    function decimals() public pure override returns (uint8) {
        return _decim;
    }
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
    function transferFrom(address sender,address recipient,uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),
        _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amt must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amt must be less than tot refl");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function _getValues(uint256 tAmount) private view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }
    function _getTValues(uint256 tAmount)private view returns (uint256,uint256,uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }
    function _getRValues(uint256 tAmount,uint256 tFee,uint256 tLiquidity,uint256 currentRate) private pure returns (uint256,uint256,uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    function _takeLiquidity(uint256 tLiquidity) private {
        tokensForMarketingToSwap += tLiquidity * _marTax / _liqDiv;
		tokensForLiquidityToSwap += tLiquidity * _liqTax / _liqDiv;
        tokensForGiveAwayToSwap += tLiquidity * _giveAwayTax / _liqDiv;
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_refTax).div(10**2);
    }
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marTax + _giveAwayTax + _liqTax).div(10**2);
    }
    function removeAllFee() private {
        if (_refTax == 0 && _liqTax == 0 && _marTax == 0 && _giveAwayTax == 0) return;

        _previousRefTax = _refTax;
        _previousLiqTax = _liqTax;
        _previousMarTax = _marTax;
        _previousGiveAwayTax = _giveAwayTax;

        _refTax = 0;
        _liqTax = 0;
        _marTax = 0;
        _giveAwayTax = 0;
    }
    function restoreAllFee() private {
        _refTax = _previousRefTax;
        _liqTax = _previousLiqTax;
        _marTax = _previousMarTax;
        _giveAwayTax = _previousGiveAwayTax;
    }
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
    function _approve(address owner,address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from zero address");
        require(to != address(0), "ERC20: transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
		require(!_isBot[from]);
		require(!boughtEarly[from] || earlyBuyPenaltyEnd <= block.timestamp, "Snipers can't transfer tokens to sell cheaper DM a Mod.");
		if (_maxWalletOn == true && ! _isMaxWalletExclude[to]) {
            require(balanceOf(to) + amount <= _maxWalletSize, "Max amount of tokens for wallet reached");
        }
        if (_buyLimits == true && from == uniV2Pair) {
			require(amount <= 500000000000 * 10**18, "Limits are in place, please lower buying amount");
		}
        if(_initLaunch == true) {
            IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            uniV2Router = _uniV2Router;
            uniV2Pair = IUniswapV2Factory(_uniV2Router.factory()).getPair(address(this), _uniV2Router.WETH());
            tradingActiveBlock = block.number;
            earlyBuyPenaltyEnd = block.timestamp + 72 hours;
            _isMaxWalletExclude[address(uniV2Pair)] = true;
            _isMaxWalletExclude[address(uniV2Router)] = true;
            _buyLimits = true;
            _maxWalletOn = true;
            _antiSnipe = true;
            _initLaunch = false;
        }
        if(_antiSnipe == true && from != owner() && to != uniV2Pair) {
            for (uint x = 0; x < 2; x++) {
                if(block.number == tradingActiveBlock + x) {
                    boughtEarly[to] = true;
                    emit BoughtEarly(to);
                }
                if(x >= 2){
                    _antiSnipe = false;
                }
            }
		}
        if (to == uniV2Pair) {
            _marTax = _sellMarTax;
            _giveAwayTax = _sellGiveAwayTax;
            _liqTax = _sellLiqTax;
            _refTax = _sellRefTax;
        } else if (from == uniV2Pair) {
            _marTax = _buyMarTax;
            _giveAwayTax = _buyGiveAwayTax;
            _liqTax = _buyLiqTax;
            _refTax = _buyRefTax;
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        if (!inSwapAndLiquify && to == uniV2Pair && swapAndLiquifyEnabled) {
            if (contractTokenBalance >= minTokensBeforeSwap) {
				swapTokens();
            }
        }
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
		if(boughtEarly[from] && earlyBuyPenaltyEnd > block.timestamp){
                    _liqTax = 0;
                    _marTax = 95;
                    _giveAwayTax = 0;
                    _refTax = 0;
                }
        _tokenTransfer(from, to, amount, takeFee);
    }
    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            dead, // Burn address
            block.timestamp.add(300)
        );
    }
	function addBot(address _user) public onlyOwner {
        require(_user != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        require(!_isBot[_user]);
        _isBot[_user] = true;
    }
	function removeBot(address _user) public onlyOwner {
        require(_isBot[_user]);
        _isBot[_user] = false;
    }
	function removeSniper(address account) external onlyOwner {
        boughtEarly[account] = false;
        emit RemovedSniper(account);
    }
	function swapTokens() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidityToSwap + tokensForMarketingToSwap + tokensForGiveAwayToSwap;
        uint256 tokensForLiquidity = tokensForLiquidityToSwap.div(2); //Halve the amount of liquidity tokens
        uint256 amountToSwapForETH = contractBalance.sub(tokensForLiquidity);
        uint256 initialETHBalance = address(this).balance;
        swapTokensForETH(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(tokensForMarketingToSwap).div(totalTokensToSwap);
        uint256 ethForGiveAway = ethBalance.mul(tokensForGiveAwayToSwap).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance.sub(ethForMarketing).sub(ethForGiveAway);
        tokensForLiquidityToSwap = 0;
        tokensForMarketingToSwap = 0;
        tokensForGiveAwayToSwap = 0;
        (bool success,) = address(marketingAddress).call{value: ethForMarketing}("");
        (success,) = address(giveAwayAddress).call{value: ethForGiveAway}("");
        addLiquidity(tokensForLiquidity, ethForLiquidity);
        emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        //If any eth left over transfer out of contract as to not get stuck
        if(address(this).balance > 0 * 10**18){
            (success,) = address(marketingAddress).call{value: address(this).balance}("");
        }
    }
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();
        _approve(address(this), address(uniV2Router), tokenAmount);
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp.add(300)
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniV2Router), tokenAmount);
        uniV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            dead,
            block.timestamp.add(300)
        );
    }
    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        require(_marketingAddress != address(0));
        _isExcludedFromFee[marketingAddress] = false;
        marketingAddress = payable(_marketingAddress);
        _isExcludedFromFee[marketingAddress] = true;
        emit UpdatedMarketingAddress(_marketingAddress);
    }
    function setGiveAwayAddress(address _giveAwayAddress) public onlyOwner {
        require(_giveAwayAddress != address(0));
        giveAwayAddress = payable(_giveAwayAddress);
        emit UpdatedGiveAwayAddress(_giveAwayAddress);
    }
	function StartLaunchInit() external onlyOwner {
		_initLaunch = true;
	}
	function StopLaunchInit() external onlyOwner {
		_initLaunch = false;
	}
    function TaxSwapEnable() external onlyOwner {
        swapAndLiquifyEnabled = true;
    }
    function TaxSwapDisable() external onlyOwner {
        swapAndLiquifyEnabled = false;
    }
    function ResumeLimits() external onlyOwner {
        _buyLimits = true;
    }
    function RemoveLimits() external onlyOwner {
        _buyLimits = false;
    }
    function MaxWalletOn() external onlyOwner {
        _maxWalletOn = true;
    }
    function MaxWalletOff() external onlyOwner {
        _maxWalletOn = false;
    }
    function setBuyF(uint buyMarTax, uint buyGiveAwayTax, uint buyLiqTax, uint buyRefTax) external onlyOwner {
        _buyMarTax = buyMarTax;
        _buyGiveAwayTax = buyGiveAwayTax;
        _buyLiqTax = buyLiqTax;
        _buyRefTax = buyRefTax;
    }
    function setSellF(uint sellMarTax, uint sellGiveAwayTax, uint sellLiqTax, uint sellRefTax) external onlyOwner {
        _sellMarTax = sellMarTax;
        _sellGiveAwayTax = sellGiveAwayTax;
        _sellLiqTax = sellLiqTax;
        _sellRefTax = sellRefTax;
    }
    function startAntiSniper() external onlyOwner {
        _antiSnipe = true;
    }
    function stopAntiSniper() external onlyOwner {
        _antiSnipe = false;
    }
    function HappyHour() external onlyOwner {
		_preBuyMarTax = _buyMarTax;
		_preBuyGiveAwayTax = _buyGiveAwayTax;
		_preBuyLiqTax = _buyLiqTax;
		_preBuyRefTax = _buyRefTax;
		_preSellMarTax = _sellMarTax;
		_preSellGiveAwayTax = _sellGiveAwayTax;
		_preSellLiqTax = _sellLiqTax;
		_preSellRefTax = _sellRefTax;
        _buyMarTax = 0;
        _buyGiveAwayTax = 0;
        _buyLiqTax = 0;
        _buyRefTax = 0;
        _sellMarTax = 0;
        _sellGiveAwayTax = 0;
        _sellLiqTax = 0;
        _sellRefTax = 0;

    }
    function HappyHourOff() external onlyOwner {
		_buyMarTax = _preBuyMarTax;
		_buyGiveAwayTax = _preBuyGiveAwayTax;
		_buyLiqTax = _preBuyLiqTax;
		_buyRefTax = _preBuyRefTax;
		_sellMarTax = _preSellMarTax;
		_sellGiveAwayTax = _preSellGiveAwayTax;
		_sellLiqTax = _preSellLiqTax;
		_sellRefTax = _preSellRefTax;
	}
    function _tokenTransfer(address sender,address recipient,uint256 amount,bool takeFee) private {
        if (!takeFee) removeAllFee();
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if (!takeFee) restoreAllFee();
    }
    function _transferStandard(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender,address recipient,uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _tokenTransferNoFee(address sender,address recipient,uint256 amount) private {
        _rOwned[sender] = _rOwned[sender].sub(amount);
        _rOwned[recipient] = _rOwned[recipient].add(amount);

        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(amount);
        }
        emit Transfer(sender, recipient, amount);
    }
}