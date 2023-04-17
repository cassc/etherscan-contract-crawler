// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Wrap {
    address public immutable owner;
    IERC20 public immutable usdt;

    constructor(address owner_, IERC20 usdt_) {
        owner = owner_;
        usdt = usdt_;
    }

    function withdraw() external {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        if (usdtBalance > 0) {
            usdt.transfer(owner, usdtBalance);
        }
    }
}

contract Dividend {
    using SafeMath for uint256;

    IERC20 public immutable usdt;

    address public immutable wzcfp;

    address public immutable owner;

    uint256 public top30DividendAmount;

    uint256 public top50DividendAmount;

    constructor(IERC20 usdt_, address wzcfp_, address owner_) {
        usdt = usdt_;
        wzcfp = wzcfp_;
        owner = owner_;
    }

    event Handle(
        address marketingAddress,
        address[] top29Addresses,
        address[] top49Addresses,
        uint256 top30DividendAmount,
        uint256 top50DividendAmount
    );

    function incTop30DividendAmount(uint256 amount) external onlyWzcfp {
        top30DividendAmount += amount;
    }

    function incTop50DividendAmount(uint256 amount) external onlyWzcfp {
        top50DividendAmount += amount;
    }

    function handle(
        address marketingAddress,
        address[] calldata _top29Addresses,
        address[] calldata _top49Addresses
    ) external onlyOwner {
        require(
            _top29Addresses.length <= 29 &&
                _top49Addresses.length >= _top29Addresses.length &&
                _top49Addresses.length <= 49
        );
        if (top30DividendAmount > 0)
            _dividend(marketingAddress, _top29Addresses, top30DividendAmount);
        if (top50DividendAmount > 0)
            _dividend(marketingAddress, _top49Addresses, top50DividendAmount);
        emit Handle(
            marketingAddress,
            _top29Addresses,
            _top49Addresses,
            top30DividendAmount,
            top50DividendAmount
        );
        top30DividendAmount = top50DividendAmount = 0;
    }

    function _dividend(
        address marketingAddress,
        address[] calldata addresses,
        uint256 dividendAmount
    ) private {
        uint256 addressesCount = addresses.length;
        uint256 marketingFee = 0 == addressesCount
            ? dividendAmount
            : dividendAmount.div(6);
        usdt.transfer(marketingAddress, marketingFee);
        if (addressesCount == 0) return;
        dividendAmount = dividendAmount.sub(marketingFee);
        uint256 avgDividendAmount = dividendAmount.div(addressesCount);
        for (uint256 i = 0; i < addressesCount; i++) {
            usdt.transfer(addresses[i], avgDividendAmount);
        }
    }

    function withdraw(address _token, address payable _to) external onlyOwner {
        if (_token == address(0x0)) {
            payable(_to).transfer(address(this).balance);
        } else {
            IERC20(_token).transfer(
                _to,
                IERC20(_token).balanceOf(address(this))
            );
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyWzcfp() {
        require(msg.sender == wzcfp);
        _;
    }
}

contract WZCFP1 is ERC20, Ownable {
    using SafeMath for uint256;
    uint256 constant NO_FEE_REQUIREMENT = 100000;

    address public immutable pair;
    IERC20 public immutable usdt;
    IUniswapV2Router02 public immutable pancakeSwapRouter;
    Wrap public immutable wrap;
    Dividend public dividend;

    bool private _swapping;

    uint256 private immutable _sellLpFeeRate = 3;
    uint256 public immutable sellDividendFeeRate = 3;
    uint256 public immutable buyLpFeeRate = 3;
    uint256 public immutable buyDividendFeeRate = 3;

    address public lpWallet;
    uint256 public AmountLpFee;
    uint256 public AmountSellDividendFee;
    uint256 public AmountBuyDividendFee;

    mapping(uint256 => uint256) private _todayBasePrices;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isHolders;

    uint256 private _lastSwapTime;

    uint256 public swapInterval = 1 hours;

    uint256 public tradeStartTime;

    uint256 public holderCount;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        IERC20 usdt_,
        IUniswapV2Router02 pancakeSwapRouter_,
        address lpWallet_,
        uint256 tradeStartTime_
    ) payable ERC20(name_, symbol_) {
        tradeStartTime = tradeStartTime_;
        lpWallet = lpWallet_;
        usdt = usdt_;
        pancakeSwapRouter = pancakeSwapRouter_;
        pair = IUniswapV2Factory(pancakeSwapRouter.factory()).createPair(
            address(usdt),
            address(this)
        );
        wrap = new Wrap(address(this), usdt);
        dividend = new Dividend(usdt, address(this), owner());
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[lpWallet_] = true;
        _mint(msg.sender, totalSupply_ * 10 ** decimals());
        usdt.approve(address(pancakeSwapRouter), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        _approve(address(this),address(pancakeSwapRouter),115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isHolders(address account) external view returns (bool) {
        return _isHolders[account];
    }

    function todayBasePrices(uint256 _day) external view returns (uint256) {
        return _todayBasePrices[_day];
    }

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
        require(_isStartTrade(from, to), "Not start trade");
        _deliveryCurrentProce();
        if (
            !_swapping &&
            from != pair &&
            from != owner() &&
            to != owner() &&
            block.timestamp >= (_lastSwapTime + swapInterval)
        ) {
            _swapping = true;
            if (AmountLpFee > 0) {
                _swapAndLiquidity(AmountLpFee);
                AmountLpFee = 0;
            }
            if (AmountBuyDividendFee > 0) {
                dividend.incTop50DividendAmount(
                    _swapTokensForUsdt(AmountBuyDividendFee, address(dividend))
                );
                AmountBuyDividendFee = 0;
            }
            if (AmountSellDividendFee > 0) {
                dividend.incTop30DividendAmount(
                    _swapTokensForUsdt(AmountSellDividendFee, address(dividend))
                );
                AmountSellDividendFee = 0;
            }
            _lastSwapTime = block.timestamp;
            _swapping = false;
        }
        if (_shouldTakeFee(from, to)) amount = _takeFee(from, amount);
        super._transfer(from, to, amount);
        setHolder(from);
        setHolder(to);
    }

    function _isStartTrade(
        address _from,
        address _to
    ) private view returns (bool) {
        return
            tradeStartTime <= block.timestamp ||
            (_from != pair && _to != pair) ||
            (_isExcludedFromFees[_to] || _isExcludedFromFees[_from]);
    }

    function _shouldTakeFee(
        address _from,
        address _to
    ) private view returns (bool) {
        return
            !(_isExcludedFromFees[_from] ||
                _isExcludedFromFees[_to] ||
                NO_FEE_REQUIREMENT <= holderCount ||
                _swapping);
    }

    function _takeFee(
        address _from,
        uint256 _amount
    ) private returns (uint256 result) {
        result = _amount;
        uint256 lpFee;
        uint256 dividendFee;
        if (_from == pair) {
            //buy
            lpFee = _amount.mul(buyLpFeeRate).div(100);
            dividendFee = _amount.mul(buyDividendFeeRate).div(100);
            AmountBuyDividendFee += dividendFee;
        } else {
            //sell or transfer
            lpFee = _amount.mul(sellLpFeeRate()).div(100);
            dividendFee = _amount.mul(sellDividendFeeRate).div(100);
            AmountSellDividendFee += dividendFee;
        }
        AmountLpFee += lpFee;
        uint256 totalFee = lpFee + dividendFee;
        result = result.sub(totalFee);
        if (totalFee > 0) super._transfer(_from, address(this), totalFee);
    }

    function sellLpFeeRate() public view returns (uint256) {
        uint256 price = _getCurrentPrice();
        uint256 base = _todayBasePrices[
            ((block.timestamp / 1 days) * 1 days) - 1 days
        ];
        if (price >= base) return _sellLpFeeRate;
        uint256 rate = ((base - price) * 100) / base;
        if (rate >= 10) {
            return 21;
        }
        if (rate >= 5) {
            return 15;
        }
        return _sellLpFeeRate;
    }

    function _deliveryCurrentProce() private {
        uint256 price = _getCurrentPrice();
        uint256 zero = (block.timestamp / 1 days) * 1 days;
        _todayBasePrices[zero] = price;
        if (_todayBasePrices[zero - 1 days] == 0) {
            _todayBasePrices[zero - 1 days] = price;
        }
    }

    function _getCurrentPrice() private view returns (uint256) {
        (uint256 r0, uint256 r1, ) = IUniswapV2Pair(pair).getReserves();
        if (r0 > 0 && r1 > 0) {
            if (address(this) == IUniswapV2Pair(pair).token0()) {
                return (r1 * 10 ** 18) / r0;
            } else {
                return (r0 * 10 ** 18) / r1;
            }
        }
        return 0;
    }

    function _swapTokensForUsdt(
        uint256 tokenAmount,
        address to
    ) private returns (uint256 swapUsdtAmount) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(usdt);
        uint256 beforeUsdtAmount = usdt.balanceOf(to);
        pancakeSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
        uint256 afterUsdtAmount = usdt.balanceOf(to);
        swapUsdtAmount = afterUsdtAmount.sub(beforeUsdtAmount);
        if (to == address(wrap)) wrap.withdraw();
    }

    function _swapAndLiquidity(uint256 tokenAmount) private {
        uint256 half = tokenAmount.div(2);
        uint256 otherHalf = tokenAmount.sub(half);
        uint256 usdtAmount = _swapTokensForUsdt(half, address(wrap));
        _addLiquidityUsdt(otherHalf, usdtAmount);
        emit SwapAndLiquify(half, usdtAmount, otherHalf);
    }

    function _addLiquidityUsdt(
        uint256 tokenAmount,
        uint256 usdtAmount
    ) private {
        pancakeSwapRouter.addLiquidity(
            address(this),
            address(usdt),
            tokenAmount,
            usdtAmount,
            0,
            0,
            lpWallet,
            block.timestamp
        );
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        if (_isExcludedFromFees[account] != excluded) {
            _isExcludedFromFees[account] = excluded;
            emit ExcludeFromFees(account, excluded);
        }
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setLpWallet(address _wallet) external onlyOwner {
        lpWallet = _wallet;
    }

    function setSwapInterval(uint256 _v) external onlyOwner {
        swapInterval = _v;
    }

    function setTradeStartTime(uint256 _v) external onlyOwner {
        tradeStartTime = _v;
    }

    function withdraw(address _token, address payable _to) external onlyOwner {
        if (_token == address(0x0)) {
            payable(_to).transfer(address(this).balance);
        } else {
            IERC20(_token).transfer(
                _to,
                IERC20(_token).balanceOf(address(this))
            );
        }
    }

    function setDividend(Dividend _dividend) external onlyOwner {
        dividend = _dividend;
    }

    function setHolder(address _address) public {
        uint256 balance = balanceOf(_address);
        bool isHolder = _isHolders[_address];
        if (isHolder && balance <= 0) {
            _isHolders[_address] = false;
            holderCount -= 1;
        }
        if (!isHolder && balance > 0) {
            _isHolders[_address] = true;
            holderCount += 1;
        }
    }

    function withdrawUsdt() external {
        IERC20(usdt).transfer(lpWallet, IERC20(usdt).balanceOf(address(this)));
    }

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 usdtReceived,
        uint256 tokensIntoLiqudity
    );
}