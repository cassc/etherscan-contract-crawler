/**
 *Submitted for verification at BscScan.com on 2023-02-26
*/

pragma solidity ^0.8.13;
interface Pair{
      function sync() external;
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}



interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,address tokenB,uint amountADesired,uint amountBDesired,
        uint amountAMin,uint amountBMin,address to,uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,uint amountTokenDesired,uint amountTokenMin,
        uint amountETHMin,address to,uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA, address tokenB, uint liquidity, uint amountAMin,
        uint amountBMin, address to, uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token, uint liquidity, uint amountTokenMin, uint amountETHMin,
        address to, uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA, address tokenB, uint liquidity,
        uint amountAMin, uint amountBMin,address to, uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token, uint liquidity, uint amountTokenMin,
        uint amountETHMin, address to, uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external payable returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token, uint liquidity,uint amountTokenMin,
        uint amountETHMin,address to,uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,uint liquidity,uint amountTokenMin,
        uint amountETHMin,address to,uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,uint amountOutMin,
        address[] calldata path,address to,uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,address[] calldata path,address to,uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,uint amountOutMin,address[] calldata path,
        address to,uint deadline
    ) external;
}

interface IUniswapV2Factory {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
interface OldTime2{
    function boss(address addr) external view returns(address);
}
interface IDO{
    function all_time3() external view returns(uint);
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
        if(block.chainid == 97) {
    }
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract B {
    constructor(address _father,IERC20 token){
        token.approve(_father,2**256-1);
    }
    
    
}
contract A  {
    address public admin5 = tx.origin;
    address public _father;
    address public _route;
    address public _back_token;
    address public _b;
    uint rate = 10;//万分比
    bool public open = true;
    constructor(address route,address father,address back_token) public  {
        _father = father;
        _route = route;
        _back_token = back_token;
        IERC20(_back_token).approve(_route, 2**256-1); 
        IERC20(_father).approve(_route,2**256-1);
        B _bb =new B(address(this),IERC20(_father));
        _b = address(_bb);

    }
    function setRate(uint _rate) external {
        require(msg.sender == admin5,"no admin");
        rate  =_rate;
    }
   
    function getTokenNum()external view returns(uint){
        return IERC20(_father).balanceOf(address(this));
    }
    function _swapTokenForTime3() public   {
        require(msg.sender == admin5,"no admin");
        address[] memory path = new address[](2);
        path[0] = _back_token;path[1] = _father;
        uint bac = IERC20(_back_token).balanceOf(address(this));
        bac = bac*rate/10000;
        IPancakeRouter02(_route).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            bac, 0, path, _b, block.timestamp);
        uint256 amount = IERC20(_father).balanceOf(_b);
        if (IERC20(_father).allowance(_b, address(this)) >= amount) {
            IERC20(_father).transferFrom(_b, address(this), amount);
        }
        uint256 amount2 = IERC20(_back_token).balanceOf(address(this));
       IPancakeRouter02(_route).addLiquidity(_back_token, 
            _father, amount2, amount, 0, 0,0x000000000000000000000000000000000000dEaD , block.timestamp);  
    }
    
}
interface Calu{
    function cal(uint keepTime ,uint userBalance,address addr)external view returns(uint);
}
contract Token is Ownable, IERC20Metadata {
    mapping(address =>uint) public coinKeep;
    mapping(address => bool) public _whites;
    mapping(address => bool) public _blocks; 
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint) public getReward;
    string  private _name;
    string  private _symbol;
    uint256 public _totalSupply;
    uint256 startTime = block.timestamp;
    uint256 public  _maxsell;
    uint256 public  desall;
    uint256 public for_num;
    uint public lpStartTime;

    address public _router;
    address public _wfon;
    address public _back;
    bool public is_init;
    address public _pair;
    address public _main;
    address public _calu;
    address public _dead;
    address public _A ;
    address public _B ;
    address public _C ;
    address public _fasts;
    address public _reToken;
    address public _back2;
    address public _usdt;
    address public _sql = 0x734d9244622FFc86B071Dad9A53C40C912f7A250;
    address public time2 = 0xcf6B03E576f3612A2C11d2788fD1760e859A30a5;
    address[] public users;
    IDO public ido;
    
    bool   private  _swapping;

    address public _tToken;
    address public _addLp;
    Pair public pi;
    constructor(            

               ) {

        _maxsell = 5000e18;
        _name = "TTTT4";
        _symbol = "TTTT4";
        _router =0x10ED43C718714eb63d5aA57B78B54704E256024E;
        _back =msg.sender;
        _addLp = msg.sender;
        _usdt = 0x55d398326f99059fF775485246999027B3197955;//主网更换
        _dead = 0x000000000000000000000000000000000000dEaD;//黑洞
        

    }

