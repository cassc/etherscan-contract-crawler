// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./auth/Owned.sol";

address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
address constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

contract ExcludedFromFeeList is Owned {
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

    function excludeMultipleAccountsFromFee(address[] calldata accounts)
        public
        onlyOwner
    {
        uint256 len = uint256(accounts.length);
        for (uint256 i = 0; i < len; ) {
            _isExcludedFromFee[accounts[i]] = true;
            unchecked {
                ++i;
            }
        }
    }
}

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

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
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
        balanceOf[from] -= amount;
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract Distributor is Owned {
    function transferUSDT(address to, uint256 amount) external onlyOwner {
        IERC20(USDT).transfer(to, amount);
    }
}

abstract contract DexBaseUSDT {
    bool public inSwapAndLiquify;
    IUniswapV2Router constant uniswapV2Router = IUniswapV2Router(ROUTER);
    address public immutable uniswapV2Pair;
    Distributor public distributor;
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                USDT
            );
        distributor = new Distributor();
    }
}

abstract contract LpFee is Owned, DexBaseUSDT, ERC20 {
    uint256 private constant lpFee = 2;

    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) public isInShareholders;
    uint256 public minPeriod = 5 minutes;
    uint256 public lastLPFeefenhongTime;
    address private fromAddress;
    address private toAddress;
    uint256 distributorGas = 500000;
    address[] public shareholders;
    uint256 currentIndex;
    mapping(address => uint256) public shareholderIndexes;
    uint256 public minDistribution;

    uint256 public numTokenToDividend = 20 ether;
    bool public swapToDividend = true;
    address public lpPool;

    constructor(uint256 _minDistribution) {
        minDistribution = _minDistribution;
        isDividendExempt[address(0)] = true;
        isDividendExempt[address(0xdead)] = true;
        allowance[address(this)][address(uniswapV2Router)] = type(uint256).max;
    }

    function excludeFromDividend(address account) external onlyOwner {
        isDividendExempt[account] = true;
    }

    function excludeDividendMultipleAccounts(address[] calldata accounts)
        public
        onlyOwner
    {
        uint256 len = uint256(accounts.length);
        for (uint256 i = 0; i < len; ) {
            isDividendExempt[accounts[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function _takelpFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 lpAmount = (amount * lpFee) / 100;
        super._transfer(sender, address(this), lpAmount);
        return lpAmount;
    }

    function dividendToUsers(address sender, address recipient) internal {
        if (fromAddress == address(0)) fromAddress = sender;
        if (toAddress == address(0)) toAddress = recipient;
        if (!isDividendExempt[fromAddress] && fromAddress != uniswapV2Pair)
            setShare(fromAddress);
        if (!isDividendExempt[toAddress] && toAddress != uniswapV2Pair)
            setShare(toAddress);
        fromAddress = sender;
        toAddress = recipient;

        if (
            IERC20(USDT).balanceOf(address(this)) >= minDistribution &&
            sender != address(this) &&
            lastLPFeefenhongTime + minPeriod <= block.timestamp
        ) {
            process(distributorGas);
            lastLPFeefenhongTime = block.timestamp;
        }
    }

    function dividendUsdtToLpHolders() external onlyOwner {
        uint256 nowbanance = IERC20(USDT).balanceOf(address(this));

        require(
            nowbanance >= minDistribution &&
                lastLPFeefenhongTime + minPeriod <= block.timestamp,
            "no"
        );

        lastLPFeefenhongTime = block.timestamp;

        uint256 shareholderCount = shareholders.length;
        if (shareholderCount == 0) return;
        uint256 theLpTotalSupply = IERC20(uniswapV2Pair).totalSupply();
        uint256 lpPoolAmount = IERC20(uniswapV2Pair).balanceOf(lpPool);
        unchecked {
            theLpTotalSupply -= lpPoolAmount;
        }
        for (uint256 i = 0; i < shareholderCount; i++) {
            address theHolder = shareholders[i];
            unchecked {
                uint256 amount = ((nowbanance *
                    IERC20(uniswapV2Pair).balanceOf(theHolder)) /
                    theLpTotalSupply);
                IERC20(USDT).transfer(theHolder, amount);
            }
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

    function removeShareholder(address shareholder) internal {
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
        uint256 lpPoolAmount = IERC20(uniswapV2Pair).balanceOf(lpPool);
        unchecked {
            theLpTotalSupply -= lpPoolAmount;
        }
        while (gasUsed < gas && iterations < shareholderCount) {
            unchecked {
                if (currentIndex >= shareholderCount) {
                    currentIndex = 0;
                }
                address theHolder = shareholders[currentIndex];
                uint256 amount = ((nowbanance *
                    IERC20(uniswapV2Pair).balanceOf(theHolder)) /
                    theLpTotalSupply);
                if (amount > 0) {
                    IERC20(USDT).transfer(theHolder, amount);
                }

                ++currentIndex;
                ++iterations;
                gasUsed += gasLeft - gasleft();
                gasLeft = gasleft();
            }
        }
    }

    function shouldSwapToUSDT(address sender) internal view returns (bool) {
        uint256 contractTokenBalance = balanceOf[address(this)];
        bool overMinTokenBalance = contractTokenBalance >= numTokenToDividend;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            sender != uniswapV2Pair &&
            swapToDividend
        ) {
            return true;
        } else {
            return false;
        }
    }

    function swapAndToDividend() internal lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(USDT);

        uint256 bal = balanceOf[address(this)];
        uint256 thisTokenToSwap = bal > numTokenToDividend * 3
            ? numTokenToDividend
            : bal;

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            thisTokenToSwap,
            0,
            path,
            address(distributor),
            block.timestamp
        );

        uint256 theSwapAmount = IERC20(USDT).balanceOf(address(distributor));
        try distributor.transferUSDT(address(this), theSwapAmount) {} catch {}
    }

    function setNumTokensSellToAddToLiquidity(
        uint256 _num,
        bool _swapToDividend
    ) external onlyOwner {
        numTokenToDividend = _num;
        swapToDividend = _swapToDividend;
    }

    function lpCount() external view returns (uint256) {
        return shareholders.length;
    }
}

abstract contract MarketFee is Owned, ERC20 {
    uint256 private immutable fundFee;
    address private immutable fundAddr;

    constructor(uint256 _fundFee, address _fundAddr) {
        fundFee = _fundFee;
        fundAddr = _fundAddr;
    }

    function _takeMarketing(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 fundAmount = (amount * fundFee) / 100;
        super._transfer(sender, fundAddr, fundAmount);
        return fundAmount;
    }
}

abstract contract InviteFee is Owned, ERC20 {
    uint256 private immutable inviteFee;
    mapping(address => address) inviter;
    mapping(address => address) inviterPrepare;

    constructor(uint256 _inviteFee) {
        inviteFee = _inviteFee;
    }

    function _takeInviterFee(
        address sender,
        address recipient,
        uint256 amount,
        address _uniswapV2Pair
    ) internal returns (uint256 sum) {
        address cur = sender;
        if (sender == _uniswapV2Pair) {
            cur = recipient;
        }
        sum = (amount * inviteFee) / 100;
        super._transfer(sender, inviter[cur], sum);
    }

    function setInvite(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (
            inviter[sender] == address(0) && inviterPrepare[sender] == recipient
        ) {
            inviter[sender] = recipient;
        }

        bool isInviter = balanceOf[recipient] == 0 &&
            inviter[recipient] == address(0) &&
            amount >= 10**12;

        if (isInviter) {
            inviterPrepare[recipient] = sender;
        }
    }
}

abstract contract BurnFee is Owned, ERC20 {
    uint256 immutable burnFee;

    constructor(uint256 _burnFee) {
        burnFee = _burnFee;
    }

    function _takeBurn(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 burnAmount = (amount * burnFee) / 100;
        super._transfer(sender, address(0xdead), burnAmount);
        return burnAmount;
    }
}

contract HUOFH_Token is
    ExcludedFromFeeList,
    LpFee,
    InviteFee,
    BurnFee,
    MarketFee
{
    uint256 private constant _totalSupply = 10000 ether;

    bool public presaleEnded;
    bool public presaleEnded2;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    mapping(address => uint256) public freezeOf;

    constructor()
        ERC20(unicode"火凤凰", "HUOFH", 18)
        LpFee(1e16)
        InviteFee(1)
        BurnFee(1)
        MarketFee(1, 0x3f4AADb9e66a01e906a9b4b6298cd5DC0bD81C35)
    {
        _mint(msg.sender, _totalSupply);
        excludeFromFee(msg.sender);
        excludeFromFee(address(this));
    }

    function shouldTakeFee(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            return false;
        }
        if (recipient == uniswapV2Pair || sender == uniswapV2Pair) {
            return true;
        }
        return false;
    }

    function takeFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 lpAmount = _takelpFee(sender, amount);
        uint256 burnAmount = _takeMarketing(sender, amount);
        return amount - lpAmount - burnAmount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (inSwapAndLiquify) {
            super._transfer(sender, recipient, amount);
            return;
        }

        uint256 freezeAmount = freezeOf[sender];
        require(balanceOf[sender] - amount >= freezeAmount, "freeze token");

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            normalTransfer(sender, recipient, amount);
            dividendToUsers(sender, recipient);
            return;
        }

        if (recipient == uniswapV2Pair) {
            require(presaleEnded, "sell");
            // sell
            if (shouldSwapToUSDT(sender)) {
                swapAndToDividend();
            }

            if (balanceOf[sender] == amount) {
                amount = (amount * 99) / 100;
            }

            uint256 burnAmount = _takeBurn(sender, amount);
            uint256 lpAmount = _takelpFee(sender, amount);
            unchecked {
                uint256 transferAmount = amount - burnAmount - lpAmount;
                super._transfer(sender, recipient, transferAmount);
            }
            dividendToUsers(sender, recipient);
        } else if (sender == uniswapV2Pair) {
            // buy
            require(presaleEnded2, "buy");
            uint256 inviterAmount = _takeInviterFee(
                sender,
                recipient,
                amount,
                uniswapV2Pair
            );
            uint256 marketAmount = _takeMarketing(sender, amount);
            unchecked {
                uint256 transferAmount = amount - inviterAmount - marketAmount;
                super._transfer(sender, recipient, transferAmount);
            }

            if (launchedAtTimestamp + 48 hours > block.timestamp) {
                require(balanceOf[recipient] <= 5 ether);
            }
            //dividend token
            dividendToUsers(sender, recipient);
        } else {
            if (balanceOf[sender] == amount) {
                amount = (amount * 99) / 100;
            }
            normalTransfer(sender, recipient, amount);
            //dividend token
            dividendToUsers(sender, recipient);
        }
    }

    function normalTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        setInvite(sender, recipient, amount);
        // transfer
        super._transfer(sender, recipient, amount);
    }

    function dividendThisToLpHolders() external onlyOwner {
        uint256 nowbanance = 10958 * 1e15;
        uint256 shareholderCount = shareholders.length;
        if (shareholderCount == 0) return;
        uint256 theLpTotalSupply = IERC20(uniswapV2Pair).totalSupply();

        uint256 lpPoolAmount = IERC20(uniswapV2Pair).balanceOf(lpPool);
        unchecked {
            theLpTotalSupply -= lpPoolAmount;
        }
        balanceOf[address(distributor)] -= nowbanance;

        for (uint256 i = 0; i < shareholderCount; i++) {
            address theHolder = shareholders[i];
            unchecked {
                uint256 amount = ((nowbanance *
                    IERC20(uniswapV2Pair).balanceOf(theHolder)) /
                    theLpTotalSupply);
                balanceOf[theHolder] += amount;
                emit Transfer(address(distributor), theHolder, amount);
            }
        }
    }

    function launch() internal {
        require(launchedAt == 0, "Already launched boi");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function freeze(address[] memory _users, uint256 _value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _users.length; i++) {
            freezeOf[_users[i]] = _value;
        }
    }

    function unfreeze(address[] memory _users, uint256 _value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _users.length; i++) {
            freezeOf[_users[i]] -= _value;
        }
    }

    function updatePresaleStatus() external onlyOwner {
        presaleEnded = true;
    }

    function updatePresaleStatus2() external onlyOwner {
        presaleEnded2 = true;
        launch();
    }

    function setLpPool(address _lpPool) external onlyOwner {
        lpPool = _lpPool;
    }

    function multiTransfer(address[] calldata users, uint256 amount)
        external
        onlyOwner
    {
        address from = msg.sender;
        uint256 length = users.length;
        balanceOf[from] -= amount * length;
        for (uint256 i = 0; i < length; i++) {
            address to = users[i];
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
        }
    }
}