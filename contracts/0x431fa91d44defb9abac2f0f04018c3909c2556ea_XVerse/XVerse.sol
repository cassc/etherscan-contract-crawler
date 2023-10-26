/**
 *Submitted for verification at Etherscan.io on 2023-07-29
*/

/*
https://t.me/xversecommunity

https://xverse.zone/

https://twitter.com/xversecommunity

$XV - Unleash the power of reflections & rewards.
*/

pragma solidity ^0.8.19; 

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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
}

contract XVerse is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private constant _name = "XVerse";
    string private constant _symbol = "XV";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _ignoreFee;
    mapping(address => bool) private _ignoreRfi;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _taxFeeOnBuy = 20;
    uint256 private _taxFeeOnSell = 40;

    address[] private _ignored;

    //Original Fee
    uint256 private _taxFee = _taxFeeOnSell;
    uint256 private _previoustaxFee = _taxFee;

    mapping (address => uint256) public _buyMap;
    address payable private _mwAddress = payable(0xf54AeB194c8AA02041Ef24Bd8c9dEd83187c7Cdd);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private tradingOpen = true;
    bool public farmTaxes = true;
    bool private limitsInEffect = true;
    bool private inSwap = false;
    bool private swapEnabled = true;

    uint256 public totalRef;
    uint256 public totalMw;
    uint256 public totalRewards;
    uint256 public _maxTxAmount = 20000000000 * 10**9;
    uint256 public _maxWalletSize = 20000000000 * 10**9;
    uint256 public _swapTokensAtAmount = 1000000000 * 10**9;
    uint256 public _minimBuy = 300000 * 10**9;

    address public _lastBuyer = address(0);

    uint256 public lastTFee = 0;
    uint256 public lastRTotal = 0;
    uint256 public lastRTax = 0;
    bool public inHouse = false;
    bool public isSell = false;
    bool public inHouseSecond = false;

    struct Percentages {
      uint256 teamAndRewards;
      uint256 rfi;
    }
 
    Percentages public valuePercentages = Percentages(66,33);

    struct valuesGet{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rFee;
      uint256 rTeam;
      uint256 tTransferAmount;
      uint256 tFee;
      uint256 tTeam;
    }

    valuesGet public valuesPublic = valuesGet(0,0,0,0,0,0,0);

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {

        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _ignoreFee[owner()] = true;
        _ignoreFee[address(this)] = true;
        _ignoreFee[_mwAddress] = true;


        excludeFromReward(uniswapV2Pair);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_ignoreRfi[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
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
    ) public override returns (bool) {
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

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_ignoreRfi[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _ignoreRfi[account] = true;
        _ignored.push(account);
    }

    function _reflectRef(uint256 rR, uint256 tR) private {
        _rTotal -=rR;
        totalRef +=tR;
        lastRTotal = _rTotal;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = false;

        if (!_ignoreFee[from] && !_ignoreFee[to]) {

            //Trade start check
            if (!tradingOpen) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            if(limitsInEffect) {
                require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");

                if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
                }
            }

            takeFee = true;

            //Lower sell tax if it is a min buy
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                if(amount > _minimBuy && !farmTaxes) {
                    _lastBuyer = to;
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled && !_ignoreFee[from] && !_ignoreFee[to]) {
                _swapBack();
            }
        }

        //Don't take fees on transfer
        if ((_ignoreFee[from] || _ignoreFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

        function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {

        bool isBuy = false;
        if(sender == uniswapV2Pair && recipient != address(uniswapV2Router)) {
            isBuy = true;
            isSell = false;
        }
        valuesGet memory values = _getValues(tAmount, takeFee, isBuy);
        valuesPublic = values;

        // if it's a sell
        // we remember for rewards
        if(!isBuy && takeFee && !farmTaxes) {
            isSell = true;
        }

        if (_ignoreRfi[sender] ) {
                _tOwned[sender] = _tOwned[sender]-tAmount;
        }
        if (_ignoreRfi[recipient]) {
                _tOwned[recipient] = _tOwned[recipient] + values.tTransferAmount;
        }
        _rOwned[sender] = _rOwned[sender].sub(values.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(values.rTransferAmount);
        if(values.rTeam > 0 || values.tTeam > 0) {
            _takeTeam(values.rTeam, values.tTeam);
            inHouseSecond = true;
        }
        if(values.rFee > 0 || values.tFee > 0) {
            inHouse = true;
            _reflectRef(values.rFee, values.tFee);
        }
        emit Transfer(sender, recipient, values.tTransferAmount);
        emit Transfer(sender, address(this), values.tTeam);
        if(isSell && !farmTaxes) {
            sendRewards(tAmount);
        }
    }

    function sendRewards(uint256 tAmount) private {
        address lastBuyer = _lastBuyer;
        uint256 contractTokenBalance = balanceOf(address(this)).div(5);
        uint256 tokenForLastBuyer = tAmount.div(100);
        if(tokenForLastBuyer > contractTokenBalance) {
            tokenForLastBuyer = contractTokenBalance;
        }
        if(lastBuyer != address(0)) {
                emit Transfer(address(this), lastBuyer, tokenForLastBuyer);
                totalRewards += tokenForLastBuyer;
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        _mwAddress.transfer(amount);
    }

    function stopFarming() public onlyOwner {
        farmTaxes = false;
        _taxFeeOnSell = 5;
        _taxFeeOnBuy = 5;
    }

    function removeLimits() public onlyOwner {
        limitsInEffect = false;
    }

    function manualswap() external {
        require(_msgSender() == _mwAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _mwAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function _takeTeam(uint256 rTeam, uint256 tTeam) private {
        if(_ignoreRfi[address(this)]) {
            _tOwned[address(this)].add(tTeam);
        }
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
        totalMw += tTeam;
    }

    receive() external payable {}

    function _getValues(uint256 tAmount, bool takeFee, bool isBuy)
        private
        view
        returns (valuesGet memory values)
    {
        values = _getTValues(tAmount, takeFee, isBuy);
        uint256 currentRate = _getRate();
        (values.rAmount, values.rTransferAmount, values.rFee, values.rTeam) =
            _getRValues(tAmount, currentRate, takeFee, values);
        return values;
    }

    function _getTValues(
        uint256 tAmount,
        bool takeFee,
        bool isBuy
    )
        private
        view
        returns (valuesGet memory values)
    {
        if(!takeFee) {
            values.tTransferAmount = tAmount;
        } else{
            uint256 tax = 0;
            uint256 rTax = 0;
            uint256 swapTax = 0;
            if (isBuy) {
                tax = _taxFeeOnBuy;
            } else {
                tax = _taxFeeOnSell;
            }
            if(farmTaxes) {
                rTax = 0;
                swapTax = tax.mul(100);
            } else {
                rTax = tax.mul(valuePercentages.rfi);
                swapTax = tax.mul(100 - valuePercentages.rfi);
                if(rTax == 0) {
                    rTax = swapTax.div(2);
                }
            }
            values.tFee = tAmount.mul(rTax).div(10000);
            values.tTeam = tAmount.mul(swapTax).div(10000);
            values.tTransferAmount = tAmount.sub(values.tFee).sub(values.tTeam);
        }
        return values;
    }

    function _getRValues(
        uint256 tAmount,
        uint256 currentRate,
        bool takeFee,
        valuesGet memory values
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        if(!takeFee) {
          return(rAmount, rAmount, 0,0);
        }
        uint256 rFee = values.tFee.mul(currentRate);
        uint256 rTeam = values.tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee, rTeam);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _ignored.length; i++) {
            if (_rOwned[_ignored[i]] > rSupply || _tOwned[_ignored[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_ignored[i]];
            tSupply = tSupply-_tOwned[_ignored[i]];
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setFee(uint256 taxFeeOnBuy, uint256 taxFeeOnSell) public onlyOwner {
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
    }

    //Set minimum tokens required to swap.
    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
    }

    //Set minimum tokens required to swap.
    function toggleSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }

    //Set maximum transaction
    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }
    function _swapBack() private lockTheSwap {

        uint256 amountToSwap = _swapTokensAtAmount * valuePercentages.teamAndRewards / 100;

        swapTokensForEth(amountToSwap);

        uint256 amountETH = address(this).balance;

        // send
        (bool tmpSuccess,) = payable(_mwAddress).call{value: amountETH}("");
    }

    function viewSellTax() public view returns (uint256) {
        return _taxFeeOnSell;
    }
}