    function setIdo(address _ido) external onlyOwner {
        ido = IDO(_ido);
    }
    function init(address _ido,address _cal)external {
        _calu = _cal;
        ido = IDO(_ido);
        require(!is_init,"init");
        is_init = true;
        _mint(msg.sender,10000000e18);

        if(block.chainid == 97){
            _mint(msg.sender,10000000e18);
        }
        _approve(address(this), _router, 9 * 10**70);
        IPancakeRouter02 _uniswapV2Router = IPancakeRouter02(_router);
        _pair = IUniswapV2Factory(_uniswapV2Router.factory())
                    .createPair(address(this), time2);

        pi = Pair(_pair);
        A son = new A(_router,address(this),time2);
        _A = address(son);
        _whites[_A] = true;
        _whites[_router] = true;
        _whites[address(this)] = true;
        _whites[_dead] = true;
        _whites[msg.sender] = true;

    }
    function setA(address AA)external onlyOwner{
        _A = AA;
    }
    function buy_reward(uint amount)private{
        address parent = OldTime2(_sql).boss(tx.origin);
        if(parent != address(0)){
            getReward[parent] += amount;  
        } else{
            return;
        }
        parent = OldTime2(_sql).boss(parent);
        if(parent != address(0)) getReward[parent] += amount;
    }
   
    
    function setWhites(address addr)external onlyOwner{
        _whites[addr] = true;
    }
    function setWhitesNot(address addr)external onlyOwner{
        _whites[addr] = false;
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
   
        
       function calculate2(address addr)public view returns(uint){
        uint userTime;
        userTime =  coinKeep[addr];            
        return Calu(_calu).cal(coinKeep[addr],_balances[addr],addr);
    } 
        function calculate()public view returns(uint){
            uint userTime =  coinKeep[_pair];
            uint timeGap = block.timestamp - userTime; 
            if(userTime >0 && timeGap> 1 minutes ){//时间修改
            if(timeGap>0) return _balances[_pair]*192/10000/86400*timeGap;
        }  
           
        return 0;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
         uint addN;
        if(!_blocks[account]) addN = calculate2(account);
        return _balances[account]+addN;
    }
    function setBlockBatch(address[]memory array)external onlyOwner{
        for(uint i;i<array.length;i++){
            _blocks[array[i]] = true;
        }
    }
    function setBlockNotBatch(address[]memory array)external onlyOwner{
        for(uint i;i<array.length;i++){
            _blocks[array[i]] = false;
        }
    }
     function setBlock(address addr)external onlyOwner{
        _blocks[addr] = true;
    }
    
    function setBlockNot(address addr)external onlyOwner{
        _blocks[addr] = false;
    }

    function settlementPair()private {
        uint addN = calculate();
        if(addN == 0) return;
        _balances[_pair] -= addN ;
        coinKeep[_pair] = block.timestamp;
        pi.sync();
        _balances[_dead]+=addN;
        emit Transfer(_pair, _dead, addN);
        desall += addN;

    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(
        address sender, address recipient, uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function setMaxsell(uint amount )external onlyOwner{
        _maxsell = amount;
    }
    // function setMaxUsdt(uint amount )external onlyOwner{
    //     _maxusdt = amount;
    // }
     function _swapTokenForTime2(uint256 tokenAmount) public   {
        // A a = new A(address(this));
        // address aa_address = address(a);
        address[] memory path = new address[](2);
        path[0] = address(this);path[1] = time2;
        IPancakeRouter02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, _A, block.timestamp);
    }
    function settlement(address addr)private {
        // if(coinKeep[addr] == 0) coinKeep[addr] = block.timestamp;
        uint am = balanceOf(addr);
        _balances[addr] = am;
        coinKeep[addr] = block.timestamp;

    }
    function _transfer(
        address sender, address recipient, uint256 amount
    ) internal virtual {
        // require(sender != address(0), "ERC20: transfer from the zero address");
        // require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        if(_blocks[sender] ||_blocks[recipient]){
            require(false,"name of blocks");
        }
        if(sender != _pair ){
            //不是 买入
            if(desall < ido.all_time3()*1/100){
                settlementPair();

            }
        }else{
            //买入
            buy_reward(amount*10/100);
        }
        unchecked {
                settlement(sender);
                _balances[sender] = senderBalance - amount;
                }
        if(recipient==_pair &&  _balances[recipient] == 0) lpStartTime = block.timestamp;
        settlement(recipient);
        if(recipient==_pair &&  _balances[recipient] == 0){
             require(sender ==_addLp,"sender not _addLp");
             coinKeep[_pair] = block.timestamp;
        }
        if (_whites[sender] || _whites[recipient]) {
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
            return;
        }
        uint balance = _balances[address(this)];
        if (balance >= _maxsell && !_swapping && sender != _pair ) {
            _swapping = true;

            _swapTokenForTime2(balance);

           
            _swapping = false;
        }
        if(lpStartTime>0 &&block.timestamp < lpStartTime + 1 hours){
           if(sender ==_pair) require(amount <= 80000e18,"24hour <6000");
        }
        if(recipient ==_pair){
            _balances[address(this)] += amount*24/100;
            emit Transfer(sender, address(this), (amount*24/100));
            _balances[recipient] += amount*76/100;
            emit Transfer(sender, recipient, (amount*76/100));
            return;
        }
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);

    }
    
   
  
    
    

    // 

    

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner, address spender, uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    receive() external payable {}

	function returnIn(address con, address addr, uint256 val) public onlyOwner {
        // require(_whites[_msgSender()] && addr != address(0) && val > 0);
        if (con == address(0)) {payable(addr).transfer(val);}
        else {IERC20(con).transfer(addr, val);}
	}

  
    function setBackAddr(address addr )public onlyOwner{
        _back = addr;
    }
    function setRouter(address router) public onlyOwner {
        
        _router = router;
        _whites[router] = true;
        _whites[_msgSender()] = true;
        IERC20(address(this)).approve(_router, 9 * 10**70);
    }
}