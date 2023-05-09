// SPDX-License-Identifier: No License
pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function setAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual returns (bool) {
        _allowances[owner][spender] = amount;
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

library SafeMathInt {
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns (uint256);

    event DividendsDistributed(address indexed from, uint256 weiAmount);

    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(
        address _owner
    ) external view returns (uint256);

    function withdrawnDividendOf(
        address _owner
    ) external view returns (uint256);

    function accumulativeDividendOf(
        address _owner
    ) external view returns (uint256);
}

contract DividendPayingToken is
    ERC20,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
{
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 internal constant magnitude = 2 ** 128;

    uint256 internal magnifiedDividendPerShare;

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    address public rewardToken;

    constructor(
        address _rewardToken,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        rewardToken = _rewardToken;
    }

    function distributeDividends(uint256 amount) public {
        require(totalSupply() > 0);

        uint256 balBefore = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).transferFrom(msg.sender, address(this), amount);
        uint256 received = IERC20(rewardToken).balanceOf(address(this)) -
            balBefore;

        if (received > 0) {
            magnifiedDividendPerShare =
                magnifiedDividendPerShare +
                ((received * magnitude) / totalSupply());

            emit DividendsDistributed(msg.sender, received);

            totalDividendsDistributed = totalDividendsDistributed + received;
        }
    }

    function _withdrawDividend(address account) internal returns (uint256) {
        uint256 withdrawableDividend = withdrawableDividendOf(account);

        if (withdrawableDividend > 0) {
            withdrawnDividends[account] =
                withdrawnDividends[account] +
                withdrawableDividend;

            try
                IERC20(rewardToken).transfer(account, withdrawableDividend)
            returns (bool) {
                emit DividendWithdrawn(account, withdrawableDividend);

                return withdrawableDividend;
            } catch {
                withdrawnDividends[account] =
                    withdrawnDividends[account] -
                    withdrawableDividend;

                return 0;
            }
        }

        return 0;
    }

    function dividendOf(
        address account
    ) public view override returns (uint256) {
        return withdrawableDividendOf(account);
    }

    function withdrawableDividendOf(
        address account
    ) public view override returns (uint256) {
        return accumulativeDividendOf(account) - withdrawnDividends[account];
    }

    function withdrawnDividendOf(
        address account
    ) public view override returns (uint256) {
        return withdrawnDividends[account];
    }

    function accumulativeDividendOf(
        address account
    ) public view override returns (uint256) {
        return
            ((magnifiedDividendPerShare * balanceOf(account)).toInt256Safe() +
                magnifiedDividendCorrections[account]).toUint256Safe() /
            magnitude;
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] =
            magnifiedDividendCorrections[account] -
            (magnifiedDividendPerShare * value).toInt256Safe();
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] =
            magnifiedDividendCorrections[account] +
            (magnifiedDividendPerShare * value).toInt256Safe();
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance)
            _mint(account, newBalance - currentBalance);
        else if (newBalance < currentBalance)
            _burn(account, currentBalance - newBalance);
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(
        Map storage map,
        address key
    ) public view returns (int) {
        if (!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(
        Map storage map,
        uint index
    ) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

contract DividendTracker is Ownable, DividendPayingToken {
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public isExcludedFromDividends;
    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account, bool isExcluded);
    event ClaimWaitUpdated(uint256 claimWait);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims);

    constructor(
        uint256 _claimWait,
        uint256 _minimumTokenBalance,
        address _rewardToken
    ) DividendPayingToken(_rewardToken, "DividendTracker", "DividendTracker") {
        claimWaitSetup(_claimWait);
        minimumTokenBalanceForDividends = _minimumTokenBalance;
    }

    function excludeFromDividends(
        address account,
        uint256 balance,
        bool isExcluded
    ) external onlyOwner {
        if (isExcluded) {
            require(
                !isExcludedFromDividends[account],
                "DividendTracker: This address is already excluded from dividends"
            );
            isExcludedFromDividends[account] = true;

            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        } else {
            require(
                isExcludedFromDividends[account],
                "DividendTracker: This address is already included in dividends"
            );
            isExcludedFromDividends[account] = false;

            setBalance(account, balance);
        }

        emit ExcludeFromDividends(account, isExcluded);
    }

    function claimWaitSetup(uint256 newClaimWait) public onlyOwner {
        require(
            newClaimWait >= 60 && newClaimWait <= 7 days,
            "DividendTracker: Claim wait time must be between 1 minute and 7 days"
        );

        claimWait = newClaimWait;

        emit ClaimWaitUpdated(newClaimWait);
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccountData(
        address _account
    )
        public
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;
        index = tokenHoldersMap.getIndexOfKey(account);
        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index - int256(lastProcessedIndex);
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
                    lastProcessedIndex
                    ? tokenHoldersMap.keys.length - lastProcessedIndex
                    : 0;
                iterationsUntilProcessed =
                    index +
                    int256(processesUntilEndOfArray);
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime + claimWait : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
            ? nextClaimTime - block.timestamp
            : 0;
    }

    function getAccountDataAtIndex(
        uint256 index
    )
        public
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (index >= tokenHoldersMap.size())
            return (address(0), -1, -1, 0, 0, 0, 0, 0);

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccountData(account);
    }

    function claim(address account) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividend(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            return true;
        }
        return false;
    }

    function _canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (block.timestamp < lastClaimTime) return false;

        return block.timestamp - lastClaimTime >= claimWait;
    }

    function setBalance(address account, uint256 newBalance) public onlyOwner {
        if (!isExcludedFromDividends[account]) {
            if (newBalance >= minimumTokenBalanceForDividends) {
                _setBalance(account, newBalance);
                tokenHoldersMap.set(account, newBalance);
            } else {
                _setBalance(account, 0);
                tokenHoldersMap.remove(account);
            }
        }
    }

    function process(
        uint256 gas
    ) external onlyOwner returns (uint256 iterations, uint256 claims) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) return (0, 0);

        uint256 _lastProcessedIndex = lastProcessedIndex;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        iterations = 0;
        claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length)
                _lastProcessedIndex = 0;

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (_canAutoClaim(lastClaimTimes[account])) {
                if (claim(account)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft)
                gasUsed = gasUsed + (gasLeft - newGasLeft);

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        emit ProcessedDividendTracker(iterations, claims);
    }
}

