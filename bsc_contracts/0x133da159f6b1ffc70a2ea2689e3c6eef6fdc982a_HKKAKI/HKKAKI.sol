/**
 *Submitted for verification at BscScan.com on 2023-03-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ISwapPair {
    function sync() external;
}

contract TokenDistributor {
    constructor (address token) {
        //将token代币授权给创建合约的地址，数量为最大整数，可以认为是无限大，在本合约中是USDT
        //因为swap合约要求，兑换的接收地址不能是swapPair的两个代币合约地址，所以在非主链币交易对的时候，
        //都需要一个类似这样的中转合约来接收兑换的代币，然后再将中转合约地址里的代币转出，需要调用transferFrom方法，该方法需要授权
        //当然，中转合约还有别的写法
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}

abstract contract AbsToken is IERC20, Ownable {
    mapping(address => mapping(address => uint256)) private _allowances;

    //营销钱包
    address public fundAddress;
    //营销钱包2
    address public fundAddress2;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    //买入的邀请税
    uint256 public _buyInviteFee = 8;
    //卖出的LP回流税
    uint256 public _sellLPFee = 2;
    //卖出的营销税
    uint256 public _sellFundFee = 1;
    //卖出的销毁税
    uint256 public _sellDestroyFee = 0;
    //卖出的营销税2
    uint256 public _sellFundFee2 = 2;

    //开放交易的区块
    uint256 public startTradeBlock;
    //白名单列表
    mapping(address => bool) public _feeWhiteList;
    //排除复利地址列表
    mapping(address => bool) public _excludeRewardList;

    //实际总量，复利的时候，该总量会变大
    uint256 public _tTotal;
    //根据系数放大后的总量，合约部署后，不会再改变，_tTotal变大，系数会变小，每个人的余额_rOwned[account]/系数，会变大
    uint256 public _rTotal;
    //放大比例后的数量，初始_rOwned[account]=_tOwned[account]*_rTotal/_tTotal
    mapping(address => uint256) public _rOwned;
    //真实拥有的数量，一般初始化或者不参与复利分红时有用
    mapping(address => uint256) public _tOwned;
    uint256 public constant MAX = ~uint256(0);

    mapping(address => bool) public _swapPairList;

    //单地址限制持有数量，0表示不限制
    uint256 public _limitAmount;

    //15分钟利率，分母为100000000，每日利率=(1.00025725)^96，24小时有96个15分钟
    uint256  public apr15Minutes = 25725;
    //利率的分母
    uint256 private constant AprDivBase = 100000000;
    //最近计算复利的时间
    uint256 public _lastRewardTime;
    //是否启用自动复利
    bool public _autoApy;
    //邀请人即上级发放奖励的持币条件，0表示不需要持币也能发放邀请奖励
    uint256 public _invitorHoldCondition;

    //防止合约卖币时，方法重入，陷入无限递归
    bool private inSwap;

    TokenDistributor public _tokenDistributor;
    address public _usdt;
    ISwapRouter public _swapRouter;

    constructor (address RouteAddress, address USDTAddress,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply,
        address ReceivedAddress, address FundAddress, address FundAddress2){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        ISwapRouter swapRouter = ISwapRouter(RouteAddress);
        _swapRouter = swapRouter;
        //因为要回流，提前将本合约地址的本代币授权给路由地址，数量为最大整数
        _allowances[address(this)][address(swapRouter)] = MAX;

        _usdt = USDTAddress;
        //创建USDT交易对
        address usdtPair = ISwapFactory(swapRouter.factory()).createPair(address(this), USDTAddress);
        _swapPairList[usdtPair] = true;
        //交易对不进行复利
        _excludeRewardList[usdtPair] = true;

        //实际总量
        uint256 tTotal = Supply * 10 ** Decimals;
        //这里预留空间，为了计算复利
        uint256 base = AprDivBase * 100;
        //放大比例后的总量，MAX/base后，最大的能够整除 tTotal 的整数，rTotal/tTotal=比例系数
        uint256 rTotal = MAX / base - (MAX / base % tTotal);
        _rOwned[ReceivedAddress] = rTotal;
        _tOwned[ReceivedAddress] = tTotal;
        emit Transfer(address(0), ReceivedAddress, tTotal);
        _rTotal = rTotal;
        _tTotal = tTotal;

        fundAddress = FundAddress;
        fundAddress2 = FundAddress2;

        //白名单
        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[FundAddress2] = true;
        _feeWhiteList[ReceivedAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(swapRouter)] = true;

        _inProject[msg.sender] = true;

        //创建接收合约兑换后接收USDT的中转合约
        _tokenDistributor = new TokenDistributor(USDTAddress);
    }

    //计算复利逻辑方法，该方法可手动调用
    function calApy() public {
        //未开启自动复利
        if (!_autoApy) {
            return;
        }
        //当前代币实际总量
        uint256 total = _tTotal;
        //代币能增发的最大总量
        uint256 maxTotal = _rTotal;
        //都增发到最大值了，肯定不再复利了
        if (total == maxTotal) {
            return;
        }
        //当前区块时间
        uint256 blockTime = block.timestamp;
        //上一次计算复利的时间
        uint256 lastRewardTime = _lastRewardTime;
        //相差不到15分钟，不计算复利
        if (blockTime < lastRewardTime + 15 minutes) {
            return;
        }
        //时间差值
        uint256 deltaTime = blockTime - lastRewardTime;
        //时间差值有多少个15分钟
        uint256 times = deltaTime / 15 minutes;
        //每个15分钟，计算一次复利
        for (uint256 i; i < times;) {
            //复利后的总量
            total = total * (AprDivBase + apr15Minutes) / AprDivBase;
            //如果超过最大总量，直接等于最大总量完事
            if (total > maxTotal) {
                total = maxTotal;
                break;
            }
            //不检测溢出，能省一点gas费
        unchecked{
            ++i;
        }
        }
        //当前合约的代币总量=计算复利后的总量
        _tTotal = total;
        //更新最近一次计算复利的时间
        _lastRewardTime = lastRewardTime + times * 15 minutes;
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

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        //不参与复利的地址，只返回地址实际持有的代币数量
        if (_excludeRewardList[account]) {
            return _tOwned[account];
        }
        //参与复利的地址，返回公式计算的代币余额
        return tokenFromReflection(_rOwned[account]);
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
        //都授权最大值了，转账后，没必要减少授权额度
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    //利用公式计算代币余额，参数是根据系数放大后的值
    function tokenFromReflection(uint256 rAmount) public view returns (uint256){
        //放大系数
        uint256 currentRate = _getRate();
        //系数放大后的数值/系数，就是实际持币数量，在这里，用户的rAmount不变，系数会慢慢变小，所以余额会变多
        return rAmount / currentRate;
    }

    function _getRate() public view returns (uint256) {
        //一般不会出现这个情况
        if (_rTotal < _tTotal) {
            return 1;
        }
        //_rTotal不变，_tTotal变大，返回的系数会变小
        return _rTotal / _tTotal;
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
        //每笔转账之前，都先计算一下复利
        calApy();

        uint256 balance = balanceOf(from);
        //余额不足，这里一般是配合dapp使用的
        require(balance >= amount, "balanceNotEnough");

        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            //地址不能把币都转出去，保留持币地址
            uint256 maxSellAmount = balance * 99999 / 100000;
            if (amount > maxSellAmount) {
                amount = maxSellAmount;
            }
        }

        bool takeFee;
        bool isBuy;

        //买入卖出操作
        if (_swapPairList[from] || _swapPairList[to]) {
            if (0 == startTradeBlock) {
                //没开盘，只能白名单加池子，或者买卖
                require(_feeWhiteList[from] || _feeWhiteList[to], "!Trading");
                //注释掉的是加池子就自动开盘的代码，如果需要，把下面注释去掉
                //                if (_swapPairList[to] && IERC20(to).totalSupply() == 0) {
                //                    startTradeBlock = block.number;
                //                }
            }

            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                //杀区块，这里的杀法是只给一少部分币
                if (block.number < startTradeBlock + 4) {
                    _funTransfer(from, to, amount);
                    return;
                }

                takeFee = true;
                if (_swapPairList[from]) {
                    isBuy = true;
                }
            }
        } else {
            //转账绑定关系
            if (0 == balanceOf(to) && amount > 0) {
                _bindInvitor(to, from);
            }
        }

        _tokenTransfer(from, to, amount, takeFee, isBuy);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isBuy
    ) private {
        //扣减实际数量
        if (_tOwned[sender] > tAmount) {
            _tOwned[sender] -= tAmount;
        } else {
            _tOwned[sender] = 0;
        }

        //当前的余额系数
        uint256 currentRate = _getRate();
        //扣减放大系数后的数量
        _rOwned[sender] = _rOwned[sender] - tAmount * currentRate;

        uint256 feeAmount;
        if (takeFee) {
            if (isBuy) {//处理买入税
                uint256 totalInviteAmount = tAmount * _buyInviteFee / 100;
                feeAmount += totalInviteAmount;
                uint256 fundAmount = totalInviteAmount;
                //邀请奖励，根据自己的需求改吧，通过公式计算每代奖励，或者每代都一个if判断都行
                if (totalInviteAmount > 0) {
                    address current = recipient;
                    address invitor;
                    uint256 inviterAmount;
                    uint256 perInviteAmount = totalInviteAmount / 16;
                    uint256 invitorHoldCondition = _invitorHoldCondition;
                    for (uint256 i; i < 10;) {
                        invitor = _inviter[current];
                        if (address(0) == invitor) {
                            break;
                        }
                        if (0 == i) {
                            inviterAmount = perInviteAmount * 6;
                        } else if (1 == i) {
                            inviterAmount = perInviteAmount * 2;
                        } else {
                            inviterAmount = perInviteAmount;
                        }
                        if (0 == invitorHoldCondition || balanceOf(invitor) >= invitorHoldCondition) {
                            fundAmount -= inviterAmount;
                            _takeTransfer(sender, invitor, inviterAmount, currentRate);
                        }
                        current = invitor;
                    unchecked{
                        ++i;
                    }
                    }
                }
                //邀请奖励发给上级，没发完，那就给营销钱包
                if (fundAmount > 1000000) {
                    _takeTransfer(sender, fundAddress, fundAmount, currentRate);
                }
            } else {//处理卖出税
                if (!inSwap) {
                    inSwap = true;
                    //LP回流税，这里直接打到LP池子地址，然后sync同步池子价格，也就是刷新价格
                    uint256 lpAmount = tAmount * _sellLPFee / 100;
                    if (lpAmount > 0) {
                        feeAmount += lpAmount;
                        _takeTransfer(
                            sender,
                            recipient,
                            lpAmount,
                            currentRate
                        );
                        ISwapPair(recipient).sync();
                    }
                    //营销税，这里是每笔卖单，合约都直接把营销税兑换为USDT，有的需求可能需要累计到一定数量再卖
                    uint256 fundFee = _sellFundFee + _sellFundFee2;
                    uint256 fundAmount = tAmount * fundFee / 100;
                    if (fundAmount > 0) {
                        feeAmount += fundAmount;
                        _takeTransfer(sender, address(this), fundAmount, currentRate);

                        address usdt = _usdt;
                        address tokenDistributor = address(_tokenDistributor);
                        address[] memory path = new address[](2);
                        path[0] = address(this);
                        path[1] = usdt;
                        //兑换USDT，不能当前合约地址接收，只能中转合约地址接收，然后分配给两个营销钱包地址
                        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                            fundAmount,
                            0,
                            path,
                            tokenDistributor,
                            block.timestamp
                        );

                        IERC20 USDT = IERC20(usdt);
                        uint256 usdtBalance = USDT.balanceOf(tokenDistributor);
                        //USDT分配给两个营销钱包
                        uint256 fundUsdt = usdtBalance * _sellFundFee / fundFee;
                        if (fundUsdt > 0) {
                            USDT.transferFrom(tokenDistributor, fundAddress, fundUsdt);
                        }
                        uint256 fundUsdt1 = usdtBalance - fundUsdt;
                        if (fundUsdt1 > 0) {
                            USDT.transferFrom(tokenDistributor, fundAddress2, fundUsdt1);
                        }
                    }
                    //销毁税
                    uint256 destroyAmount = tAmount * _sellDestroyFee / 100;
                    if (destroyAmount > 0) {
                        feeAmount += destroyAmount;
                        _takeTransfer(sender, address(0x000000000000000000000000000000000000dEaD), destroyAmount, currentRate);
                    }
                    inSwap = false;
                }
            }
        }

        _takeTransfer(
            sender,
            recipient,
            tAmount - feeAmount,
            currentRate
        );
    }

    //这里是杀区块的代码逻辑
    function _funTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        if (_tOwned[sender] > tAmount) {
            _tOwned[sender] -= tAmount;
        } else {
            _tOwned[sender] = 0;
        }

        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount * currentRate;
        _rOwned[sender] = _rOwned[sender] - rAmount;

        //90%的币给营销钱包地址
        _takeTransfer(sender, fundAddress, tAmount / 100 * 90, currentRate);
        //杀区块的交易地址，只能得到10%的代币
        _takeTransfer(sender, recipient, tAmount / 100 * 10, currentRate);
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        _tOwned[to] += tAmount;

        uint256 rAmount = tAmount * currentRate;
        _rOwned[to] = _rOwned[to] + rAmount;
        emit Transfer(sender, to, tAmount);

        //检测是否限制持有
        if (_limitAmount > 0 && !_swapPairList[to] && !_feeWhiteList[to]) {
            require(_limitAmount >= balanceOf(to), "exceed LimitAmount");
        }
    }

    receive() external payable {}

    function claimBalance() external onlyFunder {
        payable(fundAddress).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount) external onlyFunder {
        IERC20(token).transfer(fundAddress, amount);
    }

    function setFundAddress(address addr) external onlyFunder {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function setFundAddress2(address addr) external onlyFunder {
        fundAddress2 = addr;
        _feeWhiteList[addr] = true;
    }

    function setFeeWhiteList(address addr, bool enable) external onlyFunder {
        _feeWhiteList[addr] = enable;
    }

    function setSwapPairList(address addr, bool enable) external onlyFunder {
        _swapPairList[addr] = enable;
        if (enable) {
            _excludeRewardList[addr] = true;
        }
    }

    //设置地址是否不参与复利
    function setExcludeReward(address addr, bool enable) external onlyFunder {
        _tOwned[addr] = balanceOf(addr);
        _rOwned[addr] = _tOwned[addr] * _getRate();
        _excludeRewardList[addr] = enable;
    }

    function setBuyFee(uint256 buyInviteFee) external onlyOwner {
        _buyInviteFee = buyInviteFee;
    }

    function setSellFee(uint256 sellLPFee, uint256 sellFundFee, uint256 sellDestroyFee, uint256 sellFundFee2) external onlyOwner {
        _sellLPFee = sellLPFee;
        _sellFundFee = sellFundFee;
        _sellDestroyFee = sellDestroyFee;
        _sellFundFee2 = sellFundFee2;
    }

    //设置单地址限制持有数量
    function setLimitAmount(uint256 amount) external onlyFunder {
        _limitAmount = amount * 10 ** _decimals;
    }

    //开放交易
    function startTrade() external onlyFunder {
        require(0 == startTradeBlock, "trading");
        startTradeBlock = block.number;
    }

    //关闭交易
    function closeTrade() external onlyOwner {
        startTradeBlock = 0;
    }

    //开放自动复利
    function startAutoApy() external onlyFunder {
        require(!_autoApy, "autoAping");
        _autoApy = true;
        _lastRewardTime = block.timestamp;
    }

    //紧急关闭自动复利
    function emergencyCloseAutoApy() external onlyFunder {
        _autoApy = false;
    }

    //关闭自动复利，关闭之前先计算之前未计算的复利
    function closeAutoApy() external onlyFunder {
        calApy();
        _autoApy = false;
    }

    //修改15分钟利率，分母为100000000
    function setApr15Minutes(uint256 apr) external onlyFunder {
        calApy();
        apr15Minutes = apr;
    }

    function setInvitorHoldCondition(uint256 amount) external onlyFunder {
        _invitorHoldCondition = amount * 10 ** _decimals;
    }

    modifier onlyFunder() {
        require(_owner == msg.sender || fundAddress == msg.sender, "!Funder");
        _;
    }

    mapping(address => address) public _inviter;
    mapping(address => address[]) private _binders;
    mapping(address => bool) public _inProject;

    //这个方法，是为了给项目的其他合约调用的
    function bindInvitor(address account, address invitor) public {
        address caller = msg.sender;
        require(_inProject[caller], "notInProj");
        _bindInvitor(account, invitor);
    }

    //绑定关系代币
    function _bindInvitor(address account, address invitor) private {
        if (_inviter[account] == address(0) && invitor != address(0) && invitor != account) {
            if (_binders[account].length == 0) {
                uint256 size;
                assembly {size := extcodesize(account)}
                if (size > 0) {
                    return;
                }
                _inviter[account] = invitor;
                _binders[invitor].push(account);
            }
        }
    }

    function setInProject(address adr, bool enable) external onlyFunder {
        _inProject[adr] = enable;
    }
}

contract HKKAKI is AbsToken {
    constructor() AbsToken(
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E),
        address(0x55d398326f99059fF775485246999027B3197955),
    //名称
        "HKKAKI",
    //符号
        "HKKAKI",
    //精度
        9,
    //总量 2亿
        2000000000000000,
    
        address(0xC070Ec7a2495D911248D1687Ebd809c47518C8b7),
    
        address(0x41cBfA5fD1A0a09ae385bc10e16bBcBdc92e3810),
    
        address(0x5A9bb522B1700eF78AFeCB4729e13117269051e8)
    ){

    }
}