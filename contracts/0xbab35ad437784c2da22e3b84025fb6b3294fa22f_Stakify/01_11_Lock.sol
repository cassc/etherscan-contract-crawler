//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./Pool.sol";

contract Stakify is IERC20, Ownable {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event RepellentFeeActivated(uint256 activatedAmount);
    event RepellentFeeDisabled(uint256 disabledAmount);

    IUniswapV2Pair public pairContract;
    mapping(address => bool) _isFeeExempt;
    mapping(address => bool) isAuthorized;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    string constant _name = "Stakify";
    string constant _symbol = "SIFY";
    uint8 constant _decimals = 18;

    uint256 public constant DECIMALS = 18;
    uint256 public constant MAX_UINT256 = ~uint256(0);
    uint8 public constant RATE_DECIMALS = 11;

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY =
        100 * 10 ** 6 * 10 ** DECIMALS;

    uint256 public autoBurnFee = 1;
    uint256 public liquidityFee = 3;
    uint256 public treasuryFee = 1;
    uint256 public totalFee = 5;

    uint256 public repellentSellAutoBurnFee = 15;
    uint256 public repellentSellLiquidityFee = 5;
    uint256 public repellentSellTreasuryFee = 10;
    uint256 public repellentSellTotalFee = 30;

    uint256 public repellentBuyAutoBurnFee = 1;
    uint256 public repellentBuyLiquidityFee = 1;
    uint256 public repellentBuyTreasuryFee = 1;
    uint256 public repellentBuyTotalFee = 3;

    uint256 public swapThershold = INITIAL_FRAGMENTS_SUPPLY / 10000;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address BUSD = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public treasuryFeeWallet =
        0xdAb6280d5a87c10250F454EE3AD3b3b0C1A274C0;

    bool public swapEnabled = true;
    IUniswapV2Router02 public router;

    enum LPLevels {
        Level1,
        Level2,
        Level3,
        Level4,
        Level5
    }

    LPLevels public currentLpLevel;

    ReferalPool public referalPool;

    uint256 public lastLPCheckedAt;
    uint256 public lastLPAmount;
    uint256 public lpCheckFrequency = 1 hours;

    struct LPRange {
        uint256 minLimit;
        uint256 maxLimit;
        uint256 dropLimit;
        uint256 recoverLimit;
    }

    mapping(LPLevels => LPRange) public lpRanges;

    address public pair;
    bool inSwap = false;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    uint256 private constant TOTAL_GONS =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 public swapThreshold;
    bool public tradingOpen = false;

    bool public isRepellentFee;

    uint256 public repellentFeeActivatedAt;
    uint256 public repellentFeeActivatedAmount;
    uint256 public repellentFeeRecoverAmount;

    uint256 public lastRepellentFeeActivatedAt;
    uint256 public lastRepellentFeeRecoveredAt;

    bool public _autoRebase;
    bool public _autoAddLiquidity;
    uint256 public _initRebaseStartTime;
    uint256 public _lastRebasedTime;
    uint256 public _lastAddLiquidityTime;
    uint256 public _totalSupply;
    uint256 private _gonsPerFragment;

    uint256 public initialRebaseRate = 19904549;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    constructor() {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _allowedFragments[address(this)][address(router)] = type(uint256).max;
        pairContract = IUniswapV2Pair(pair);

        isAuthorized[msg.sender] = true;

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _initRebaseStartTime = block.timestamp;
        _lastRebasedTime = block.timestamp;
        _autoRebase = true;
        _autoAddLiquidity = true;
        _isFeeExempt[msg.sender] = true;
        _isFeeExempt[address(this)] = true;

        lpRanges[LPLevels.Level1].minLimit = 0;
        lpRanges[LPLevels.Level1].maxLimit = 100000 ether;
        lpRanges[LPLevels.Level1].dropLimit = 1000;
        lpRanges[LPLevels.Level1].recoverLimit = 2000;

        lpRanges[LPLevels.Level2].minLimit = 100000 ether;
        lpRanges[LPLevels.Level2].maxLimit = 200000 ether;
        lpRanges[LPLevels.Level2].dropLimit = 750;
        lpRanges[LPLevels.Level2].recoverLimit = 1500;

        lpRanges[LPLevels.Level3].minLimit = 200000 ether;
        lpRanges[LPLevels.Level3].maxLimit = 500000 ether;
        lpRanges[LPLevels.Level3].dropLimit = 500;
        lpRanges[LPLevels.Level3].recoverLimit = 1000;

        lpRanges[LPLevels.Level4].minLimit = 500000 ether;
        lpRanges[LPLevels.Level4].maxLimit = 1000000 ether;
        lpRanges[LPLevels.Level4].dropLimit = 250;
        lpRanges[LPLevels.Level4].recoverLimit = 500;

        lpRanges[LPLevels.Level5].minLimit = 1000000 ether;
        lpRanges[LPLevels.Level5].maxLimit = 600000 ether;
        lpRanges[LPLevels.Level5].dropLimit = 100;
        lpRanges[LPLevels.Level5].recoverLimit = 200;

        referalPool = new ReferalPool(msg.sender, address(this));

        // _transferOwnership(treasuryReceiver);
        emit Transfer(address(0x0), msg.sender, _totalSupply);
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

    function rebase() internal {
        if (inSwap) return;
        uint256 rebaseRate;
        uint256 deltaTimeFromInit = block.timestamp - _initRebaseStartTime;
        uint256 deltaTime = block.timestamp - _lastRebasedTime;
        uint256 times = deltaTime.div(3600);
        uint256 epoch = times.mul(60);

        if (deltaTimeFromInit <= 10) {
            rebaseRate = initialRebaseRate;
        } else if (deltaTimeFromInit < 100) {
            uint256 numberOf10Days = deltaTimeFromInit / 10;
            rebaseRate = initialRebaseRate - (100000 * numberOf10Days);
        } else {
            rebaseRate = 272039;
        }

        for (uint256 i = 0; i < times; i++) {
            _totalSupply = _totalSupply
                .mul((10 ** RATE_DECIMALS).add(rebaseRate))
                .div(10 ** RATE_DECIMALS);
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _lastRebasedTime = _lastRebasedTime.add(times.mul(60));

        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
    }

    function transfer(
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != type(uint256).max) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }
        _transferFrom(from, to, value);
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (!isAuthorized[sender]) {
            require(tradingOpen, "Trading not open yet");
        }
        if (inSwap || sender == address(referalPool)) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (
            (lastLPCheckedAt + lpCheckFrequency) < block.timestamp &&
            !isRepellentFee &&
            tradingOpen
        ) {
            uint256 lpBnbBalance = IERC20(router.WETH()).balanceOf(
                address(pair)
            );
            lastLPAmount = getBnbPrice(lpBnbBalance);
            lastLPCheckedAt = block.timestamp;
        }

        if (sender == pair) {
            if (referalPool.userReferal(recipient) != ZERO) {
                referalPool.setReferalBonus(recipient, amount);
            }
        }
        if (tradingOpen) {
            calculateLPStatus();
        }

        if (shouldRebase()) {
            rebase();
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);
        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, gonAmount)
            : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(
            gonAmountReceived
        );

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(_gonsPerFragment)
        );
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 gonAmount
    ) internal returns (uint256) {
        uint256 feeAmount = 0;
        uint256 tokensToTreasury = 0;
        uint256 tokensToBurn = 0;

        if (!isRepellentFee) {
            feeAmount = gonAmount.div(100).mul(totalFee);
            tokensToTreasury = feeAmount.mul(treasuryFee).div(totalFee);
            tokensToBurn = feeAmount.mul(autoBurnFee).div(totalFee);
        } else {
            if (recipient == pair) {
                feeAmount = gonAmount.div(100).mul(repellentSellTotalFee);
                tokensToTreasury = feeAmount.mul(repellentSellTreasuryFee).div(
                    repellentSellTotalFee
                );
                tokensToBurn = feeAmount.mul(repellentSellAutoBurnFee).div(
                    repellentSellTotalFee
                );
            } else {
                feeAmount = gonAmount.div(100).mul(repellentBuyTotalFee);
                tokensToTreasury = feeAmount.mul(repellentBuyTreasuryFee).div(
                    repellentBuyTotalFee
                );
                tokensToBurn = feeAmount.mul(repellentBuyAutoBurnFee).div(
                    repellentBuyTotalFee
                );
            }
        }

        feeAmount = feeAmount.sub(tokensToTreasury).sub(tokensToBurn);

        _gonBalances[treasuryFeeWallet] = _gonBalances[treasuryFeeWallet].add(
            tokensToTreasury
        );

        emit Transfer(
            sender,
            address(treasuryFeeWallet),
            tokensToTreasury.div(_gonsPerFragment)
        );
        _gonBalances[DEAD] = _gonBalances[DEAD].add(tokensToBurn);

        emit Transfer(sender, DEAD, tokensToBurn.div(_gonsPerFragment));
        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            feeAmount
        );

        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));
        return gonAmount.sub(feeAmount + tokensToTreasury + tokensToBurn);
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(DEAD),
            block.timestamp
        );
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = _gonBalances[address(this)].div(
            _gonsPerFragment
        );

        if (contractTokenBalance == 0 && totalFee == 0) return;

        swapAndLiquify(contractTokenBalance);
    }

    function shouldTakeFee(
        address from,
        address to
    ) internal view returns (bool) {
        return (pair == from || pair == to) && !_isFeeExempt[from];
    }

    function shouldRebase() internal view returns (bool) {
        return
            _autoRebase &&
            msg.sender != pair &&
            !inSwap &&
            tradingOpen &&
            block.timestamp >= (_lastRebasedTime + 15 minutes);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            !inSwap &&
            msg.sender != pair &&
            swapEnabled &&
            _gonBalances[address(this)] >= swapThershold;
    }

    function enableSwap(bool status) external onlyOwner {
        swapEnabled = status;
    }

    function setAutoRebase(bool _flag) external onlyOwner {
        if (_flag) {
            _autoRebase = _flag;
            _lastRebasedTime = block.timestamp;
        } else {
            _autoRebase = _flag;
        }
    }

    function setAutoAddLiquidity(bool _flag) external onlyOwner {
        if (_flag) {
            _autoAddLiquidity = _flag;
            _lastAddLiquidityTime = block.timestamp;
        } else {
            _autoAddLiquidity = _flag;
        }
    }

    function allowance(
        address owner_,
        address spender
    ) external view override returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    function enableTrading() public onlyOwner {
        tradingOpen = true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool) {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function approve(
        address spender,
        uint256 value
    ) external override returns (bool) {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(
                _gonsPerFragment
            );
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function manualSync() external {
        IUniswapV2Pair(pair).sync();
    }

    function setFeeReceivers(address _treasuryFeeWallet) external onlyOwner {
        treasuryFeeWallet = _treasuryFeeWallet;
    }

    function getLiquidityBacking(
        uint256 accuracy
    ) public view returns (uint256) {
        uint256 liquidityBalance = _gonBalances[pair].div(_gonsPerFragment);
        return
            accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }

    function setWhitelist(address _addr) external onlyOwner {
        _isFeeExempt[_addr] = true;
    }

    function setLP(address _address) external onlyOwner {
        pairContract = IUniswapV2Pair(_address);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _gonBalances[account].div(_gonsPerFragment);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function _transferBNBToWallet(
        address payable recipient,
        uint256 amount
    ) private {
        recipient.transfer(amount);
    }

    function calculateLPStatus() internal {
        uint256 lpBnbBalance = IERC20(router.WETH()).balanceOf(address(pair));
        uint256 lpBalance = getBnbPrice(lpBnbBalance);

        if (
            lpBalance >= lpRanges[LPLevels.Level1].minLimit &&
            lpBalance <= lpRanges[LPLevels.Level1].maxLimit
        ) currentLpLevel = LPLevels.Level1;

        if (
            lpBalance >= lpRanges[LPLevels.Level2].minLimit &&
            lpBalance <= lpRanges[LPLevels.Level2].maxLimit
        ) currentLpLevel = LPLevels.Level2;

        if (
            lpBalance >= lpRanges[LPLevels.Level3].minLimit &&
            lpBalance <= lpRanges[LPLevels.Level3].maxLimit
        ) currentLpLevel = LPLevels.Level3;

        if (
            lpBalance >= lpRanges[LPLevels.Level4].minLimit &&
            lpBalance <= lpRanges[LPLevels.Level4].maxLimit
        ) currentLpLevel = LPLevels.Level4;

        if (lpBalance >= lpRanges[LPLevels.Level5].minLimit)
            currentLpLevel = LPLevels.Level5;

        if (lastLPAmount > lpBalance && !isRepellentFee) {
            uint256 lpDifference = lastLPAmount - lpBalance;

            uint256 differencePercentage = ((lpDifference * 10000) /
                lastLPAmount);

            if (differencePercentage > lpRanges[currentLpLevel].dropLimit) {
                isRepellentFee = true;
                repellentFeeActivatedAt = block.timestamp;
                lastRepellentFeeActivatedAt = block.timestamp;
                repellentFeeActivatedAmount = lpBalance;
                repellentFeeRecoverAmount =
                    lpBalance +
                    ((lpBalance * lpRanges[currentLpLevel].recoverLimit) /
                        10000);

                emit RepellentFeeActivated(lpBalance);
            }
        }
        if (isRepellentFee && lpBalance > repellentFeeRecoverAmount) {
            isRepellentFee = false;
            repellentFeeActivatedAt = 0;
            repellentFeeActivatedAmount = 0;
            repellentFeeRecoverAmount = 0;

            lastRepellentFeeRecoveredAt = block.timestamp;

            lastLPAmount = lpBalance;

            emit RepellentFeeDisabled(lpBalance);
        }
    }

    function getBnbPrice(uint256 _amount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = BUSD;

        uint256[] memory amounts = router.getAmountsOut(_amount, path);

        return amounts[1];
    }

    function setLpRange(
        LPLevels _level,
        uint256 _min,
        uint256 _max,
        uint256 _drop,
        uint256 _recover
    ) external onlyOwner {
        LPRange storage currentRange = lpRanges[_level];

        currentRange.minLimit = _min;
        currentRange.maxLimit = _max;
        currentRange.dropLimit = _drop;
        currentRange.recoverLimit = _recover;
    }

    function changeSwapPoint(uint256 _amount) external onlyOwner {
        swapThershold = _amount;
    }

    function changeRebaseRate(uint256 _amount) external onlyOwner {
        initialRebaseRate = _amount;
    }

    function changeNormalFees(
        uint256 _autoBurnFee,
        uint256 _liquidityFee,
        uint256 _treasuryFee
    ) external onlyOwner {
        autoBurnFee = _autoBurnFee;
        liquidityFee = _liquidityFee;
        treasuryFee = _treasuryFee;

        totalFee = _autoBurnFee + _liquidityFee + _treasuryFee;

        require(totalFee <= 20, "Fees can not be grater than 20%");
    }

    function changeRepellentSellFees(
        uint256 _autoBurnFee,
        uint256 _liquidityFee,
        uint256 _treasuryFee
    ) external onlyOwner {
        repellentSellAutoBurnFee = _autoBurnFee;
        repellentSellLiquidityFee = _liquidityFee;
        repellentSellTreasuryFee = _treasuryFee;

        repellentSellTotalFee = _autoBurnFee + _liquidityFee + _treasuryFee;

        require(repellentSellTotalFee <= 30, "Fees can not be grater than 30%");
    }

    function changeRepellentBuyFees(
        uint256 _autoBurnFee,
        uint256 _liquidityFee,
        uint256 _treasuryFee
    ) external onlyOwner {
        repellentBuyAutoBurnFee = _autoBurnFee;
        repellentBuyLiquidityFee = _liquidityFee;
        repellentBuyTreasuryFee = _treasuryFee;

        repellentBuyTotalFee = _autoBurnFee + _liquidityFee + _treasuryFee;

        require(repellentSellTotalFee <= 20, "Fees can not be grater than 20%");
    }

    receive() external payable {}
}