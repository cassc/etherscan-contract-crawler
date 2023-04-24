//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
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

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        // require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint256);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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
}

// interface
interface IMarketing {
    function autoAddLp() external; // auto add lp
}

contract Token6827 is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;
    mapping(address => bool) public ammPairs;
    
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public marketingAddress;

    address public usdtAddress = 0x55d398326f99059fF775485246999027B3197955;
    address public tokenReceiver;

    address public migrantAddress;

    uint256 public swapTokensAtAmount = 100e18;

    uint256 public extraSupply;
    uint256 public SPY = 253472222222; //
    uint256 internal staticRewardRequire = 10 ** 18;

    uint256 public holdRefAmount = 2000e18;
    mapping(uint256 => address) public totalUserAddres;
    mapping (address => address) public _recommerMapping;
    mapping(address => mapping(address => bool)) public _refBackMapping;
    uint256 public userTotal = 0;
    address private topAddress; // top user
    address constant public rootAddress = address(0x000000000000000000000000000000000000dEaD);
    
    uint256 public lv2Rate = 210;
    uint256 public limitRate = 22;

    uint256 public startTime;
    uint public dayOfRecord;
    uint256 public marketingPoolAmount = 239047300e18; // inital pool amount
    uint256 public recordMarketingBonus;
    bool public enableMarketingAddLp = true;

    mapping(address => uint256) public lastUpdateTime;
    mapping(address => bool) public rewardBlacklist;

    bool public isInitial = false;
    bool inSwapAndLiquidity;

    mapping (address => bool) private _isExcludedFromFees;

    uint256 private _commonDiv = 1000; //Fee DIV
    uint256 private _buyLiquidityFee = 120; //12% LP
    uint256 private _sellMarketFee = 150; //15% market fee

    event UpdatePancakeRouter(address indexed newAddress, address indexed oldAddress);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    modifier calculateReward(address account) {
        if (account != address(0)) {
            uint256 reward = getReward(account);
            if (reward > 0) {
                _balances[account] = _balances[account].add(reward);
                extraSupply = extraSupply.add(reward);
            }
            lastUpdateTime[account] = block.timestamp;
        }
        _;
    }

    modifier lockTheSwap {
        inSwapAndLiquidity = true;
        _;
        inSwapAndLiquidity = false;
    }

    modifier onlyMigrant{
        require(msg.sender == migrantAddress, "Err migrant contract address");
        _;
    }

    uint256 private constant MAX = type(uint256).max;
    
    constructor() ERC20("6827 Token", "6827") {
        topAddress = msg.sender; 
        _recommerMapping[rootAddress] = address(0xdeaddead);
        _recommerMapping[topAddress] = rootAddress;
        userTotal++;
        totalUserAddres[userTotal] = topAddress;

        updatePancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);  // bsc
        rewardBlacklist[address(this)] = true;
        rewardBlacklist[msg.sender] = true;
        excludeFromAllLimits(msg.sender, true);
        excludeFromAllLimits(address(this), true);
        _isExcludedFromFees[deadAddress] = true;
        rewardBlacklist[deadAddress] = true;

        startTime = block.timestamp;
    }

    function initial(address _receiveAddress, uint256 _initAmount) external onlyOwner {
        require(!isInitial, "Initialized");
        isInitial = true;
        excludeFromAllLimits(_receiveAddress, true);
        _mint(_receiveAddress, _initAmount * 10 ** 18);
    }

    function updatePancakeRouter(address newAddress) public onlyOwner {
        require(newAddress != address(pancakeRouter), "6827: The router already has that address");
        emit UpdatePancakeRouter(newAddress, address(pancakeRouter));
        pancakeRouter = IPancakeRouter02(newAddress);
        address _pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), usdtAddress);
        pancakePair = _pancakePair;
        rewardBlacklist[pancakePair] = true;
        ammPairs[pancakePair] = true;
        excludeFromAllLimits(newAddress, true);
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account].add(getReward(account));
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply.add(extraSupply);
    }

    function getReward(address account) public view returns (uint256) {
        if ( lastUpdateTime[account] == 0 || rewardBlacklist[account] || _balances[account] < staticRewardRequire ) {
            return 0;
        }
        uint256 curnReward;
        if (account != marketingAddress){
            uint256 n = block.timestamp.sub(lastUpdateTime[account]) / 10;
            curnReward = _balances[account].mul(SPY.mul(10)).mul(n).div(10 ** 18);
        } else {
            uint256 n = block.timestamp.sub(lastUpdateTime[account]);
            curnReward = _balances[account].mul(SPY).mul(n).div(10 ** 18);
        }
        return curnReward;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override calculateReward(from) calculateReward(to) {}


    receive() external payable {}

    function excludeFromAllLimits(address account, bool status) public onlyOwner {
        _isExcludedFromFees[account] = status;
    }

    function excludeMultipleFromAllLimits(address[] memory accounts, bool status) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            excludeFromAllLimits(accounts[i], status);
        }
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount;
    }

    function setEnableMarketingAddLp(bool _flag) external onlyOwner{
        enableMarketingAddLp = _flag;
    }

    function setRewardBlacklist(address[] memory accounts, bool status) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            rewardBlacklist[accounts[i]] = status;
        }
    }

    function setConfigParams(uint256 _SPY) external onlyOwner {
        SPY = _SPY;
    }

    function setConfigAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
        excludeFromAllLimits(_marketingAddress, true);
    }

    function setMigrantContract(address _addr) external onlyOwner{
        migrantAddress = _addr;
    }

    function setAmmPair(address pair,bool hasPair) external onlyOwner{
        ammPairs[pair] = hasPair;
        rewardBlacklist[pair] = true;
    }

    function getDay() public view returns (uint256) {
        return (block.timestamp - startTime)/1 days;
    }

    function setStartTime(uint time) external onlyOwner{
        startTime = time;
    }

    function setReferBonusRate(uint256 lv2) external onlyOwner{
        lv2Rate = lv2;
    }
    
    function setLimitRate(uint256 rate) external onlyOwner{
        limitRate = rate;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    // --- refer start ---- //
    event AddRelation(address indexed recommer, address indexed user);

    function addRelation(address recommer,address user) internal {
        if(recommer != user 
            && _recommerMapping[user] == address(0x0) 
            && _recommerMapping[recommer] != address(0x0)){
            _recommerMapping[user] = recommer;
            userTotal++;
            totalUserAddres[userTotal] = user;
            emit AddRelation(recommer, user);
        }
    }

    function getRefBackMapping(address from, address to) public view returns (bool){
        return _refBackMapping[from][to];
    }

    function getRecommer(address addr) public view returns(address){
        return _recommerMapping[addr];
    }

    function getForefathers(address addr,uint num) public view returns(address[] memory fathers) {
        fathers = new address[](num);
        address parent  = addr;
        for( uint i = 0; i < num; i++){
            parent = _recommerMapping[parent];
            if(parent == address(0xdead) || parent == address(0) ) break;
            fathers[i] = parent;
        }
    }

    function addRelationEx(address recommer,address user) external onlyOwner{
        addRelation(recommer, user);
    }

    function importRelation(address recommer, address user) external onlyMigrant{
        addRelation(recommer, user);
    }

    event PreAddRelation(address indexed recommer, address indexed user);

    function preRelation(address from, address to) private {
        //A->B
        if(_refBackMapping[to][from]){
            // is A ' ref b?
            //Search Back B->A
            addRelation(to, from);
        } else if (!_refBackMapping[from][to] && !_refBackMapping[to][from]) {
            _refBackMapping[from][to] = true;
            emit PreAddRelation(from, to);
        }
    }
    // -----Refer end-----//
    
    // -----Refer bonus-----//
    function recordMarketingPool() public {
        uint _day = getDay();
        if ( dayOfRecord != _day ){
            marketingPoolAmount = balanceOf(marketingAddress);
            dayOfRecord = _day;
            recordMarketingBonus = 0;
        }
    }

    function notifyRewardAmount(address to, uint256 tAmount) private {
        if ( marketingPoolAmount > 0 ) {
            address upper = getRecommer(to);
            if (upper != address(0)) {
                // upper
                uint256 bonus = tAmount.mul(lv2Rate).div(_commonDiv);
                uint256 limitAmount = marketingPoolAmount.mul(limitRate).div(_commonDiv);
                if(recordMarketingBonus.add(bonus) <= limitAmount && balanceOf(marketingAddress) >= bonus) {
                    super._transfer(marketingAddress, upper, bonus);
                    recordMarketingBonus += bonus;
                }
            }
        }
    }

    function _getBuyParam(uint256 tAmount, Param memory param) private view  {
        param.tLiquidityFee = tAmount.mul(_buyLiquidityFee).div(_commonDiv);
        param.tTransferAmount = tAmount.sub(param.tLiquidityFee);
        param.bonusRecord = true;//buy
    }
 
    function _getSellParam(uint256 tAmount, Param memory param) private view  {
        param.tMarketFee = tAmount.mul(_sellMarketFee).div(_commonDiv);
        param.tTransferAmount = tAmount.sub(param.tMarketFee);
        param.bonusRecord = false;
    }

    struct Param{
        bool takeFee;
        bool bonusRecord; // false no record, buy = true Record   
        uint256 tTransferAmount;
        uint256 tLiquidityFee;// add lp
        uint256 tMarketFee; // tech service fee
        uint256 tDestroyFee; // destroy fee
    }

    function _transfer (
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (from != to && !ammPairs[from] && !ammPairs[to] && 
            from != marketingAddress && to != marketingAddress) {
            if ((!getRefBackMapping(from, to) && balanceOf(from) >= holdRefAmount) || getRefBackMapping(to, from)) {
                preRelation(from, to);
            }
        }

        if( amount == 0 ) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 _tokenBal = balanceOf(address(this));
        if( _tokenBal >= swapTokensAtAmount 
            && !inSwapAndLiquidity 
            && msg.sender != pancakePair 
            && msg.sender != marketingAddress 
            && IERC20(pancakePair).totalSupply() > 10 * 10**18 ) {
            // swap
            _processSwap(_tokenBal);
        }

        bool takeFee = true;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        Param memory param;
        if( takeFee ) {
            param.takeFee = true;
            if (ammPairs[from]) {  // buy or removeLiquidity
                _getBuyParam(amount, param);
            } else if (ammPairs[to]) {
                _getSellParam(amount, param);   //sell or addLiquidity
            } else {
                // transfer
                param.tDestroyFee = amount.mul(3).div(100);
                param.tTransferAmount = amount.sub(param.tDestroyFee);
            }
        } else {
            param.takeFee = false;
            param.tTransferAmount = amount;
        }

        if( takeFee ){
            // marketing add lp check
            _marketingAutoAddLp();
            // transfer slip fee
            _feeTransfer(param, from);
        }
        // normal transfer
        super._transfer(from, to, param.tTransferAmount);
        // buy to dividend bonus
        if ( takeFee && param.bonusRecord ) {
            // buy bonus
            notifyRewardAmount(to, amount);
        }
    }

    function _marketingAutoAddLp() private {        
        // record day pool of marketing
        recordMarketingPool();
        if (enableMarketingAddLp) {
            try IMarketing(marketingAddress).autoAddLp() {} catch {}
        }
    }

    // slip fee transfer
    function _feeTransfer(Param memory param, address from) private {
        if (param.tDestroyFee > 0){
            super._transfer(from, address(0), param.tDestroyFee);
        }
        if (param.tMarketFee > 0){
            super._transfer(from, marketingAddress, param.tMarketFee);
        }
        if (param.tLiquidityFee > 0){
            super._transfer(from, address(this), param.tLiquidityFee);
        }
    }

    function _processSwap(uint256 tokenBal) private lockTheSwap {
        // swap coin to at once save gas fee
        swapTokensForUsdt(tokenBal, marketingAddress);
    }

    function swapTokensForUsdt(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdtAddress;
        _approve(address(this), address(pancakeRouter), tokenAmount);
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }
}