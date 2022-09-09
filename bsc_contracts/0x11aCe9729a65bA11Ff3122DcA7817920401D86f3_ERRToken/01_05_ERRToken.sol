// SPDX-License-Identifier: MIT;
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract ERRToken is Context,IERC20,Ownable {
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

    // 白名单列表，交易不扣手续费
    mapping(address => bool) public _isExcludedFromFee;
    // 交易对地址存储（用户判断是否是在swap交易）
    mapping(address => bool) public automatedMarketMakerPairs;

    // 买入基金分红
    uint256 public _ruJijin = 1;
    // 买入创世分红
    uint256 public _ruChuangshi = 4;
    // 卖出销毁
    uint256 public _chuXiaohui = 1;
    // 卖出lp
    uint256 public _chuLp = 4;
    // 转账手续费
    uint256 public _zhuanzhangRate = 5;

    // 基金地址
    address private _jijinAddress = 0xF1C591d923D47b9FD9E4Db0521E87F6d051fd887;
    // 创世地址
    address private _chuangshiAddress = 0x66EA42512830c3E19B46d2b6CC049B2469Ba5648;
    // 销毁地址
    address private _xiaohuiAddress = 0x0000000000000000000000000000000000000000;
    // lp地址
    address private _lpAddress = 0x02ecdbf36c1Ca7C8454E3F751E49118067787B13;
    // 转账地址
    address private _zhuanzhangAddress = 0x7E392F77B3C712f17134c242270D040bBECFF5e5;
    // 路由合约
    IUniswapV2Router public uniswapV2Router;
    // 交易对地址
    address public uniswapV2Pair;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() {
        _name = "cological chain of Rural Revitalization";
        _symbol = "ERR";
        _decimals = 18;
        _totalSupply = 21000000 * 10 ** uint256(_decimals);

        // 
        uint256 lianyou_num = 21000000 * 10 ** uint256(_decimals);
        _balances[msg.sender] = lianyou_num;
        emit Transfer(address(0), msg.sender, lianyou_num);

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

    // 获取交易对地址
    function getPair() external view returns(address){
        return uniswapV2Pair;
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

    /**
     *
     *  设置基金地址
     */ 
    function setJijinAddress(address account) public onlyOwner {
        if(_jijinAddress != account){
            _jijinAddress = account;
        }
    }
    // 设置创世地址
    function setChuangshiAddress(address account) public onlyOwner {
        if(_chuangshiAddress != account){
            _chuangshiAddress = account;
        }
    }
    // 设置销毁地址
    function setXiaohuiAddress(address account) public onlyOwner {
        if(_xiaohuiAddress != account){
            _xiaohuiAddress = account;
        }
    }
    // 设置lp地址
    function setLpAddress(address account) public onlyOwner {
        if(_lpAddress != account){
            _lpAddress = account;
        }
    }
    // 设置转账地址
    function setZhuanzhangAddress(address account) public onlyOwner {
        if(_zhuanzhangAddress != account){
            _zhuanzhangAddress = account;
        }
    }
    
    
    // 设置买入基金比例
    function setRuJijinRate(uint256 fee) public onlyOwner{
        _ruJijin = fee;
    }
    // 设置买入创世比例
    function setRuChuangshiRate(uint256 fee) public onlyOwner{
        _ruChuangshi = fee;
    }
    // 设置卖出销毁比例
    function setChuXiaohuiRate(uint256 fee) public onlyOwner{
        _chuXiaohui = fee;
    }
    // 设置卖出销毁比例
    function setChuLpRate(uint256 fee) public onlyOwner{
        _chuLp = fee;
    }
    // 设置转账手续费比例
    function setZhuanzhangRate(uint256 fee) public onlyOwner{
        _zhuanzhangRate = fee;
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
        
        // 当接收地址是交易对地址时，说明是swap交易卖出，扣除对应比例手续费
        if(takeFee && automatedMarketMakerPairs[recipient]){
            // 到账数量
            uint256 rate = 100;
            rate = rate.sub(_chuXiaohui).sub(_chuLp);
            uint256 daozhang_num = rate.mul(amount).div(100);
            _balances[recipient] = _balances[recipient].add(daozhang_num);


            // 销毁
            uint256 xiaohuiFee = _chuXiaohui.mul(amount).div(100);
            _balances[_xiaohuiAddress] = _balances[_xiaohuiAddress].add(xiaohuiFee);

            // lp
            uint256 lpFee = _chuLp.mul(amount).div(100);
            _balances[_lpAddress] = _balances[_lpAddress].add(lpFee);

        }else if(takeFee && automatedMarketMakerPairs[sender]){
            // 当发起地址是交易对地址时，说明是swap交易买入，扣除对应比例手续费
            // 到账数量
            uint256 rate = 100;
            rate = rate.sub(_ruJijin).sub(_ruChuangshi);
            uint256 daozhang_num = rate.mul(amount).div(100);
            _balances[recipient] = _balances[recipient].add(daozhang_num);

            // 基金
            uint256 jijinFee = _ruJijin.mul(amount).div(100);
            _balances[_jijinAddress] = _balances[_jijinAddress].add(jijinFee);
            // 创世
            uint256 chuangshiFee = _ruChuangshi.mul(amount).div(100);
            _balances[_chuangshiAddress] = _balances[_chuangshiAddress].add(chuangshiFee);
        }else{
            if(takeFee){
                uint256 rate = 100;
                rate = rate.sub(_zhuanzhangRate);
                uint256 daozhang_num = rate.mul(amount).div(100);
                _balances[recipient] = _balances[recipient].add(daozhang_num);

                // 转账手续费
                uint256 zhuanzhangFee = _zhuanzhangRate.mul(amount).div(100);
                _balances[_zhuanzhangAddress] = _balances[_zhuanzhangAddress].add(zhuanzhangFee);

            }else{
                _balances[recipient] = _balances[recipient].add(amount);
            }
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