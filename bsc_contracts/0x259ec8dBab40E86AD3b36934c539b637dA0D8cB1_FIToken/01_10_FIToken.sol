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
    IERC20 public fi;
    IERC20 public usdt;

    constructor(IERC20 fi_, IERC20 usdt_) {
        fi = fi_;
        usdt = usdt_;
    }

    function withdraw() external {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        if (usdtBalance > 0) {
            usdt.transfer(address(fi), usdtBalance);
        }
    }
}

contract FIToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    Wrap public immutable wrap;
    IERC20 public immutable usdt;

    bool private _swapping;
    uint256 public swapTokensAtAmount;

    uint256 public immutable marketingFee = 1;
    uint256 public immutable lpFee = 1;
    uint256 public immutable buyBackFee = 1;
    uint256 public immutable lpRewardFee = 2;
    uint256 public immutable fiRewardFee = 2;
    uint256 public AmountLpRewardFee;
    uint256 public AmountFiRewardFee;
    uint256 public AmountMarketingFee;
    uint256 public AmountBuyBackFee;
    uint256 public AmountLpFee;
    address public marketingAddress;
    address public lpReceiveAddress;
    address public buyBackAddress;
    address public immutable burnAddress =
        0x000000000000000000000000000000000000dEaD;

    TokenDividendTracker public immutable fiDividendTracker;
    TokenDividendTracker public immutable lpDividendTracker;
    address private _fromAddress;
    address private _toAddress;
    mapping(address => bool) private _isDividendExempt;
    uint256 public minPeriod = 1 days;
    uint256 distributorGas = 200000;

    mapping(address => bool) private _isExcludedFromFees;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
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
        address marketingAddress_,
        address lpReceiveAddress_,
        address buyBackAddress_
    ) payable ERC20(name_, symbol_) {
        uint256 totalSupply = totalSupply_ * (10**18);
        swapTokensAtAmount = totalSupply.mul(2).div(10**6); // 0.002%;
        uniswapV2Router = uniswapV2Router_;
        usdt = usdt_;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                address(usdt)
            );
        marketingAddress = marketingAddress_;
        lpReceiveAddress = lpReceiveAddress_;
        buyBackAddress = buyBackAddress_;
        lpDividendTracker = new TokenDividendTracker(
            uniswapV2Pair,
            address(usdt)
        );
        fiDividendTracker = new TokenDividendTracker(
            address(this),
            address(usdt)
        );
        wrap = new Wrap(IERC20(this), usdt);
        excludeFromFees(owner(), true);
        excludeFromFees(burnAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(marketingAddress, true);
        excludeFromFees(buyBackAddress, true);
        excludeFromFees(lpReceiveAddress, true);
        
        _isDividendExempt[address(this)] = true;
        _isDividendExempt[address(0)] = true;
        _isDividendExempt[burnAddress] = true;
        _isDividendExempt[address(lpDividendTracker)] = true;
        _isDividendExempt[address(fiDividendTracker)] = true;
        _mint(owner(), totalSupply);
    }

    receive() external payable {}

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
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
        if (_isSwapFee(from,to)) {
            _swapFee();
        }
        if (_isTakeFee(from, to)) {
            amount = _takeFee(from, amount);
        }
        super._transfer(from, to, amount);
        if (_fromAddress == address(0)) _fromAddress = from;
        if (_toAddress == address(0)) _toAddress = to;

        if (!_isDividendExempt[_fromAddress] && _fromAddress != uniswapV2Pair){
            try lpDividendTracker.setShare(_fromAddress) {} catch {}
            try fiDividendTracker.setShare(_fromAddress) {} catch {}
        }

        if (!_isDividendExempt[_toAddress] && _toAddress != uniswapV2Pair){
            try lpDividendTracker.setShare(_toAddress) {} catch {}
            try fiDividendTracker.setShare(_toAddress) {} catch {}
        }
        
        _fromAddress = from;
        _toAddress = to;
        
        if (
            !_swapping &&
            from != owner() &&
            to != owner() &&
            from != address(this)
        ) {
            if (
                lpDividendTracker.LPRewardLastSendTime().add(minPeriod) <=
                block.timestamp
            ) {
                try lpDividendTracker.process(distributorGas) {} catch {}
            }
            if (
                fiDividendTracker.LPRewardLastSendTime().add(minPeriod) <=
                block.timestamp
            ) {
                try fiDividendTracker.process(distributorGas) {} catch {}
            }
        }
    }

    function _isSwapFee(address _from, address _to)
        private
        view
        returns (bool)
    {
        return
            balanceOf(address(this)) >= swapTokensAtAmount &&
            !_swapping &&
            _from != uniswapV2Pair &&
            _from != owner() &&
            _to != owner();
    }

    function _swapFee() private {
        _swapping = true;
        if (AmountBuyBackFee > 0) {
            _swapTokensForUsdt(AmountBuyBackFee, buyBackAddress);
            AmountBuyBackFee = 0;
        }
        if (AmountLpRewardFee > 0) {
            _swapTokensForUsdt(AmountLpRewardFee, address(lpDividendTracker));
            AmountLpRewardFee = 0;
        }
        if (AmountMarketingFee > 0) {
            _swapTokensForUsdt(AmountMarketingFee, marketingAddress);
            AmountMarketingFee = 0;
        }
        if (AmountFiRewardFee > 0) {
            _swapTokensForUsdt(AmountFiRewardFee, address(fiDividendTracker));
            AmountFiRewardFee = 0;
        }
        if (AmountLpFee > 0) {
            _swapAndLiquify(AmountLpFee);
            AmountLpFee = 0;
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

    function _takeFee(address from, uint256 amount)
        private
        returns (uint256 amountAfter)
    {
        amountAfter = amount;
        //lp奖励
        uint256 LPRFee = amount.mul(lpRewardFee).div(100);
        AmountLpRewardFee += LPRFee;
        amountAfter = amountAfter.sub(LPRFee);

        //持币奖励
        uint256 FIFee = amount.mul(fiRewardFee).div(100);
        AmountFiRewardFee += FIFee;
        amountAfter = amountAfter.sub(FIFee);

        //营销
        uint256 MFee = amount.mul(marketingFee).div(100);
        AmountMarketingFee += MFee;
        amountAfter = amountAfter.sub(MFee);

        //回流
        uint256 LPFee = amount.mul(lpFee).div(100);
        AmountLpFee += LPFee;
        amountAfter = amountAfter.sub(LPFee);

        //回购
        uint256 BFee = amount.mul(buyBackFee).div(100);
        AmountBuyBackFee += BFee;
        amountAfter = amountAfter.sub(BFee);

        super._transfer(
            from,
            address(this),
            LPRFee.add(MFee).add(FIFee).add(LPFee).add(BFee)
        );
    }

    function _swapAndLiquify(uint256 tokenAmount) private {
        uint256 half = tokenAmount.div(2);
        uint256 otherHalf = tokenAmount.sub(half);
        uint256 newBalance = _swapTokensForUsdt(half, address(wrap));
        _addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForUsdt(uint256 _tokenAmount, address _to)
        private
        returns (uint256 amount)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(usdt);
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uint256 before = usdt.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
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

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount;
    }

    function setMinPeriod(uint256 number) external onlyOwner {
        minPeriod = number;
    }

    function resetLPRewardLastSendTime() external onlyOwner {
        lpDividendTracker.resetLPRewardLastSendTime();
    }

    function resetFIRewardLastSendTime() external onlyOwner {
        fiDividendTracker.resetLPRewardLastSendTime();
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

    function setMarketingAddress(address _address) external onlyOwner {
        marketingAddress = _address;
    }

    function setBuyBackAddress(address _address) external onlyOwner{
        buyBackAddress = _address;
    }

    function setLpReceiveAddress(address _address) external onlyOwner{
        lpReceiveAddress = _address;
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
}