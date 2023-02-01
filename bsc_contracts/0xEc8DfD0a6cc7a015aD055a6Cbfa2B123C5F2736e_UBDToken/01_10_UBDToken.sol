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

contract UBDToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    
    TokenDividendTracker public immutable dividendTracker;

    address public immutable uniswapV2Pair;
    
    bool private _swapping;
    
    uint256 public immutable lpRewardFee = 20;

    uint256 public immutable marketingFee1 = 5;

    uint256 public immutable marketingFee2 = 5;
    
    IERC20 public immutable usdt;
    
    address public marketingWallet1;

    address public marketingWallet2;

    address private _fromAddress;
    
    address private _toAddress;

    mapping(address => bool) private _isExcludedFromFees;
    
    mapping(address => bool) private _isDividendExempt;

    uint256 public minPeriod = 1 days;

    uint256 distributorGas = 200000;

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
        address marketingWallet1_,
        address marketingWallet2_
    ) payable ERC20(name_, symbol_) {
        uint256 totalSupply = totalSupply_ * (10**18);
        uniswapV2Router = uniswapV2Router_;
        usdt = usdt_;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                address(usdt)
            );
        dividendTracker = new TokenDividendTracker(
            uniswapV2Pair,
            address(this)
        );

        marketingWallet1 = marketingWallet1_;
        marketingWallet2 = marketingWallet2_;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(dividendTracker), true);
        excludeFromFees(marketingWallet1, true);
        excludeFromFees(marketingWallet2, true);

        _isDividendExempt[address(this)] = true;
        _isDividendExempt[address(0)] = true;
        _isDividendExempt[address(dividendTracker)] = true;

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
        if (_isTakeFee(from, to)) {
            amount = _takeFee(from, amount);
        }
        super._transfer(from, to, amount);
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
            from != address(dividendTracker) && 
            dividendTracker.LPRewardLastSendTime().add(minPeriod) <=
            block.timestamp
        ) {
            try dividendTracker.process(distributorGas) {} catch {}
        }
    }

    
    function _isTakeFee(address _from, address _to)
        private
        view
        returns (bool)
    {
        if (
            _isExcludedFromFees[_from] ||
            _isExcludedFromFees[_to] ||
            _swapping
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
       
        uint256 LPFee = amount.mul(lpRewardFee).div(1000);
        if(LPFee>0)super._transfer(from,address(dividendTracker),LPFee);
        amountAfter = amountAfter.sub(LPFee);

        uint256 MFee1 = amount.mul(marketingFee1).div(1000);
        if(MFee1>0)super._transfer(from,marketingWallet1,MFee1);
        amountAfter = amountAfter.sub(MFee1);

        uint256 MFee2 = amount.mul(marketingFee2).div(1000);
        if(MFee2>0)super._transfer(from,marketingWallet2,MFee2);
        amountAfter = amountAfter.sub(MFee2);
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

     function setMarketingWallet1(address payable wallet) external onlyOwner{
        marketingWallet1 = wallet;
    }

     function setMarketingWallet2(address payable wallet) external onlyOwner{
        marketingWallet2 = wallet;
    }
}