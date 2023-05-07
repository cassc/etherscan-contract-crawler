/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function feeTo() external view returns (address);
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function totalSupply() external view returns (uint);

    function kLast() external view returns (uint);

    function sync() external;
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!o");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "n0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

abstract contract AbsToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _tTotal;

    mapping(address => bool) public _feeWhiteList;

    ISwapRouter public immutable _swapRouter;
    address public immutable _usdt;
    mapping(address => bool) public _swapPairList;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);

    uint256 public _buyFundFee = 500;

    uint256 public _sellDestroyFee = 1000;

    uint256 public startTradeBlock;
    uint256 public startAddLPBlock;
    address public immutable _mainPair;

    mapping(uint256 => uint256) public dayPrice;
    uint256 public _addSellFeePriceRate = 8000;
    uint256 public _maxSellFee = 3300;

    uint256 public _rewardBuyCondition;
    uint256 public _rewardCondition;
    uint256 public _rewardLen = 10;
    uint256 public _minTotal;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (
        address RouterAddress, address USDTAddress,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply,
        address ReceiveAddress, address FundAddress, uint256 MinTotal
    ){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        _swapRouter = ISwapRouter(RouterAddress);

        _usdt = USDTAddress;
        _allowances[address(this)][address(_swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(_swapRouter.factory());
        address mainPair = swapFactory.createPair(address(this), _usdt);
        _swapPairList[mainPair] = true;
        _mainPair = mainPair;

        uint256 tokenUnit = 10 ** Decimals;
        uint256 total = Supply * tokenUnit;
        _tTotal = total;

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);

        fundAddress = FundAddress;

        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(_swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[address(0x000000000000000000000000000000000000dEaD)] = true;

        _rewardBuyCondition = 100 * 10 ** IERC20(USDTAddress).decimals();
        _rewardCondition = 10 * tokenUnit;
        _minTotal = MinTotal * tokenUnit;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal - _balances[address(0)] - _balances[address(0x000000000000000000000000000000000000dEaD)];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 balance = balanceOf(from);
        require(balance >= amount, "BNE");

        bool takeFee;
        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            takeFee = true;
            uint256 maxSellAmount = balance * 99999 / 100000;
            if (amount > maxSellAmount) {
                amount = maxSellAmount;
            }
        }

        uint256 day = today();
        if (0 == dayPrice[day]) {
            dayPrice[day] = tokenPrice();
        }


        bool isAddLP;
        bool isRemoveLP;
        if (to == _mainPair) {
            uint256 addLPLiquidity = _isAddLiquidity(amount);
            if (addLPLiquidity > 0) {
                isAddLP = true;
            }
        } else if (from == _mainPair) {
            uint256 removeLPLiquidity = _isRemoveLiquidity(amount);
            if (removeLPLiquidity > 0) {
                isRemoveLP = true;
            }
        }

        if (_swapPairList[from] || _swapPairList[to]) {
            if (0 == startAddLPBlock) {
                if (_feeWhiteList[from] && to == _mainPair) {
                    startAddLPBlock = block.number;
                }
            }

            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                if (0 == startTradeBlock) {
                    require(0 < startAddLPBlock && isAddLP);
                } else {
                    if (!isAddLP && block.number < startTradeBlock + 3) {
                        _funTransfer(from, to, amount, 99);
                        return;
                    }
                }
            }
        }

        if (isAddLP) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee, isRemoveLP);
    }

    function _funTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 fee
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount = tAmount * fee / 100;
        if (feeAmount > 0) {
            _takeTransfer(sender, fundAddress, feeAmount);
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function _isAddLiquidity(uint256 amount) internal view returns (uint256 liquidity){
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        uint256 amountOther;
        if (rOther > 0 && rThis > 0) {
            amountOther = amount * rOther / rThis;
        }
        //isAddLP
        if (balanceOther >= rOther + amountOther) {
            (liquidity,) = calLiquidity(balanceOther, amount, rOther, rThis);
        }
    }

    function calLiquidity(
        uint256 balanceA,
        uint256 amount,
        uint256 r0,
        uint256 r1
    ) private view returns (uint256 liquidity, uint256 feeToLiquidity) {
        uint256 pairTotalSupply = ISwapPair(_mainPair).totalSupply();
        address feeTo = ISwapFactory(_swapRouter.factory()).feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = ISwapPair(_mainPair).kLast();
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(r0 * r1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = pairTotalSupply * (rootK - rootKLast) * 8;
                    uint256 denominator = rootK * 17 + (rootKLast * 8);
                    feeToLiquidity = numerator / denominator;
                    if (feeToLiquidity > 0) pairTotalSupply += feeToLiquidity;
                }
            }
        }
        uint256 amount0 = balanceA - r0;
        if (pairTotalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount) - 1000;
        } else {
            liquidity = Math.min(
                (amount0 * pairTotalSupply) / r0,
                (amount * pairTotalSupply) / r1
            );
        }
    }

    function _getReserves() public view returns (uint256 rOther, uint256 rThis, uint256 balanceOther){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1,) = mainPair.getReserves();

        address tokenOther = _usdt;
        if (tokenOther < address(this)) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }

        balanceOther = IERC20(tokenOther).balanceOf(_mainPair);
    }

    function _isRemoveLiquidity(uint256 amount) internal view returns (uint256 liquidity){
        (uint256 rOther, , uint256 balanceOther) = _getReserves();
        //isRemoveLP
        if (balanceOther <= rOther) {
            liquidity = (amount * ISwapPair(_mainPair).totalSupply()) /
            (balanceOf(_mainPair) - amount);
        }
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isRemoveLP
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;
        if (takeFee) {
            if (_swapPairList[sender]) {//Buy
                feeAmount = tAmount * _buyFundFee / 10000;
                _takeTransfer(sender, fundAddress, feeAmount);
                if (!isRemoveLP) {
                    uint256 rewardCondition = _rewardCondition;
                    uint256 thisTokenBalance = balanceOf(address(this));
                    if (thisTokenBalance >= rewardCondition) {
                        uint256 addAllSellFee = getAddSellFee();
                        if (addAllSellFee > 0) {
                            address[] memory path = new address[](2);
                            path[0] = _usdt;
                            path[1] = address(this);
                            uint[] memory amounts = _swapRouter.getAmountsOut(_rewardBuyCondition, path);
                            uint256 rewardBuyCondition = amounts[amounts.length - 1];
                            if (tAmount >= rewardBuyCondition) {
                                _tokenTransfer(address(this), recipient, thisTokenBalance / _rewardLen, false, false);
                            }
                        }
                    }
                }
            } else if (_swapPairList[recipient]) {//Sell
                uint256 destroyFeeAmount = tAmount * _sellDestroyFee / 10000;
                uint256 currentTotal = totalSupply();
                uint256 maxDestroyAmount;
                uint256 minTotal = _minTotal;
                if (currentTotal > minTotal) {
                    maxDestroyAmount = currentTotal - minTotal;
                }
                if (destroyFeeAmount > maxDestroyAmount) {
                    destroyFeeAmount = maxDestroyAmount;
                }
                if (destroyFeeAmount > 0) {
                    feeAmount += destroyFeeAmount;
                    _takeTransfer(sender, address(0x000000000000000000000000000000000000dEaD), destroyFeeAmount);
                }

                uint256 addAllSellFee = getAddSellFee();
                uint256 maxFee = _maxSellFee;
                if (addAllSellFee > maxFee) {
                    addAllSellFee = maxFee;
                }
                uint256 addAllSellFeeAmount = tAmount * addAllSellFee / 10000;
                uint256 addSellFeeAmount;
                if (addAllSellFeeAmount > destroyFeeAmount) {
                    addSellFeeAmount = addAllSellFeeAmount - destroyFeeAmount;
                    feeAmount += addSellFeeAmount;
                    _takeTransfer(sender, address(this), addSellFeeAmount);
                }
            }
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function getAddSellFee() public view returns (uint256){
        uint256 todayPrice = dayPrice[today()];
        uint256 price = tokenPrice();
        uint256 priceRate = price * 10000 / todayPrice;
        uint256 sellFee;
        uint256 addSellFeePriceRate = _addSellFeePriceRate;
        if (addSellFeePriceRate >= priceRate) {
            sellFee = 10000 - priceRate;
        }
        return sellFee;
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    modifier onlyWhiteList() {
        address msgSender = msg.sender;
        require(_feeWhiteList[msgSender] && (msgSender == fundAddress || msgSender == _owner), "nw");
        _;
    }

    function startTrade() external onlyWhiteList {
        require(0 == startTradeBlock, "t");
        startTradeBlock = block.number;
    }

    function setFundAddress(address addr) external onlyWhiteList {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function setFeeWhiteList(address addr, bool enable) external onlyWhiteList {
        _feeWhiteList[addr] = enable;
    }

    function batchSetFeeWhiteList(address [] memory addr, bool enable) external onlyWhiteList {
        for (uint i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }

    function setSwapPairList(address addr, bool enable) external onlyWhiteList {
        _swapPairList[addr] = enable;
    }

    function claimBalance() external {
        payable(fundAddress).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            IERC20(token).transfer(fundAddress, amount);
        }
    }

    function setDayPrice(uint256 day, uint256 price) external onlyWhiteList {
        dayPrice[day] = price;
    }

    function setAddFeePriceRate(uint256 rate) external onlyOwner {
        _addSellFeePriceRate = rate;
    }

    uint256 public _dailyDuration = 12 hours;

    function setDailyDuration(uint256 d) external onlyOwner {
        _dailyDuration = d;
    }

    function today() public view returns (uint256){
        return block.timestamp / _dailyDuration;
    }

    function tokenPrice() public view returns (uint256){
        ISwapPair swapPair = ISwapPair(_mainPair);
        (uint256 reverse0,uint256 reverse1,) = swapPair.getReserves();
        uint256 otherReverse;
        uint256 tokenReverse;
        if (_usdt < address(this)) {
            otherReverse = reverse0;
            tokenReverse = reverse1;
        } else {
            otherReverse = reverse1;
            tokenReverse = reverse0;
        }
        if (0 == tokenReverse) {
            return 0;
        }
        return 10 ** _decimals * otherReverse / tokenReverse;
    }

    function setSellDestroyFee(uint256 f) external onlyOwner {
        _sellDestroyFee = f;
    }

    function setBuyFundFee(uint256 f) external onlyOwner {
        _buyFundFee = f;
    }

    function setAddSellFeePriceRate(uint256 r) external onlyOwner {
        _addSellFeePriceRate = r;
    }

    function setMaxSellFee(uint256 f) external onlyOwner {
        _maxSellFee = f;
    }

    function setRewardLen(uint256 l) external onlyWhiteList {
        _rewardLen = l;
    }

    function setRewardCondition(uint256 c) external onlyWhiteList {
        _rewardCondition = c;
    }

    function setRewardBuyCondition(uint256 c) external onlyWhiteList {
        _rewardBuyCondition = c;
    }

    receive() external payable {}

    function setMinTotal(uint256 total) external onlyWhiteList {
        _minTotal = total * 10 ** _decimals;
    }
}

contract ADL is AbsToken {
    constructor() AbsToken(
    //SwapRouter
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E),
    //USDT
        address(0x55d398326f99059fF775485246999027B3197955),
        "Activity of Daily Living",
        "ADL",
        18,
        260000000,
    //Received，
        address(0x6Cf8465D8CEF4810FBF71F382fd947082b1213e0),
    //Fund，
        address(0x9F149feC2702FEbbbDA955738e29Ec84f7377c35),
    //MinTotal，
        20000
    ){

    }
}