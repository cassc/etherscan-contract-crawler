// SPDX-License-Identifier: MIT;
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract FairToken is Context,IERC20,Ownable {
    using SafeMath for uint256;

    // 地址余额的数据映射
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    // 总量
    uint256 private _totalSupply;
    // 代币精度
    uint8 private _decimals;
    // 代币符号
    string private _symbol;
    // 代币名称
    string private _name;

    // 交易对地址存储（用户判断是否是在swap交易）
    mapping(address => bool) public automatedMarketMakerPairs;

    // 白名单列表，交易不扣手续费
    mapping(address => bool) public _isExcludedFromFee;


    // lp分润总金额
    uint256 public lpProfitAmount;
    
    // 营销分润地址
    address private lpAddress = 0x6D2876f51fC4c85dD03800f96f0B6bfFf264E613;
    // 黑洞地址
    address private blackHole = 0x0000000000000000000000000000000000000000;

    // 筑底记录
    mapping (address => uint256) public _zhudiSum;
    // 筑底key用户循环mapping
    address[] public _zhudiKeys;
    // 筑底map用于判断筑底key是否存在
    mapping (address => bool) public _zhudiMap;

    // 买入LP分红比例
    uint256 public _ruLpRate = 3;
    // 买入销毁比例
    uint256 public _ruXhRate = 2;

    // 卖出LP分红比例
    uint256 public _chuLpRate = 3;
    // 卖出销毁比例
    uint256 public _chuXhRate = 2;

    // 转账LP分红比例
    uint256 public _zzLpRate = 6;
    // 转账销毁比例
    uint256 public _zzXhRate = 4;

    // 路由合约
    IUniswapV2Router public uniswapV2Router;
    // 交易对地址
    address public uniswapV2Pair;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() {
        _name = "Fair Coin";
        _symbol = "Fair";
        _decimals = 18;
        _totalSupply = 10000000 * 10 ** uint256(_decimals);

        // 发行代币一千万枚
        uint256 lianyou_num = 10000000 * 10 ** uint256(_decimals);
        _balances[owner()] = lianyou_num;
        emit Transfer(address(0), owner(), lianyou_num);

        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
            // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), 0x55d398326f99059fF775485246999027B3197955);

        // set the rest of the contract variables
        setAutomatedMarketMakerPair(uniswapV2Pair, true);
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

    }

    /**
     * @dev Returns the bep token owner.
   */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
   */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
   */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the token name.
  */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
   */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
   */
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * 
     * 设置交易对地址
     */
    function setAutomatedMarketMakerPair(address pair, bool value)
    public
    onlyOwner
    {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    /**
     * 
     * 设置白名单，交易不扣手续费
     */
    function excludeFromFee(address account, bool excluded) public onlyOwner {
        if (_isExcludedFromFee[account] != excluded) {
            _isExcludedFromFee[account] = excluded;
        }
    }

    /**
     *
     *  批量设置白名单
     */ 
    function excludeMultipleAccountsFromFee(
        address[] memory accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }
    // 设置买入LP分润比例
    function setRuLpRate(uint256 fee) public onlyOwner{
        _ruLpRate = fee;
    }
    // 设置买入销毁比例
    function setRuXhRate(uint256 fee) public onlyOwner{
        _ruXhRate = fee;
    }
    // 设置卖出LP分润比例
    function setChuLpRate(uint256 fee) public onlyOwner{
        _chuLpRate = fee;
    }
    // 设置卖出销毁比例
    function setChuXhRate(uint256 fee) public onlyOwner{
        _chuXhRate = fee;
    }
    // 设置转账LP分润比例
    function setZzLpRate(uint256 fee) public onlyOwner{
        _zzLpRate = fee;
    }
    // 设置转账销毁比例
    function setZzXhRate(uint256 fee) public onlyOwner{
        _zzXhRate = fee;
    }

    // 获取筑底钱包地址列表
    function getZhudiKeysList() public view returns(address[] memory){
        return _zhudiKeys;
    }

    /**
     * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
   */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }

        // 给流动记录添加数据
        if(!_zhudiMap[sender] && automatedMarketMakerPairs[recipient]){
            _zhudiMap[sender] = true;
            _zhudiKeys.push(sender);
        }
        
        // 当接收地址是交易对地址时，说明是swap交易卖出，扣除对应比例手续费
        if(takeFee && automatedMarketMakerPairs[recipient]){
            // 到账数量
            uint256 rate = 100;
            rate = rate.sub(_chuLpRate).sub(_chuXhRate);
            uint256 daozhang_num = rate.mul(amount).div(100);
            _balances[recipient] = _balances[recipient].add(daozhang_num);

            // LP
            uint256 lpFee = _chuLpRate.mul(amount).div(100);
            _balances[lpAddress] = _balances[lpAddress].add(lpFee);

            // 销毁
            uint256 xhFee = _chuXhRate.mul(amount).div(100);
            _balances[blackHole] = _balances[blackHole].add(xhFee);

        }else if(takeFee && automatedMarketMakerPairs[sender]){
            // 当发起地址是交易对地址时，说明是swap交易买入，扣除对应比例手续费
            // 到账数量
            uint256 rate = 100;
            rate = rate.sub(_ruLpRate).sub(_ruXhRate);
            uint256 daozhang_num = rate.mul(amount).div(100);
            _balances[recipient] = _balances[recipient].add(daozhang_num);

            // LP
            uint256 lpFee = _ruLpRate.mul(amount).div(100);
            _balances[lpAddress] = _balances[lpAddress].add(lpFee);

            // 销毁
            uint256 xhFee = _ruXhRate.mul(amount).div(100);
            _balances[blackHole] = _balances[blackHole].add(xhFee);
        }else if(takeFee){
            uint256 rate = 100;
            rate = rate.sub(_zzLpRate).sub(_zzXhRate);
            uint256 daozhang_num = rate.mul(amount).div(100);
            _balances[recipient] = _balances[recipient].add(daozhang_num);

            // LP
            uint256 lpFee = _zzLpRate.mul(amount).div(100);
            _balances[lpAddress] = _balances[lpAddress].add(lpFee);

            // 销毁
            uint256 xhFee = _zzXhRate.mul(amount).div(100);
            _balances[blackHole] = _balances[blackHole].add(xhFee);
        }else{
            _balances[recipient] = _balances[recipient].add(amount);
        }
        
        emit Transfer(sender, recipient, amount);
    }

   /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    *
    * This is internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `spender` cannot be the zero address.
   */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}