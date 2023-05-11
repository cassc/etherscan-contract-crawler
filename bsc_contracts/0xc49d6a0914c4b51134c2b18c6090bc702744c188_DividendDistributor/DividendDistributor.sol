/**
 *Submitted for verification at BscScan.com on 2023-05-10
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IERC20Extended {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

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

    function calculatePrice() external view returns (uint256);

    function getBNBPrice() external view returns (uint256);
}

interface ISRGONE {
    function deposit(uint256 _amount) external;
}

interface IReceiver {
    function process() external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDividendDistributor {

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit(uint256 amount) external;

    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address public _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20Extended public rewardToken;
    address private srgToken;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod;
    uint256 public minDistribution;

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address rewardToken_, address srgToken_) {
        _token = msg.sender;
        rewardToken = IERC20Extended(rewardToken_);
        srgToken = srgToken_;

        dividendsPerShareAccuracyFactor = 10 ** 36;
        minPeriod = 1 hours;
        minDistribution = 1 * (10 ** rewardToken.decimals());
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit(uint256 amount) external onlyToken {

        uint256 balanceBefore = rewardToken.balanceOf(address(this));

        IERC20Extended(srgToken).approve(address(this), amount);
        IERC20Extended(srgToken).approve(address(rewardToken), amount);

        ISRGONE(address(rewardToken)).deposit(amount);

        uint256 balanceAfter = rewardToken.balanceOf(address(this));

        uint256 rewardAmount = balanceAfter - balanceBefore;

        totalDividends = totalDividends + rewardAmount;
        dividendsPerShare = dividendsPerShare + ((dividendsPerShareAccuracyFactor * rewardAmount) / totalShares);
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return
        shareholderClaims[shareholder] + minPeriod < block.timestamp &&
        getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            rewardToken.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
            .totalRealised
            .add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function claimDividend(address holder) external {
        distributeDividend(holder);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
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

contract CHAD is IERC20Extended, Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    event Bought(address indexed from, address indexed to, uint256 tokens, uint256 beans, uint256 dollarBuy);
    event Sold(address indexed from, address indexed to, uint256 tokens, uint256 beans, uint256 dollarSell);
    event Burn(address indexed from, uint256 value, uint256 new_supply);
    event FeesMulChanged(uint256 newBuyMul, uint256 newSellMul, uint256 newBurnTax);
    event LiquidityAdded(uint256 amountSRG, uint256 amountSRG20);
    event MaxBagChanged(uint256 newMaxBag);

    address private _dexRouter;

    IERC20Extended private ISRG;

    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);
    uint8 private constant _decimals = 9;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    address public rewardToken;

    //Fees
    uint256 public sellMul;
    uint256 public buyMul;
    uint256 public DIVISOR = 100;

    uint256 public totalFee;
    uint256 public rewardsFee;
    uint256 public burnFee;
    uint256 public assetBackingFee;
    uint256 public liquidityFee;
    uint256 public stakingFee;
    uint256 public SHAREDIVISOR;

    address public burnReceiver;
    address public assetBackingReceiver;
    address public liquidityReceiver;
    address public stakingReceiver;

    uint256 public taxBalance = 0;
    uint256 public taxBalanceMin = 5000 * (10 ** _decimals);

    DividendDistributor public distributor;
    uint256 public distributorGas;

    // balances
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isDividendExempt;

    mapping(address => bool) public isTxLimitExempt;
    uint256 public maxBag;
    uint256 public maxTX;

    //trading parameters
    uint256 public liquidity;
    uint256 public liqConst;
    bool public tradeOpen = false;

    //volume trackers
    mapping(address => uint256) public indVol;
    mapping(uint256 => uint256) public tVol;
    uint256 public totalVolume = 0;

    //candlestick data
    uint256 public constant PADDING = 10 ** 18;
    uint256 public totalTx;
    mapping(uint256 => uint256) public txTimeStamp;

    struct candleStick {
        uint256 time;
        uint256 open;
        uint256 close;
        uint256 high;
        uint256 low;
    }

    mapping(uint256 => candleStick) public candleStickData;

    //Frontrun Guard
    mapping(address => uint256) private _lastBuyBlock;
    uint256 public launchedAt;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address rewardToken_,
        address srg_,
        address dexRouter_,
        uint256 startLiquidity_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_ * (10 ** _decimals);
        rewardToken = rewardToken_;

        liquidity = startLiquidity_ * (10 ** _decimals);
        liqConst = liquidity * _totalSupply;

        _dexRouter = dexRouter_;

        ISRG = IERC20Extended(srg_);

        distributor = new DividendDistributor(rewardToken_, srg_);
        distributorGas = 500000;

        _initializeFees();
        setFeeReceivers(msg.sender, msg.sender, msg.sender, msg.sender);
        setTxLimits(_totalSupply, _totalSupply);

        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(0)] = true;

        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);

        launchedAt = block.number;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function performBurn(uint256 amount) public {
        _burn(_msgSender(), amount);
        emit Burn(_msgSender(), amount, _totalSupply);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function getLiquidity() public view returns (uint256) {
        return liquidity;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD));
    }

    function getMarketCap() external view returns (uint256) {
        return (getCirculatingSupply() * calculatePrice() * getSRGPrice());
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "SRG20: approve to the zero address");
        require(
            msg.sender != address(0),
            "SRG20: approve from the zero address"
        );

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(recipient != address(0) && recipient != address(this) && recipient != _dexRouter, "transfer to the zero address or CA");
        require(isTxLimitExempt[recipient] || _balances[recipient].add(amount) <= maxBag, "Max wallet exceeded!");

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);

        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if (!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _initializeFees() internal {
        _setFees(
            100, // rewardsFee
            100, // burnFee
            100, // assetBackingFee
            100, // liquidityFee
            100, // stakingFee
            500, // SHAREDIVISOR
            95, // buyMul
            90  // sellMul
        );
    }

    function setFees(uint256 _rewardsFee, uint256 _burnFee, uint256 _assetBackingFee, uint256 _liquidityFee, uint256 _stakingFee, uint256 _SHAREDIVISOR, uint256 _buyMul, uint256 _sellMul) public onlyOwner {
        _setFees(
            _rewardsFee,
            _burnFee,
            _assetBackingFee,
            _liquidityFee,
            _stakingFee,
            _SHAREDIVISOR,
            _buyMul,
            _sellMul
        );
    }

    function _setFees(uint256 _rewardsFee, uint256 _burnFee, uint256 _assetBackingFee, uint256 _liquidityFee, uint256 _stakingFee, uint256 _SHAREDIVISOR, uint256 _buyMul, uint256 _sellMul) internal {
        rewardsFee = _rewardsFee;
        burnFee = _burnFee;
        assetBackingFee = _assetBackingFee;
        liquidityFee = _liquidityFee;
        stakingFee = _stakingFee;


        totalFee = _rewardsFee
        .add(_burnFee)
        .add(_assetBackingFee)
        .add(_liquidityFee)
        .add(_stakingFee);

        SHAREDIVISOR = _SHAREDIVISOR;

        buyMul = _buyMul;
        sellMul = _sellMul;

        require(
            _buyMul >= 85 &&
            _sellMul >= 85 &&
            _buyMul <= 100 &&
            _sellMul <= 100,
            "Fees are too high"
        );

        emit FeesMulChanged(_buyMul, _sellMul, 0);

        require(totalFee == SHAREDIVISOR, "Total fees should equal SHAREDIVISOR");
    }

    function setTaxBalanceMin(uint256 amount) external onlyOwner {
        taxBalanceMin = amount * (10 **_decimals);
    }

    function setFeeReceivers(address _burnReceiver, address _assetBackingReceiver, address _liquidityReceiver, address _stakingReceiver) public onlyOwner {
        burnReceiver = _burnReceiver;
        assetBackingReceiver = _assetBackingReceiver;
        liquidityReceiver = _liquidityReceiver;
        stakingReceiver = _stakingReceiver;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this));
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setTxLimits(uint256 newLimit, uint256 newMaxTx) public onlyOwner {
        require(newLimit >= maxBag && newMaxTx >= maxTX, "New wallet limit should be at least 1% of total supply");
        maxBag = newLimit;
        maxTX = newMaxTx;
        emit MaxBagChanged(newLimit);
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function _buy(uint256 buyAmount, uint256 minTokenOut, uint256 deadline) public nonReentrant returns (bool) {

        require(deadline >= block.timestamp, "Deadline EXPIRED");
        require(liquidity > 0, "The token has no liquidity");

        address buyer = msg.sender;
        require(tradeOpen || isTxLimitExempt[buyer], "Trading is not Open");

        _lastBuyBlock[buyer] = block.number;
        // Frontrun Guard

        //remove the buy tax
        uint256 srgAmount = isFeeExempt[buyer] ? buyAmount : (buyAmount * buyMul) / DIVISOR;

        // how much they should receive?
        uint256 tokensToSend = _balances[address(this)] - (liqConst / (srgAmount + liquidity));

        require((_balances[buyer].add(tokensToSend) <= maxBag && tokensToSend <= maxTX) || isTxLimitExempt[buyer], "Max wallet exceeded");
        require(tokensToSend > 1, "SRG20: Must Buy more than 1 decimal");
        require(tokensToSend >= minTokenOut, "INSUFFICIENT OUTPUT AMOUNT");

        // transfer the SRG from the msg.sender to the CA
        bool s = ISRG.transferFrom(buyer, address(this), buyAmount);
        require(s, "transfer of SRG failed!");

        // transfer the tokens from CA to the buyer
        buy(buyer, tokensToSend);

        //update available tax to extract and Liquidity
        uint256 taxAmount = buyAmount - srgAmount;
        liquidity = liquidity + srgAmount;
        collectTaxes(taxAmount);

        uint256 cTime = block.timestamp;
        updateVolume(cTime, buyAmount);
        updateCandleStickData(cTime, srgAmount);


        if (!isDividendExempt[buyer] && !isFeeExempt[buyer]) {
            try distributor.setShare(buyer, _balances[buyer]) {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        //emit transfer and buy events
        emit Transfer(address(this), msg.sender, tokensToSend);
        emit Bought(msg.sender, address(this), tokensToSend, buyAmount, srgAmount * getSRGPrice());
        return true;
    }

    function buy(address receiver, uint256 amount) internal {
        _balances[receiver] = _balances[receiver] + amount;
        _balances[address(this)] = _balances[address(this)] - amount;
    }

    function _sell(uint256 tokenAmount, uint256 deadline, uint256 minBNBOut) public nonReentrant returns (bool) {
        require(deadline >= block.timestamp, "Deadline EXPIRED");
        require(tokenAmount <= maxTX, "Max Tx exceeded!");
        require(_lastBuyBlock[msg.sender] != block.number, "Buying and selling in the same block is not allowed!");

        address seller = msg.sender;

        require(_balances[seller] >= tokenAmount, "cannot sell above token amount");

        // get how much beans are the tokens worth
        uint256 amountSRG = liquidity - (liqConst / (_balances[address(this)] + tokenAmount));
        require(amountSRG >= minBNBOut, "INSUFFICIENT OUTPUT AMOUNT");

        uint256 amountTax = (amountSRG * (DIVISOR - sellMul)) / DIVISOR;
        uint256 SRGtoSend = amountSRG - amountTax;
        collectTaxes(amountTax);

        // send SRG to Seller
        bool successful = isFeeExempt[msg.sender] ? ISRG.transfer(msg.sender, amountSRG) : ISRG.transfer(msg.sender, SRGtoSend);
        require(successful, "SRG transfer failed");

        // subtract full amount from sender
        _balances[seller] = _balances[seller] - tokenAmount;

        liquidity = liquidity - amountSRG;

        // add tokens back into the contract
        _balances[address(this)] = _balances[address(this)] + tokenAmount;

        uint256 cTime = block.timestamp;
        updateVolume(cTime, amountSRG);
        updateCandleStickData(cTime, 0);

        if (!isDividendExempt[seller] && !isFeeExempt[seller]) {
            try distributor.setShare(seller, _balances[seller]) {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        // emit transfer and sell events
        emit Transfer(seller, address(this), tokenAmount);
        if (isFeeExempt[msg.sender]) {
            emit Sold(address(this), msg.sender, tokenAmount, amountSRG, amountSRG * getSRGPrice());
        } else {
            emit Sold(address(this), msg.sender, tokenAmount, SRGtoSend, SRGtoSend * getSRGPrice());
        }
        return true;
    }

    function addLiquidity(uint256 amountSRGLiq) external onlyOwner {
        uint256 tokensToAdd = (_balances[address(this)] * amountSRGLiq) / liquidity;
        require(_balances[msg.sender] >= tokensToAdd, "Not enough tokens!");

        bool sLiq = ISRG.transfer(address(this), amountSRGLiq);
        require(sLiq, "SRG transfer was unsuccesful!");

        uint256 oldLiq = liquidity;
        liquidity = liquidity + amountSRGLiq;
        _balances[address(this)] += tokensToAdd;
        _balances[msg.sender] -= tokensToAdd;
        liqConst = (liqConst * liquidity) / oldLiq;

        emit Transfer(msg.sender, address(this), tokensToAdd);
        emit LiquidityAdded(amountSRGLiq, tokensToAdd);
    }

    function checkPendingRewards(address holder) external view returns (uint256) {
        return distributor.getUnpaidEarnings(holder);
    }

    function processDist(uint256 gas) external nonReentrant {
        distributor.process(gas);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000, "Gas must be lower than 750000");
        distributorGas = gas;
    }

    function claimRewards() external nonReentrant {
        distributor.claimDividend(msg.sender);
    }

    function getTokenAmountOut(uint256 amountSRGIn) external view returns (uint256) {
        uint256 amountAfter = liqConst / (liquidity - amountSRGIn);
        uint256 amountBefore = liqConst / liquidity;
        return amountAfter - amountBefore;
    }

    function getsrgAmountOut(uint256 amountIn) public view returns (uint256) {
        uint256 srgBefore = liqConst / _balances[address(this)];
        uint256 srgAfter = liqConst / (_balances[address(this)] + amountIn);
        return srgBefore - srgAfter;
    }

    function getValueOfHoldings(address holder) public view returns (uint256) {
        return
        ((_balances[holder] * liquidity) / _balances[address(this)]) *
        getSRGPrice();
    }

    function openTrading() external nonReentrant onlyOwner {
        tradeOpen = true;
    }

    function getSRGPrice() public view returns (uint256) {
        return (ISRG.calculatePrice() * ISRG.getBNBPrice());
    }

    function getBNBPrice() public view returns (uint256) {
        return ISRG.getBNBPrice();
    }

    function calculatePrice() public view returns (uint256) {
        require(liquidity > 0, "No Liquidity");
        return (liquidity * PADDING) / _balances[address(this)];
    }

    function updateCandleStickData(uint256 cTime, uint256 srgAmount) internal {
        totalTx += 1;
        txTimeStamp[totalTx] = cTime;
        uint256 cPrice = calculatePrice() * getSRGPrice();
        candleStickData[cTime].time = cTime;

        if (candleStickData[cTime].open == 0) {
            if (totalTx == 1) {
                candleStickData[cTime].open =
                ((liquidity - srgAmount) / (_totalSupply)) *
                getSRGPrice();
            } else {
                candleStickData[cTime].open = candleStickData[
                txTimeStamp[totalTx - 1]
                ].close;
            }
        }
        candleStickData[cTime].close = cPrice;

        if (
            candleStickData[cTime].high < cPrice ||
            candleStickData[cTime].high == 0
        ) {
            candleStickData[cTime].high = cPrice;
        }

        if (candleStickData[cTime].low > cPrice || candleStickData[cTime].low == 0) {
            candleStickData[cTime].low = cPrice;
        }

    }

    function updateVolume(uint256 cTime, uint256 _amount) internal {
        uint256 dollarAmount = _amount * getSRGPrice();
        totalVolume += dollarAmount;
        indVol[msg.sender] += dollarAmount;
        tVol[cTime] += dollarAmount;
    }

    function collectTaxes(uint256 taxAmount) internal {
        taxBalance += taxAmount;
        if(taxBalance >= taxBalanceMin){
            distributeTaxes();
        }
    }

    function distributeTaxes() public nonReentrant {
        if (taxBalance > 0) {
            uint256 rewardAmount = taxBalance.mul(rewardsFee).div(SHAREDIVISOR);
            ISRG.approve(address(this), rewardAmount);
            require(ISRG.transfer(address(distributor), rewardAmount), "Transfer of Rewards Failed");
            distributor.deposit(rewardAmount);

            uint256 burnAmount = taxBalance.mul(burnFee).div(SHAREDIVISOR);
            ISRG.approve(address(this), burnAmount);
            require(ISRG.transfer(burnReceiver, burnAmount), "Transfer of Burn Failed");

            uint256 assetBackingAmount = taxBalance.mul(assetBackingFee).div(SHAREDIVISOR);
            ISRG.approve(address(this), assetBackingAmount);
            require(ISRG.transfer(assetBackingReceiver, assetBackingAmount), "Transfer of Asset Backing Failed");

            uint256 liquidityAmount = taxBalance.mul(liquidityFee).div(SHAREDIVISOR);
            ISRG.approve(address(this), liquidityAmount);
            require(ISRG.transfer(liquidityReceiver, liquidityAmount), "Transfer of Liquidity Failed");

            uint256 stakingAmount = taxBalance.mul(stakingFee).div(SHAREDIVISOR);
            ISRG.approve(address(this), stakingAmount);
            require(ISRG.transfer(stakingReceiver, stakingAmount), "Transfer of Staking Failed");

            taxBalance = 0;
        }
    }

    function processTaxes() public nonReentrant {
        IReceiver(burnReceiver).process();
        IReceiver(assetBackingReceiver).process();
        IReceiver(liquidityReceiver).process();
        IReceiver(stakingReceiver).process();
    }

}