/**

https://realfinesmurf.com
https://t.me/RealFineSmurf
https://twitter.com/realfinesmurf

*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
    function allowance(address owner, address spender) external view returns (uint256);

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

pragma solidity ^0.8.19;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address UNISWAP_V2_PAIR);
}

contract SMURF is IERC20, Ownable {

    event Reflect(uint256 amountReflected, uint256 newTotalProportion);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    uint256 constant MAX_FEE = 10;

    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable UNISWAP_V2_PAIR;
    mapping(address => bool) public automatedMarketMakerPairs;

    struct Fee {
        uint8 reflection;
        uint8 marketing;
        uint8 lp;
        uint8 buyback;
        uint8 burn;
        uint128 total;
    }

    string _name = "Real Fine Smurf";
    string _symbol = unicode"смурф";

    uint256 _totalSupply = 69_420_000_000 ether;
    uint256 public _maxTxAmount = _totalSupply * 10 / 1000;
    uint256 public _maxWalletAmount = _totalSupply * 20 / 1000;

    /* rOwned = ratio of tokens owned relative to circulating supply (NOT total supply, since circulating <= total) */
    mapping(address => uint256) public _rOwned;
    uint256 public _totalProportion = _totalSupply;

    mapping(address => mapping(address => uint256)) _allowances;

    bool public tradingActive = false;
    bool public transferDelayEnabled = false;
    bool public limitsEnabled = true;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isLimitExempt;

    Fee public buyFee = Fee({reflection: 0, marketing: 25, lp: 0, buyback: 0, burn: 0, total: 25});
    Fee public sellFee = Fee({reflection: 0, marketing: 35, lp: 0, buyback: 0, burn: 0, total: 35});

    address private marketingFeeReceiver;
    address private lpFeeReceiver;
    address private buybackFeeReceiver;

    bool public claimingFees = false;
    uint256 public swapThreshold = (_totalSupply * 3) / 1000;
    bool inSwap;
    mapping(address => bool) public blacklists;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        // create uniswap pair
        address _uniswapPair =
            IUniswapV2Factory(UNISWAP_V2_ROUTER.factory()).createPair(address(this), UNISWAP_V2_ROUTER.WETH());
        UNISWAP_V2_PAIR = _uniswapPair;
        _setAutomatedMarketMakerPair(address(_uniswapPair), true);

        _allowances[address(this)][address(UNISWAP_V2_ROUTER)] = type(uint256).max;
        _allowances[address(this)][owner()] = type(uint256).max;

        isLimitExempt[address(this)] = true;
        isLimitExempt[DEAD] = true;
        isLimitExempt[owner()] = true;
        isLimitExempt[UNISWAP_V2_PAIR] = true;
        
        isFeeExempt[address(this)] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[owner()] = true;

        marketingFeeReceiver = 0x7bfe1B0bc8f69c7098F95Df566CCB49A121f4bA1;
        lpFeeReceiver = 0x7bfe1B0bc8f69c7098F95Df566CCB49A121f4bA1;
        buybackFeeReceiver = 0x7bfe1B0bc8f69c7098F95Df566CCB49A121f4bA1;

        _rOwned[tx.origin] = _totalSupply;
        emit Transfer(address(0), tx.origin, _totalSupply);
    }

    receive() external payable {}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(_allowances[sender][msg.sender] >= amount, "ERC20: insufficient allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function tokensToProportion(uint256 tokens) public view returns (uint256) {
        return tokens * _totalProportion / _totalSupply;
    }

    function tokenFromReflection(uint256 proportion) public view returns (uint256) {
        return proportion * _totalSupply / _totalProportion;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;
        claimingFees = true;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != UNISWAP_V2_PAIR,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((_totalSupply * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        _maxTxAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((_totalSupply * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        _maxWalletAmount = newNum * (10**18);
    }

    function clearStuckBalance() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function clearStuckToken() external onlyOwner {
        _transferFrom(address(this), msg.sender, balanceOf(address(this)));
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        claimingFees = _enabled;
        swapThreshold = _amount;
    }

    function changeFees(
        uint8 reflectionFeeBuy,
        uint8 marketingFeeBuy,
        uint8 lpFeeBuy,
        uint8 buybackFeeBuy,
        uint8 burnFeeBuy,
        uint8 reflectionFeeSell,
        uint8 marketingFeeSell,
        uint8 lpFeeSell,
        uint8 buybackFeeSell,
        uint8 burnFeeSell
    ) external onlyOwner {
        uint128 __totalBuyFee = reflectionFeeBuy + marketingFeeBuy + lpFeeBuy + buybackFeeBuy + burnFeeBuy;
        uint128 __totalSellFee = reflectionFeeSell + marketingFeeSell + lpFeeSell + buybackFeeSell + burnFeeSell;

        buyFee = Fee({
            reflection: reflectionFeeBuy,
            marketing: marketingFeeBuy,
            lp: lpFeeBuy,
            buyback: buybackFeeBuy,
            burn: burnFeeBuy,
            total: __totalBuyFee
        });

        sellFee = Fee({
            reflection: reflectionFeeSell,
            marketing: marketingFeeSell,
            lp: lpFeeSell,
            buyback: buybackFeeSell,
            burn: burnFeeSell,
            total: __totalSellFee
        });
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setisLimitExempt(address holder, bool exempt) external onlyOwner {
        isLimitExempt[holder] = exempt;
    }

    function setFeeReceivers(address m_, address lp_, address b_) external onlyOwner {
        marketingFeeReceiver = m_;
        lpFeeReceiver = lp_;
        buybackFeeReceiver = b_;
    }

    function setLimitsEnabled(bool e_) external onlyOwner {
        limitsEnabled = e_;
    }

    // Set Transfer delay
    function disableTransferDelay(bool e_) external onlyOwner returns (bool) {
        transferDelayEnabled = e_;
        return true;
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(!blacklists[recipient] && !blacklists[sender], "Blacklisted");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (limitsEnabled) {
            if (!tradingActive) 
            {
                require(
                    isFeeExempt[sender] || isFeeExempt[recipient],
                    "Trading is not active."
                );
            }

            //when buy
            if (automatedMarketMakerPairs[sender] && !isLimitExempt[recipient]) 
            {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
                require(amount + balanceOf(recipient) <= _maxWalletAmount, "Max wallet exceeded");
            }
            //when sell
            else if (automatedMarketMakerPairs[recipient] && !isLimitExempt[sender])
            {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }
            else if (!isLimitExempt[recipient]) 
            {
                require(amount + balanceOf(recipient) <= _maxWalletAmount, "Max wallet exceeded");
            }
            
            // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
            if (transferDelayEnabled) {
                if (
                    recipient != owner() &&
                    recipient != address(UNISWAP_V2_ROUTER) &&
                    recipient != UNISWAP_V2_PAIR
                ) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] + 1 <
                            block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per two blocks allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }
        }

        if (_shouldSwapBack()) {
            _swapBack();
        }

        uint256 proportionAmount = tokensToProportion(amount);
        require(_rOwned[sender] >= proportionAmount, "Insufficient Balance");
        _rOwned[sender] = _rOwned[sender] - proportionAmount;

        uint256 proportionReceived = _shouldTakeFee(sender, recipient)
            ? _takeFeeInProportions(sender == UNISWAP_V2_PAIR ? true : false, sender, proportionAmount)
            : proportionAmount;
        _rOwned[recipient] = _rOwned[recipient] + proportionReceived;

        emit Transfer(sender, recipient, tokenFromReflection(proportionReceived));
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 proportionAmount = tokensToProportion(amount);
        require(_rOwned[sender] >= proportionAmount, "Insufficient Balance");
        _rOwned[sender] = _rOwned[sender] - proportionAmount;
        _rOwned[recipient] = _rOwned[recipient] + proportionAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _takeFeeInProportions(bool buying, address sender, uint256 proportionAmount) internal returns (uint256) {
        Fee memory __buyFee = buyFee;
        Fee memory __sellFee = sellFee;

        uint256 proportionFeeAmount =
            buying == true ? proportionAmount * __buyFee.total / 100 : proportionAmount * __sellFee.total / 100;

        // reflect
        uint256 proportionReflected = buying == true
            ? proportionFeeAmount * __buyFee.reflection / __buyFee.total
            : proportionFeeAmount * __sellFee.reflection / __sellFee.total;

        _totalProportion = _totalProportion - proportionReflected;

        // take fees
        uint256 _proportionToContract = proportionFeeAmount - proportionReflected;
        if (_proportionToContract > 0) {
            _rOwned[address(this)] = _rOwned[address(this)] + _proportionToContract;

            emit Transfer(sender, address(this), tokenFromReflection(_proportionToContract));
        }
        emit Reflect(proportionReflected, _totalProportion);
        return proportionAmount - proportionFeeAmount;
    }

    function _shouldSwapBack() internal view returns (bool) {
        return msg.sender != UNISWAP_V2_PAIR && !inSwap && claimingFees && balanceOf(address(this)) >= swapThreshold;
    }

    function _swapBack() internal swapping {
        Fee memory __sellFee = sellFee;

        uint256 __swapThreshold = swapThreshold;
        uint256 amountToBurn = __swapThreshold * __sellFee.burn / __sellFee.total;
        uint256 amountToSwap = __swapThreshold - amountToBurn;
        approve(address(UNISWAP_V2_ROUTER), amountToSwap);

        if(amountToBurn > 0)
        {
            // burn
            _transferFrom(address(this), DEAD, amountToBurn);
        }

        // swap
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_V2_ROUTER.WETH();

        UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap, 0, path, address(this), block.timestamp
        );

        uint256 amountETH = address(this).balance;

        uint256 totalSwapFee = __sellFee.total - __sellFee.reflection - __sellFee.burn;
        uint256 amountETHMarketing = amountETH * __sellFee.marketing / totalSwapFee;
        uint256 amountETHLP = amountETH * __sellFee.lp / totalSwapFee;
        uint256 amountETHBuyback = amountETH * __sellFee.buyback / totalSwapFee;

        // send
        (bool tmpSuccess,) = payable(lpFeeReceiver).call{value: amountETHLP}("");
        (tmpSuccess,) = payable(buybackFeeReceiver).call{value: amountETHBuyback}("");
        (tmpSuccess,) = address(marketingFeeReceiver).call{value: address(this).balance}("");
    }

    function _shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }
}