/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IPancakePair {
    function sync() external;
}

interface IDEXRouter {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
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

contract Nobody is IERC20, Ownable {
    using SafeMath for uint256;

    address constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string _name = "Nobody";
    string _symbol = "NOBODY";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 10 * 10 ** 9 * 10 ** _decimals;

    /* rOwned = ratio of tokens owned relative to circulating supply (NOT total supply, since circulating <= total) */
    mapping(address => uint256) public _rOwned;
    uint256 public _totalProportion = _totalSupply;

    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;

    uint256 teamFeeBuy = 0;
    uint256 marketingFeeBuy = 3;
    uint256 reflectionFeeBuy = 2;

    uint256 teamFeeSell = 1;
    uint256 marketingFeeSell = 4;
    uint256 reflectionFeeSell = 2;

    uint256 feeDenominator = 100;

    uint256 totalFeeBuy = marketingFeeBuy + teamFeeBuy + reflectionFeeBuy;
    uint256 totalFeeSell = marketingFeeSell + teamFeeSell + reflectionFeeSell;

    address marketingFeeReceiver;
    address teamFeeReceiver;

    IDEXRouter public router;
    address public pair;

    address public feeExemptSetter;

    bool public tradingOpen = false;

    bool public claimingFees = true;
    bool alternateSwaps = true;
    uint256 smallSwapThreshold = (_totalSupply * 2) / 1000;
    uint256 largeSwapThreshold = (_totalSupply * 3) / 1000;

    uint256 public swapThreshold = smallSwapThreshold;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyFeeExemptSetter() {
        require(msg.sender == feeExemptSetter, "Not fee exempt setter");
        _;
    }

    constructor() {
        router = IDEXRouter(ROUTER);
        pair = IDEXFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[address(this)][msg.sender] = type(uint256).max;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        feeExemptSetter = msg.sender;
        teamFeeReceiver = 0xed339F87D5A6d3F10EFe49151bda437Cd71C5a07;
        marketingFeeReceiver = 0xed339F87D5A6d3F10EFe49151bda437Cd71C5a07;

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

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function viewFeesBuy()
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256)
    {
        return (
            marketingFeeBuy,
            teamFeeBuy,
            reflectionFeeBuy,
            totalFeeBuy,
            feeDenominator
        );
    }

    function viewFeesSell()
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256)
    {
        return (
            marketingFeeSell,
            teamFeeSell,
            reflectionFeeSell,
            totalFeeSell,
            feeDenominator
        );
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
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
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (
            recipient != pair &&
            recipient != DEAD &&
            !isTxLimitExempt[recipient]
        ) {
            require(tradingOpen, "Trading not open yet");
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        uint256 proportionAmount = tokensToProportion(amount);

        _rOwned[sender] = _rOwned[sender].sub(
            proportionAmount,
            "Insufficient Balance"
        );

        uint256 proportionReceived = shouldTakeFee(sender, recipient)
            ? takeFeeInProportions(
                sender == pair ? true : false,
                sender,
                recipient,
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

    function tokenFromReflection(
        uint256 proportion
    ) public view returns (uint256) {
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

    function shouldTakeFee(
        address sender,
        address recipient
    ) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function getTotalFeeBuy(bool) public view returns (uint256) {
        return totalFeeBuy;
    }

    function getTotalFeeSell(bool) public view returns (uint256) {
        return totalFeeSell;
    }

    function takeFeeInProportions(
        bool buying,
        address sender,
        address receiver,
        uint256 proportionAmount
    ) internal returns (uint256) {
        uint256 proportionFeeAmount = buying == true
            ? proportionAmount.mul(getTotalFeeBuy(receiver == pair)).div(
                feeDenominator
            )
            : proportionAmount.mul(getTotalFeeSell(receiver == pair)).div(
                feeDenominator
            );

        // reflect
        uint256 proportionReflected = buying == true
            ? proportionFeeAmount.mul(reflectionFeeBuy).div(totalFeeBuy)
            : proportionFeeAmount.mul(reflectionFeeSell).div(totalFeeSell);

        _totalProportion = _totalProportion.sub(proportionReflected);

        // take fees
        uint256 _proportionToContract = proportionFeeAmount.sub(
            proportionReflected
        );
        if (_proportionToContract > 0) {
            _rOwned[address(this)] = _rOwned[address(this)].add(
                _proportionToContract
            );

            emit Transfer(
                sender,
                address(this),
                tokenFromReflection(_proportionToContract)
            );
        }
        emit Reflect(proportionReflected, _totalProportion);
        return proportionAmount.sub(proportionFeeAmount);
    }

    function clearStuckBalance() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance,
            gas: 30000
        }("");
        require(success);
    }

    function clearForeignToken(
        address tokenAddress,
        uint256 tokens
    ) public returns (bool) {
        require(isTxLimitExempt[msg.sender]);
        require(tokenAddress != address(this), "Not allowed");
        if (tokens == 0) {
            tokens = IERC20(tokenAddress).balanceOf(address(this));
        }
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            claimingFees &&
            balanceOf(address(this)) >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 _totalFee = totalFeeSell.sub(reflectionFeeSell);
        uint256 amountToSwap = swapThreshold;
        approve(address(router), amountToSwap);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;

        uint256 totalBNBFee = _totalFee;
        uint256 amountBNBMarketing = amountBNB.mul(marketingFeeSell).div(
            totalBNBFee
        );
        uint256 amountBNBteam = amountBNB.mul(teamFeeSell).div(totalBNBFee);

        (bool tmpSuccess, ) = payable(marketingFeeReceiver).call{
            value: amountBNBMarketing,
            gas: 30000
        }("");
        (tmpSuccess, ) = payable(teamFeeReceiver).call{
            value: amountBNBteam,
            gas: 30000
        }("");

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

    function enableTrading() public onlyOwner {
        tradingOpen = true;
    }

    function changeFees(
        uint256 _reflectionFeeBuy,
        uint256 _marketingFeeBuy,
        uint256 _teamFeeBuy,
        uint256 _feeDenominator,
        uint256 _reflectionFeeSell,
        uint256 _marketingFeeSell,
        uint256 _teamFeeSell
    ) external onlyOwner {
        reflectionFeeBuy = _reflectionFeeBuy;
        marketingFeeBuy = _marketingFeeBuy;
        teamFeeBuy = _teamFeeBuy;
        totalFeeBuy = reflectionFeeBuy.add(marketingFeeBuy).add(teamFeeBuy);

        reflectionFeeSell = _reflectionFeeSell;
        marketingFeeSell = _marketingFeeSell;
        teamFeeSell = _teamFeeSell;
        totalFeeSell = reflectionFeeSell.add(marketingFeeSell).add(teamFeeSell);

        feeDenominator = _feeDenominator;

        require(totalFeeBuy <= 10, "Cannot set buy fees above 10%"); // max fee possible
        require(totalFeeSell <= 50, "Cannot set sell fees above 50%"); // max fee possible
    }

    function setIsFeeExempt(
        address holder,
        bool exempt
    ) external onlyFeeExemptSetter {
        isFeeExempt[holder] = exempt;
    }

    function changeFeeExemptSetter(
        address _feeExemptSetter
    ) external onlyFeeExemptSetter {
        feeExemptSetter = _feeExemptSetter;
    }

    function renounceFeeExemptSetter() external onlyFeeExemptSetter {
        feeExemptSetter = address(0);
    }

    function setIsTxLimitExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFeeReceivers(
        address _marketingFeeReceiver,
        address _teamFeeReceiver
    ) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
        teamFeeReceiver = _teamFeeReceiver;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    event Reflect(uint256 amountReflected, uint256 newTotalProportion);
}