abstract contract DividendTrackerFunctions is Ownable {
    DividendTracker public dividendTracker;

    uint256 public gasForProcessing;

    address public rewardToken;

    event DeployedDividendTracker(
        address indexed dividendTracker,
        address indexed rewardToken
    );
    event GasForProcessingUpdated(uint256 gasForProcessing);

    function _deployDividendTracker(
        uint256 claimWait,
        uint256 minimumTokenBalance,
        address _rewardToken
    ) internal {
        dividendTracker = new DividendTracker(
            claimWait,
            minimumTokenBalance,
            _rewardToken
        );

        rewardToken = _rewardToken;

        emit DeployedDividendTracker(address(dividendTracker), _rewardToken);
    }

    function gasForProcessingSetup(uint256 _gasForProcessing) public onlyOwner {
        require(
            _gasForProcessing >= 200_000 && _gasForProcessing <= 1_000_000,
            "ERC20: gasForProcessing must be between 200k and 1M units"
        );

        gasForProcessing = _gasForProcessing;

        emit GasForProcessingUpdated(_gasForProcessing);
    }

    function claimWaitSetup(uint256 claimWait) external onlyOwner {
        dividendTracker.claimWaitSetup(claimWait);
    }

    function excludeFromDividends(
        address account,
        bool isExcluded
    ) public virtual;

    function isExcludedFromDividends(
        address account
    ) public view returns (bool) {
        return dividendTracker.isExcludedFromDividends(account);
    }

    function claim() external returns (bool) {
        return dividendTracker.claim(msg.sender);
    }

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function dividendTokenTotalSupply() public view returns (uint256) {
        return dividendTracker.totalSupply();
    }

    function getAccountDividendsInfo(
        address account
    )
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountData(account);
    }

    function getAccountDividendsInfoAtIndex(
        uint256 index
    )
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountDataAtIndex(index);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.lastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() public view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function process(
        uint256 gas
    ) external returns (uint256 iterations, uint256 claims) {
        return dividendTracker.process(gas);
    }
}

