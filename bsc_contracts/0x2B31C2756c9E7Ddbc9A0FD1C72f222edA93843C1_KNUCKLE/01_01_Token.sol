// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.17;

interface Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface Router {
    function WETH() external view returns (address);

    function factory() external view returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IBEP20 {
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

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
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

contract KNUCKLE is Context, IBEP20, Ownable {
    using Address for address payable;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;

    address[] private _excluded;

    bool public tradingEnabled;

    uint8 private constant _decimals = 18;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 1e9 * 10 ** _decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    address public buyBackWallet = 0x811FCC87AF0E8D7adF6caE825bb1C80A6fbda760;
    address public marketingWallet = 0x7221F95889eb6d8714227a32d50A2CEaA8C0341B;

    string private constant _name = "Knuckles Inu";
    string private constant _symbol = "KNUCKLES";

    struct Taxes {
        uint256 rfi;
        uint256 marketing;
        uint256 buyback;
    }

    Taxes public buyTaxes = Taxes(2000, 4000, 2000);
    Taxes public sellTaxes = Taxes(2000, 4000, 2000);
    Taxes public transferTaxes = Taxes(0, 0, 1000);

    uint256 totalMarketingTax = 8000;
    uint256 totalBuybackTax = 4000;

    struct TotFeesPaidStruct {
        uint256 rfi;
        uint256 marketing;
        uint256 buyback;
    }

    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 tTransferAmount;
        uint256 rRfi;
        uint256 tRfi;
        uint256 tBuyback;
        uint256 rBuyback;
        uint256 rMarketing;
        uint256 tMarketing;
    }

    event FeesChanged();
    event UpdatedRouter(address oldRouter, address newRouter);
    event Buyback(uint256 amount);
    event Reflected(uint256 amount);

    bool locked;
    modifier LockSwap() {
        locked = true;
        _;
        locked = false;
    }

    address public pair;
    Router public swapRouter;

    constructor() {
        swapRouter = Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = Factory(swapRouter.factory()).createPair(
            address(this),
            swapRouter.WETH()
        );

        excludeFromReward(buyBackWallet);
        excludeFromReward(address(this));
        excludeFromReward(address(pair));

        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[0xe9Caf8681838FADf2A8545160206c436aCADE82B] = true;

        transferOwnership(0xe9Caf8681838FADf2A8545160206c436aCADE82B);

        _rOwned[owner()] = _rTotal;
        emit Transfer(address(0), owner(), _tTotal);
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "BEP20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
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
    ) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "BEP20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(
        uint256 tAmount,
        bool deductTransferRfi
    ) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(
                tAmount,
                true,
                address(0),
                address(0)
            );
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(
                tAmount,
                true,
                address(0),
                address(0)
            );
            return s.rTransferAmount;
        }
    }

    function EnableTrading() external onlyOwner {
        require(!tradingEnabled, "Cannot re-enable trading");
        tradingEnabled = true;
    }

    function updateBuyTaxes(
        uint refTax,
        uint256 marketing,
        uint256 buybackTax
    ) public onlyOwner {
        require(
            refTax + buybackTax + marketing <= 12500,
            "Can not set sum of reflection and buyback taxes more than 12.5%"
        );
        buyTaxes.buyback = refTax;
        buyTaxes.marketing = marketing;
        buyTaxes.rfi = refTax;
        totalMarketingTax =
            marketing +
            sellTaxes.marketing +
            transferTaxes.marketing;
        totalBuybackTax =
            buybackTax +
            sellTaxes.buyback +
            transferTaxes.buyback;
    }

    function updateSellTaxes(
        uint refTax,
        uint256 marketing,
        uint256 buybackTax
    ) public onlyOwner {
        require(
            refTax + buybackTax + marketing <= 12500,
            "Can not set sum of reflection and buyback taxes more than 12.5%"
        );
        sellTaxes.buyback = refTax;
        sellTaxes.marketing = marketing;
        sellTaxes.rfi = refTax;
        totalMarketingTax =
            marketing +
            buyTaxes.marketing +
            transferTaxes.marketing;
        totalBuybackTax = buybackTax + buyTaxes.buyback + transferTaxes.buyback;
    }

    function updateTransferTaxes(
        uint refTax,
        uint256 marketing,
        uint256 buybackTax
    ) public onlyOwner {
        require(
            refTax + buybackTax + marketing <= 5000,
            "Can not set sum of reflection and buyback taxes more than 5%"
        );
        transferTaxes.buyback = refTax;
        transferTaxes.marketing = marketing;
        transferTaxes.rfi = refTax;
        totalMarketingTax =
            marketing +
            buyTaxes.marketing +
            sellTaxes.marketing;
        totalBuybackTax = buybackTax + buyTaxes.buyback + sellTaxes.buyback;
    }

    function tokenFromReflection(
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -= rRfi;
        totFeesPaid.rfi += tRfi;
        emit Reflected(tRfi);
    }

    function _takeBuyback(
        address from,
        uint256 rBuyback,
        uint256 tBuyback
    ) private {
        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] += tBuyback;
        }

        _rOwned[address(this)] += rBuyback;
        emit Transfer(from, address(this), tBuyback);
    }

    function _takeMarketing(
        address from,
        uint256 rMarketing,
        uint256 tMarketing
    ) private {
        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] += tMarketing;
        }

        _rOwned[address(this)] += rMarketing;
        emit Transfer(from, address(this), tMarketing);
    }

    function _getValues(
        uint256 tAmount,
        bool takeFee,
        address from,
        address to
    ) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee, from, to);
        (
            to_return.rAmount,
            to_return.rTransferAmount,
            to_return.rRfi,
            to_return.rBuyback,
            to_return.rMarketing
        ) = _getRValues1(to_return, tAmount, takeFee, _getRate());

        return to_return;
    }

    function _getTValues(
        uint256 tAmount,
        bool takeFee,
        address from,
        address to
    ) private view returns (valuesFromGetValues memory s) {
        if (!takeFee) {
            s.tTransferAmount = tAmount;
            return s;
        }

        Taxes memory temp = transferTaxes;
        if (from == pair) {
            temp = buyTaxes;
        } else if (to == pair) {
            temp = sellTaxes;
        }

        s.tRfi = (tAmount * temp.rfi) / 100000;
        s.tBuyback = (tAmount * temp.buyback) / 100000;
        s.tMarketing = (tAmount * temp.marketing) / 100000;
        s.tTransferAmount = tAmount - s.tRfi - s.tBuyback - s.tMarketing;
        return s;
    }

    function _getRValues1(
        valuesFromGetValues memory s,
        uint256 tAmount,
        bool takeFee,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rRfi,
            uint256 rBuyback,
            uint256 rMarketing
        )
    {
        rAmount = tAmount * currentRate;

        if (!takeFee) {
            return (rAmount, rAmount, 0, 0, 0);
        }

        rRfi = s.tRfi * currentRate;
        rBuyback = s.tBuyback * currentRate;
        rMarketing = s.tMarketing * currentRate;

        rTransferAmount = rAmount - rRfi - rBuyback - rMarketing;
        return (rAmount, rTransferAmount, rRfi, rBuyback, rMarketing);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(tradingEnabled, "Trading not active");
        }

        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) takeFee = false;

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        if (takeFee && sender != pair && !locked && sender != address(this)) {
            InternalSwap();
        }

        valuesFromGetValues memory s = _getValues(
            tAmount,
            takeFee,
            sender,
            recipient
        );

        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender] - tAmount;
        }

        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient] + s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender] - s.rAmount;
        _rOwned[recipient] = _rOwned[recipient] + s.rTransferAmount;

        if (s.rRfi > 0 || s.tRfi > 0) _reflectRfi(s.rRfi, s.tRfi);
        if (s.rMarketing > 0 || s.tMarketing > 0)
            _takeMarketing(sender, s.rMarketing, s.tMarketing);
        if (s.rBuyback > 0 || s.tBuyback > 0) {
            _takeBuyback(sender, s.rBuyback, s.tBuyback);
        }

        emit Transfer(sender, recipient, s.tTransferAmount);
    }

    function InternalSwap() internal LockSwap {
        if (balanceOf(address(this)) == 0) return;

        _approve(address(this), address(swapRouter), ~uint256(0));

        address[] memory Path = new address[](2);
        Path[0] = address(this);
        Path[1] = address(swapRouter.WETH());

        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            balanceOf(address(this)),
            0,
            Path,
            address(this),
            block.timestamp
        );
        uint256 ethReceived = address(this).balance;
        uint256 totalShares = totalMarketingTax + totalBuybackTax;

        if (totalShares == 0) {
            //send the bnb to owner
            (bool success, ) = payable(owner()).call{value: ethReceived}("");
            return;
        }

        uint256 marketingShare = (ethReceived * totalMarketingTax) /
            totalShares;
        uint256 buybackShare = ethReceived - marketingShare;

        if (marketingShare > 0) {
            (bool success, ) = payable(marketingWallet).call{
                value: marketingShare
            }("");
        }

        if (buybackShare > 0) {
            (bool success, ) = payable(buyBackWallet).call{value: buybackShare}(
                ""
            );
        }
    }

    function bulkExcludeFee(
        address[] memory accounts,
        bool state
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = state;
        }
    }

    function rescueBNB(uint256 weiAmount) external onlyOwner {
        payable(msg.sender).transfer(weiAmount);
    }

    function rescueAnyBEP20Tokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        IBEP20(_tokenAddr).transfer(_to, _amount);
    }

    receive() external payable {}
}