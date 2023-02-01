/**
 *Submitted for verification at BscScan.com on 2023-01-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

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
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract AbsToken is IERC20, Ownable {
    struct SellRateConfig {
        uint256 price;
        uint256 rate;
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _feeWhiteList;

    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    address public _usdt;
    mapping(address => bool) public _swapPairList;

    uint256 private constant MAX = ~uint256(0);

    uint256 public _buyFee = 10000;

    uint256 public _sellLPDividendFee = 1000;

    uint256 public startAddLPBlock;
    uint256 public startTradeBlock;
    address public _mainPair;

    uint256 public _sellPoolRate = 1000;
    uint256 public _minTotal;
    SellRateConfig[] private _sellRateConfigs;

    constructor (
        address RouterAddress, address USDTAddress,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply,
        address FundAddress, address ReceiveAddress,
        uint256 MinTotal
    ){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);

        _usdt = USDTAddress;
        _swapRouter = swapRouter;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address usdtPair = swapFactory.createPair(address(this), USDTAddress);
        _swapPairList[usdtPair] = true;
        _mainPair = usdtPair;

        uint256 tokenUnit = 10 ** Decimals;
        uint256 total = Supply * tokenUnit;

        _tTotal = total;

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);

        fundAddress = FundAddress;

        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[address(0x000000000000000000000000000000000000dEaD)] = true;

        excludeLPHolder[address(0)] = true;
        excludeLPHolder[address(0x000000000000000000000000000000000000dEaD)] = true;
        lpRewardCondition = 2 * tokenUnit;
        lpCondition = 1000;

        _minTotal = MinTotal * tokenUnit;

        uint256 usdtUnit = 10 ** IERC20(USDTAddress).decimals();
        _sellRateConfigs.push(SellRateConfig(100 * usdtUnit, 99));
        _sellRateConfigs.push(SellRateConfig(50 * usdtUnit, 50));
        _sellRateConfigs.push(SellRateConfig(0 * usdtUnit, 0));
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
        return _tTotal;
    }

    function validTotal() public view returns (uint256) {
        return _tTotal - _balances[address(0)] - _balances[address(0x000000000000000000000000000000000000dEaD)];
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 balance = _balances[account];
        return balance;
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

    address private _lastMaybeLPAddress;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        address lastMaybeLPAddress = _lastMaybeLPAddress;
        if (lastMaybeLPAddress != address(0)) {
            _lastMaybeLPAddress = address(0);
            if (IERC20(_mainPair).balanceOf(lastMaybeLPAddress) > 0) {
                _addLpProvider(lastMaybeLPAddress);
            }
        }

        uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");
        bool takeFee;

        if (_swapPairList[from] || _swapPairList[to]) {
            if (startAddLPBlock == 0 && _mainPair == to && _feeWhiteList[from] && IERC20(to).totalSupply() == 0) {
                startAddLPBlock = block.number;
                startTradeBlock = block.number;
            }

            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                takeFee = true;
                bool isAddLP;
                if (_swapPairList[to]) {
                    isAddLP = _isAddLiquidity(amount);
                    if (isAddLP) {
                        takeFee = false;
                    } else {
                        address[] memory path = new address[](2);
                        path[0] = address(this);
                        path[1] = _usdt;
                        uint[] memory amounts = _swapRouter.getAmountsOut(10 ** _decimals, path);
                        uint256 price = amounts[amounts.length - 1];
                        uint256 sellRate = getSellRate(price);
                        require(sellRate > 0, "Price");
                        uint256 maxSellAmount = balance * sellRate / 100;
                        if (amount > maxSellAmount) {
                            amount = maxSellAmount;
                        }
                    }
                } else {
                    bool isRemoveLP = _isRemoveLiquidity();
                    if (isRemoveLP) {
                        takeFee = false;
                    }
                }

                if (0 == startTradeBlock) {
                    require(0 < startAddLPBlock && isAddLP, "!Trade");
                }
            }
        } else {
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                uint256 maxSellAmount = balance * 99 / 100;
                if (amount > maxSellAmount) {
                    amount = maxSellAmount;
                }
            }
        }

        _tokenTransfer(from, to, amount, takeFee);

        if (from != address(this)) {
            if (_swapPairList[to]) {
                _lastMaybeLPAddress = from;
            }

            processLPReward(_rewardGas);
        }
    }

    function getSellRate(uint256 price) public view returns (uint256 rate){
        uint256 len = _sellRateConfigs.length;
        rate = _sellRateConfigs[len - 1].rate;
        SellRateConfig storage sellRateConfig;
        for (uint256 i; i < len;) {
            sellRateConfig = _sellRateConfigs[i];
            if (price >= sellRateConfig.price) {
                rate = sellRateConfig.rate;
                break;
            }
        unchecked{
            ++i;
        }
        }
    }

    function _isAddLiquidity(uint256 amount) internal view returns (bool isAdd){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1,) = mainPair.getReserves();

        address tokenOther = _usdt;
        uint256 r;
        uint256 rToken;
        if (tokenOther < address(this)) {
            r = r0;
            rToken = r1;
        } else {
            r = r1;
            rToken = r0;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        if (rToken == 0) {
            isAdd = bal > r;
        } else {
            isAdd = bal > r + r * amount / rToken / 2;
        }
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = _usdt;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;

        if (takeFee) {
            if (_swapPairList[sender]) {//Buy
                feeAmount = tAmount * _buyFee / 10000;
                if (feeAmount > 0) {
                    _takeTransfer(sender, sender, feeAmount);
                }
            } else if (_swapPairList[recipient]) {//Sell
                feeAmount = tAmount * _sellLPDividendFee / 10000;
                if (feeAmount > 0) {
                    _takeTransfer(sender, address(this), feeAmount);
                }

                address mainPair = _mainPair;
                uint256 mainPoolToken = balanceOf(mainPair);
                require(tAmount <= mainPoolToken * _sellPoolRate / 10000, "sLimit");

                uint256 sellDestroyAmount = tAmount - feeAmount;

                uint256 currentTotal = validTotal();
                uint256 maxDestroyAmount;
                if (currentTotal > _minTotal) {
                    maxDestroyAmount = currentTotal - _minTotal;
                }
                if (sellDestroyAmount > maxDestroyAmount) {
                    sellDestroyAmount = maxDestroyAmount;
                }
                if (sellDestroyAmount > 0) {
                    _tokenTransfer(mainPair, address(0x000000000000000000000000000000000000dEaD), sellDestroyAmount, false);
                    ISwapPair(mainPair).sync();
                }
            }
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function setBuyFee(uint256 fee) external onlyOwner {
        _buyFee = fee;
    }

    function setSellFee(uint256 lpDividendFee) external onlyOwner {
        _sellLPDividendFee = lpDividendFee;
    }

    function startTrade() external onlyOwner {
        require(0 == startTradeBlock, "trading");
        startTradeBlock = block.number;
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    function batchSetFeeWhiteList(address [] memory addr, bool enable) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function claimBalance() external {
        if (_feeWhiteList[msg.sender]) {
            payable(fundAddress).transfer(address(this).balance);
        }
    }

    function claimToken(address token, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            IERC20(token).transfer(fundAddress, amount);
        }
    }

    function setMinTotal(uint256 amount) external onlyOwner {
        _minTotal = amount * 10 ** _decimals;
    }

    function setSellRate(uint256 rate) external onlyOwner {
        _sellPoolRate = rate;
    }

    receive() external payable {}

    address[] public lpProviders;
    mapping(address => uint256) public lpProviderIndex;

    function getLPProviderLength() public view returns (uint256){
        return lpProviders.length;
    }

    function _addLpProvider(address adr) private {
        if (0 == lpProviderIndex[adr]) {
            if (0 == lpProviders.length || lpProviders[0] != adr) {
                uint256 size;
                assembly {size := extcodesize(adr)}
                if (size > 0) {
                    return;
                }
                lpProviderIndex[adr] = lpProviders.length;
                lpProviders.push(adr);
            }
        }
    }

    uint256 public _rewardGas = 500000;

    mapping(address => bool)  public excludeLPHolder;
    uint256 public currentLPIndex;
    uint256 public lpRewardCondition;
    uint256 public lpCondition;
    uint256 public progressLPRewardBlock;
    uint256 public progressLPBlockDebt = 20;

    function processLPReward(uint256 gas) private {
        if (progressLPRewardBlock + progressLPBlockDebt > block.number) {
            return;
        }

        uint256 rewardCondition = lpRewardCondition;
        address sender = address(this);
        if (balanceOf(sender) < rewardCondition) {
            return;
        }
        IERC20 holdToken = IERC20(_mainPair);
        uint holdTokenTotal = holdToken.totalSupply();
        if (0 == holdTokenTotal) {
            return;
        }

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;

        uint256 shareholderCount = lpProviders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        uint256 holdCondition = lpCondition;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentLPIndex >= shareholderCount) {
                currentLPIndex = 0;
            }
            shareHolder = lpProviders[currentLPIndex];
            tokenBalance = holdToken.balanceOf(shareHolder);
            if (tokenBalance >= holdCondition && !excludeLPHolder[shareHolder]) {
                amount = rewardCondition * tokenBalance / holdTokenTotal;
                if (amount > 0) {
                    _tokenTransfer(sender, shareHolder, amount, false);
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentLPIndex++;
            iterations++;
        }
        progressLPRewardBlock = block.number;
    }

    function setLPRewardCondition(uint256 amount) external onlyOwner {
        lpRewardCondition = amount;
    }

    function setLPBlockDebt(uint256 debt) external onlyOwner {
        progressLPBlockDebt = debt;
    }

    function setLPCondition(uint256 amount) external onlyOwner {
        lpCondition = amount;
    }

    function setExcludeLPHolder(address addr, bool enable) external onlyOwner {
        excludeLPHolder[addr] = enable;
    }

    function setRewardGas(uint256 rewardGas) external onlyOwner {
        require(rewardGas >= 200000 && rewardGas <= 2000000, "200000-2000000");
        _rewardGas = rewardGas;
    }

    function getSellRateConfigs() public view returns (uint256[] memory price, uint256[] memory rate){
        uint256 len = _sellRateConfigs.length;
        price = new uint256[](len);
        rate = new uint256[](len);
        SellRateConfig storage sellRateConfig;
        for (uint256 i; i < len;) {
            sellRateConfig = _sellRateConfigs[i];
            price[i] = sellRateConfig.price;
            rate[i] = sellRateConfig.rate;
        unchecked{
            ++i;
        }
        }
    }

    function setSellRateConfig(uint256 i, uint256 price, uint256 rate) public onlyOwner {
        SellRateConfig storage sellRateConfig = _sellRateConfigs[i];
        sellRateConfig.price = price;
        sellRateConfig.rate = rate;
    }

    function addSellRateConfig(uint256 price, uint256 rate) public onlyOwner {
        _sellRateConfigs.push(SellRateConfig(price, rate));
    }
}

contract FOMO is AbsToken {
    constructor() AbsToken(
    //SwapRouter
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E),
    //USDT
        address(0x55d398326f99059fF775485246999027B3197955),
        "FOMO",
        "FOMO",
        18,
        199999,
    //Fund
        address(0x12E9c91fe1aB1DE52A620A88Ce2D047260E13A22),
    //Received
        address(0x12E9c91fe1aB1DE52A620A88Ce2D047260E13A22),
    //MinTotal
        9999
    ){

    }
}