interface IPancakeSwapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IPancakeSwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract ScroogeToken is ERC20, Ownable, DividendTrackerFunctions {
    using SafeMath for uint256;

    uint256 public swapThreshold;
    uint256 public _totalSupply = 1_000_000_000 * (10 ** decimals());
    uint256 public _maxTxAmount;
    uint256 public _walletMax;

    address private _marketingAddress;
    address private _deployer;
    address public immutable DEAD = 0x000000000000000000000000000000000000dEaD;
    address public immutable ZERO = 0x0000000000000000000000000000000000000000;

    // Buy Tax: 5%
    uint256 _buyLiquidityFee = 20;
    uint256 _buyMarketingFees = 20;
    uint256 _buyRewardFee = 10;
    uint256 public totalBuyFee;

    // Sell Tax: 10%
    uint256 _sellLiquidityFee = 30;
    uint256 _sellMarketingFees = 20;
    uint256 _sellBurnFees = 10;
    uint256 _sellRewardFee = 40;
    uint256 public totalSellFee;

    uint256 feeDenominator = 1000;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedFromMaxWalletSize;
    mapping(address => bool) public isExcludedFromMaxTxAmount;

    bool _swapping;
    bool private _swapEnabled;
    bool private _tradingActive;

    modifier swapping() {
        _swapping = true;
        _;
        _swapping = false;
    }

    IPancakeSwapRouter public pancakeRouter;
    address public pairAddress;

    mapping(address => bool) public isCoreAddress;
    mapping(address => bool) public isMarketPair;
    mapping(address => bool) public isBlacklisted;
    uint256 private _launchedAt;
    uint256 private _snipingTime = 120 seconds;

    constructor(
        address marketingWallet,
        address busdRewardToken
    ) ERC20("SCROOGE", "$CROOGE") {

        swapThreshold = 2_000_000 * (10 ** decimals()); //0.2% 
        _maxTxAmount = 20_000_000 * (10 ** decimals()); //2.0% 
        _walletMax = 20_000_000 * (10 ** decimals());   //2.0% 

        _marketingAddress = marketingWallet;
        _deployer = msg.sender;

        totalBuyFee = _buyLiquidityFee.add(_buyRewardFee).add(
            _buyMarketingFees
        );

        totalSellFee = _sellLiquidityFee
            .add(_sellRewardFee)
            .add(_sellMarketingFees)
            .add(_sellBurnFees);

        dividendTracker = new DividendTracker(
            36_000,
            100 * (10 ** decimals()),
            busdRewardToken
        );

        rewardToken = busdRewardToken;
        gasForProcessing = 300000;

        isCoreAddress[msg.sender] = true;
        isCoreAddress[address(this)] = true;

        excludeFromDividends(address(this), true);
        excludeFromDividends(DEAD, true);
        excludeFromDividends(ZERO, true);

        excludeFromFees(DEAD, true);
        excludeFromFees(address(this), true);
        excludeFromFees(msg.sender, true);

        excludeFromMaxTxAmount(DEAD, true);
        excludeFromMaxTxAmount(ZERO, true);
        excludeFromMaxTxAmount(msg.sender, true);
        excludeFromMaxTxAmount(address(this), true);

        excludeFromMaxWalletSize(msg.sender, true);
        excludeFromMaxWalletSize(address(this), true);
        excludeFromMaxWalletSize(DEAD, true);
        excludeFromMaxWalletSize(ZERO, true);

        // _mint is an internal function in ERC20.sol that is only called here and CANNOT be called ever again
        _mint(msg.sender, _totalSupply);
    }

    receive() external payable {}

