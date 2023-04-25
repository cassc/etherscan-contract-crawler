/**
 *Submitted for verification at BscScan.com on 2023-04-24
*/

/**                                                                                                                                                                                                                                                        

*/
//SPDX-License-Identifier: Unlicensed                                                                                                                                                                                



pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IPancakePair {
    function sync() external;
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FlokiKing is IERC20, Ownable {
    using SafeMath for uint256;

    address constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string _name = "Floki King";
    string _symbol = "Floki King";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100 * 10**9 * 10**_decimals;
    uint256 public _maxTxAmount = (_totalSupply * 3) / 100;
    uint256 public _maxWalletSize = (_totalSupply * 3) / 100; // 1%

    /* rOwned = ratio of tokens owned relative to circulating supply (NOT total supply, since circulating <= total) */
    mapping(address => uint256) public _rOwned;
    uint256 public _totalProportion = _totalSupply;

    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isReflectionExempt;
    mapping(address => bool) isTxLimitExempt;

    uint256 liquidityFeeBuy = 0;
    uint256 liquidityFeeSell = 0;

    uint256 buybackFeeBuy = 0;
    uint256 buybackFeeSell = 0;

    uint256 marketingFeeBuy = 5;
    uint256 marketingFeeSell = 5;

    uint256 reflectionFeeBuy = 0;
    uint256 reflectionFeeSell = 0;

    uint256 totalFeeBuy =
        marketingFeeBuy + liquidityFeeBuy + buybackFeeBuy + reflectionFeeBuy;
    uint256 totalFeeSell =
        marketingFeeSell +
            liquidityFeeSell +
            buybackFeeSell +
            reflectionFeeSell;

    uint256 feeDenominator = 100;

    address autoLiquidityReceiver;
    address marketingFeeReceiver;
    address buybackFeeReceiver;

    uint256 targetLiquidity = 100;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    bool public claimingFees = true;
    bool alternateSwaps = true;
    uint256 smallSwapThreshold = (_totalSupply * 25) / 10000; //.25%
    uint256 largeSwapThreshold = (_totalSupply * 25) / 10000; 

    uint256 public swapThreshold = smallSwapThreshold;
    bool inSwap;

    //Whitelist
    bool public whitelistEnabled = false;
    bool public whitelistRenounced = false;
    mapping(address => bool) isWhitelisted;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        router = IDEXRouter(ROUTER);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[address(this)][msg.sender] = type(uint256).max;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[msg.sender] = true;
        isFeeExempt[msg.sender] = true;

        autoLiquidityReceiver = msg.sender;
        buybackFeeReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;

        _rOwned[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function changeName(string memory newName) external onlyOwner {
        _name = newName;
    }

    function changeSymbol(string memory newSymbol) external onlyOwner {
        _symbol = newSymbol;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function viewFeesBuy()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            liquidityFeeBuy,
            marketingFeeBuy,
            buybackFeeSell,
            reflectionFeeBuy,
            totalFeeBuy,
            feeDenominator
        );
    }

    function viewFeesSell()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            liquidityFeeSell,
            marketingFeeSell,
            buybackFeeSell,
            reflectionFeeSell,
            totalFeeSell,
            feeDenominator
        );
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(
            !whitelistEnabled || isWhitelisted[sender],
            "Whitelist enabled and sender not whitelisted"
        );

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (
            recipient != pair &&
            recipient != DEAD &&
            recipient != marketingFeeReceiver &&
            !isTxLimitExempt[recipient]
        ) {
            require(
                balanceOf(recipient) + amount <= _maxWalletSize,
                "Max Wallet Exceeded"
            );
        }

        if (!isTxLimitExempt[sender]) {
            require(amount <= _maxTxAmount, "Transaction Exceeded");
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        uint256 proportionAmount = tokensToProportion(amount);

        _rOwned[sender] = _rOwned[sender].sub(
            proportionAmount,
            "Insufficient Balance"
        );

        uint256 proportionReceived = shouldTakeFee(sender) &&
            shouldTakeFee(recipient)
            ? takeFeeInProportions(
                sender == pair ? true : false,
                sender,
                proportionAmount
            )
            : proportionAmount;
        _rOwned[recipient] = _rOwned[recipient].add(proportionReceived);

        emit Transfer(
            sender,
            recipient,
            tokenFromReflection(proportionReceived)
        );
        return true;
    }

    function tokensToProportion(uint256 tokens) public view returns (uint256) {
        return tokens.mul(_totalProportion).div(_totalSupply);
    }

    function tokenFromReflection(uint256 proportion)
        public
        view
        returns (uint256)
    {
        return proportion.mul(_totalSupply).div(_totalProportion);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        uint256 proportionAmount = tokensToProportion(amount);
        _rOwned[sender] = _rOwned[sender].sub(
            proportionAmount,
            "Insufficient Balance"
        );
        _rOwned[recipient] = _rOwned[recipient].add(proportionAmount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    function getTotalFeeBuy() public view returns (uint256) {
        return totalFeeBuy;
    }

    function getTotalFeeSell() public view returns (uint256) {
        return totalFeeSell;
    }

    function takeFeeInProportions(
        bool buying,
        address sender,
        uint256 proportionAmount
    ) internal returns (uint256) {
        uint256 proportionFeeAmount = buying == true
            ? proportionAmount.mul(getTotalFeeBuy()).div(feeDenominator)
            : proportionAmount.mul(getTotalFeeSell()).div(feeDenominator);

        // reflect
        uint256 proportionReflected = buying == true
            ? proportionFeeAmount.mul(reflectionFeeBuy).div(totalFeeBuy)
            : proportionFeeAmount.mul(reflectionFeeSell).div(totalFeeSell);

        _totalProportion = _totalProportion.sub(proportionReflected);

        // take fees
        uint256 _proportionToContract = proportionFeeAmount.sub(
            proportionReflected
        );
        _rOwned[address(this)] = _rOwned[address(this)].add(
            _proportionToContract
        );

        emit Transfer(
            sender,
            address(this),
            tokenFromReflection(_proportionToContract)
        );
        emit Reflect(proportionReflected, _totalProportion);
        return proportionAmount.sub(proportionFeeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            claimingFees &&
            balanceOf(address(this)) >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : liquidityFeeSell;
        uint256 _totalFee = totalFeeSell.sub(reflectionFeeSell);
        uint256 amountToLiquify = swapThreshold
            .mul(dynamicLiquidityFee)
            .div(_totalFee)
            .div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBFee = _totalFee.sub(dynamicLiquidityFee.div(2));
        uint256 amountBNBLiquidity = amountBNB
            .mul(liquidityFeeSell)
            .div(totalBNBFee)
            .div(2);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFeeSell).div(
            totalBNBFee
        );
        uint256 amountBNBdev = amountBNB.mul(buybackFeeSell).div(totalBNBFee);

        (bool tmpSuccess, ) = payable(marketingFeeReceiver).call{
            value: amountBNBMarketing,
            gas: 30000
        }("");
        (tmpSuccess, ) = payable(buybackFeeReceiver).call{
            value: amountBNBdev,
            gas: 30000
        }("");

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }

        swapThreshold = !alternateSwaps
            ? swapThreshold
            : swapThreshold == smallSwapThreshold
            ? largeSwapThreshold
            : smallSwapThreshold;
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _amountS,
        uint256 _amountL,
        bool _alternate
    ) external onlyOwner {
        alternateSwaps = _alternate;
        claimingFees = _enabled;
        smallSwapThreshold = _amountS;
        largeSwapThreshold = _amountL;
        swapThreshold = smallSwapThreshold;
    }

    function changeFees(
        uint256 _liquidityFeeBuy,
        uint256 _reflectionFeeBuy,
        uint256 _marketingFeeBuy,
        uint256 _buybackFeeBuy,
        uint256 _liquidityFeeSell,
        uint256 _reflectionFeeSell,
        uint256 _marketingFeeSell,
        uint256 _buybackFeeSell
    ) external onlyOwner {
        liquidityFeeBuy = _liquidityFeeBuy;
        reflectionFeeBuy = _reflectionFeeBuy;
        marketingFeeBuy = _marketingFeeBuy;
        buybackFeeBuy = _buybackFeeBuy;
        totalFeeBuy = liquidityFeeBuy
            .add(reflectionFeeBuy)
            .add(marketingFeeBuy)
            .add(buybackFeeBuy);

        liquidityFeeSell = _liquidityFeeSell;
        reflectionFeeSell = _reflectionFeeSell;
        marketingFeeSell = _marketingFeeSell;
        buybackFeeSell = _buybackFeeSell;
        totalFeeSell = liquidityFeeSell
            .add(reflectionFeeSell)
            .add(marketingFeeSell)
            .add(buybackFeeSell);

        require(totalFeeBuy <= 25, "Cannot set buy fees above 25%"); 
        require(totalFeeSell <= 25, "Cannot set sell fees above 25%"); 
    }

    function SetMaxWalletPercent_base1000(uint256 maxWallPercent_base1000)
        external
        onlyOwner
    {
        require(
            maxWallPercent_base1000 >= 1,
            "Cannot set max Wallet below .1%"
        );
        _maxWalletSize = (_totalSupply * maxWallPercent_base1000) / 1000;
    }

    function SetMaxTxPercent_base1000(uint256 maxTXPercentage_base1000)
        external
        onlyOwner
    {
        require(maxTXPercentage_base1000 >= 1, "Cannot set max TX below .1%");
        _maxTxAmount = (_totalSupply * maxTXPercentage_base1000) / 1000;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setFeeReceivers(
        address _marketingFeeReceiver,
        address _buybackFeeReceiver,
        address _liquidityReceiver
    ) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
        autoLiquidityReceiver = _liquidityReceiver;
        buybackFeeReceiver = _buybackFeeReceiver;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy)
        public
        view
        returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }

    function multiAirdrop(
        address[] calldata addresses,
        uint256[] calldata tokens
    ) external onlyOwner {
        require(
            addresses.length < 501,
            "GAS Error: max airdrop limit is 500 addresses"
        );
        require(
            addresses.length == tokens.length,
            "Mismatch between Address and token count"
        );

        uint256 antibot = 0;

        for (uint256 i = 0; i < addresses.length; i++) {
            antibot = antibot + tokens[i];
        }

        require(
            balanceOf(msg.sender) >= antibot,
            "Not enough tokens in wallet"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            _basicTransfer(msg.sender, addresses[i], tokens[i]);
        }
    }

    function manageWhitelist(address[] memory addresses, bool whitelisted)
        external
        onlyOwner
    {
        require(
            addresses.length < 501,
            "GAS Error: max limit is 500 addresses"
        );
        for (uint256 i; i < addresses.length; ++i) {
            isWhitelisted[addresses[i]] = whitelisted;
        }
    }

    function enableWhitelistMode(bool enableWhitelist) external onlyOwner {
        require(!whitelistRenounced || !enableWhitelist);
        whitelistEnabled = enableWhitelist;
    }

    function renounceWhitelist() external onlyOwner {
        whitelistRenounced = true;
    }

    function clearStuckBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
    event Reflect(uint256 amountReflected, uint256 newTotalProportion);
}