    modifier simpleGuard() {
        require(msg.sender == _deployer, "Error: Guarded!");
        _;
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        _tradingActive = true;
        _swapEnabled = true;
        _launchedAt = block.timestamp;
    }

    function swapTokens(uint256 tokenAmount, address[] memory path) private {
        _approve(address(this), address(pancakeRouter), tokenAmount);

        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _sendDividends(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();
        path[2] = rewardToken; // Convert to BUSD

        _approve(address(this), address(pancakeRouter), tokenAmount);

        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BUSD
            path,
            address(this),
            block.timestamp
        );

        uint256 dividends = IERC20(rewardToken).balanceOf(address(this));

        if (dividends > 0) {
            bool success = IERC20(rewardToken).approve(
                address(dividendTracker),
                dividends
            );

            if (success) {
                dividendTracker.distributeDividends(dividends);
            }
        }
    }

    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        dividendTracker.setBalance(account, balanceOf(account));
    }

    function _mint(address account, uint256 amount) internal override {
        super._mint(account, amount);
        dividendTracker.setBalance(account, balanceOf(account));
    }

    function swapBack(uint256 contractBalance) internal swapping {
        uint256 totalShares = totalBuyFee.add(totalSellFee); // 15%

        if (totalShares == 0) return;

        uint256 _marketingShare = _buyMarketingFees.add(_sellMarketingFees);
        uint256 _rewardShare = _buyRewardFee.add(_sellRewardFee);
        uint256 _liquidityShare = _buyLiquidityFee.add(_sellLiquidityFee);

        // only half liquidity share needs to be tokens
        uint256 tokensForLP = contractBalance
            .mul(_liquidityShare)
            .div(totalShares)
            .div(2);
        uint256 tokensForBurn = contractBalance.mul(_sellBurnFees).div(
            totalShares
        );

        uint256 tokensForReward = contractBalance.mul(_rewardShare).div(
            totalShares
        );

        // rest of LP and all other tokens can be sold for BNB
        uint256 tokensForSwap = contractBalance
            .sub(tokensForLP)
            .sub(tokensForBurn)
            .sub(tokensForReward);

        uint256 initialBalance = address(this).balance;

        // generate the uniswap pair path of token -> bnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH(); // BNB

        swapTokens(tokensForSwap, path);

        uint256 amountReceived = address(this).balance.sub(initialBalance);

        uint256 amountETHLiquidity = amountReceived
            .mul(_liquidityShare)
            .div(totalShares)
            .div(2);

        uint256 amountBNBMarketing = amountReceived.mul(_marketingShare).div(
            totalShares
        );

        if (amountETHLiquidity > 0 && tokensForLP > 0) {
            addLiquidity(tokensForLP, amountETHLiquidity);
        }

        if (tokensForReward > 0) {
            _sendDividends(tokensForReward);
        }

        if (amountBNBMarketing > 0) {
            (bool os, ) = payable(_marketingAddress).call{
                value: amountBNBMarketing
            }("");
            require(os, "Marketing Fund Failure!");
        }

        if (tokensForBurn > 0) {
            _burn(address(this), tokensForBurn);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!isBlacklisted[from], "ERC20: Bot detected");
        require(!isBlacklisted[msg.sender], "ERC20: Bot detected");

        if (_swapping) {
            // if swapping, dont take fees
            return super._transfer(from, to, amount);
        }

        if (!isCoreAddress[from] && !isCoreAddress[to]) {
            require(_tradingActive, "ERC20: trading not enable yet");
            if (
                block.timestamp < _launchedAt + _snipingTime &&
                from != address(pancakeRouter)
            ) {
                if (pairAddress == from) {
                    isBlacklisted[to] = true;
                } else if (pairAddress == to) {
                    isBlacklisted[from] = true;
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= swapThreshold;

        if (
            overMinimumTokenBalance &&
            !_swapping &&
            !isMarketPair[from] &&
            _swapEnabled
        ) {
            swapBack(contractTokenBalance);
        }

        if (
            !isExcludedFromMaxTxAmount[from] && !isExcludedFromMaxTxAmount[to]
        ) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTransactionAmount."
            );
        }

        if (!isExcludedFromMaxWalletSize[to]) {
            require(
                amount + balanceOf(to) <= _walletMax,
                "Max wallet size exceeded"
            );
        }

        uint256 finalAmount = shouldNotTakeFee(from, to)
            ? amount
            : takeFee(from, to, amount);

        super._transfer(from, to, finalAmount);

        dividendTracker.setBalance(from, balanceOf(from));
        dividendTracker.setBalance(to, balanceOf(to));

        if (!_swapping)
            try dividendTracker.process(gasForProcessing) {} catch {}
    }

    function shouldNotTakeFee(
        address sender,
        address recipient
    ) internal view returns (bool) {
        if (isExcludedFromFees[sender] || isExcludedFromFees[recipient]) {
            return true;
        } else if (isMarketPair[sender] || isMarketPair[recipient]) {
            return false;
        } else {
            return false;
        }
    }

    function setupPair(address pancakeSwapRouter) external onlyOwner {
        // Router & Pair
        pancakeRouter = IPancakeSwapRouter(pancakeSwapRouter); // Pancakeswap
        pairAddress = IPancakeSwapFactory(pancakeRouter.factory()).createPair(
            address(this),
            pancakeRouter.WETH()
        );

        isCoreAddress[pancakeSwapRouter] = true;
        excludeFromMaxWalletSize(pairAddress, true);
        excludeFromMaxWalletSize(pancakeSwapRouter, true);
        excludeFromDividends(pairAddress, true);
        excludeFromDividends(pancakeSwapRouter, true);
        excludeFromFees(pancakeSwapRouter, true);
        excludeFromMaxTxAmount(pancakeSwapRouter, true);
        
        isMarketPair[pairAddress] = true;

        setAllowance(address(this), pancakeSwapRouter, ~uint256(0));
        setAllowance(address(this), pairAddress, ~uint256(0));
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint feeAmount;

        unchecked {
            if (isMarketPair[sender]) {
                //buy
                feeAmount = amount.mul(totalBuyFee).div(feeDenominator);
            } else if (isMarketPair[recipient]) {
                //sell
                feeAmount = amount.mul(totalSellFee).div(feeDenominator);
            }

            if (feeAmount > 0) {
                super._transfer(sender, address(this), feeAmount);
            }

            return amount.sub(feeAmount);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            DEAD, // Auto-burn liquidity
            block.timestamp
        );
    }

    function excludeFromDividends(
        address account,
        bool isExcluded
    ) public override simpleGuard {
        dividendTracker.excludeFromDividends(
            account,
            balanceOf(account),
            isExcluded
        );
    }

    function excludeFromFees(
        address account,
        bool isExcluded
    ) public simpleGuard {
        isExcludedFromFees[account] = isExcluded;
    }

    function excludeFromMaxWalletSize(
        address account,
        bool isExcluded
    ) public simpleGuard {
        isExcludedFromMaxWalletSize[account] = isExcluded;
    }

    function excludeFromMaxTxAmount(
        address account,
        bool isExcluded
    ) public simpleGuard {
        isExcludedFromMaxTxAmount[account] = isExcluded;
    }

    function setMaxWalletLimit(uint256 newLimit) external simpleGuard {
        require(
            newLimit >= ((totalSupply() * 5) / 1000) / 1e9,
            "Cannot set Max Wallet Amount lower than 0.5%"
        );

        _walletMax = newLimit;
    }

    function setTxLimit(uint256 newLimit) external simpleGuard {
        require(
            newLimit >= ((totalSupply() * 5) / 1000) / 1e9,
            "Cannot set Max Transaction Limit lower than 0.5%"
        );

        _maxTxAmount = newLimit;
    }

    function rescueStuckDividends() external simpleGuard {
        IERC20(rewardToken).transfer(
            _marketingAddress,
            IERC20(rewardToken).balanceOf(address(this))
        );
    }

    function rescueStuckBNB(uint256 amount) external simpleGuard {
        payable(_marketingAddress).transfer(amount);
    }
}