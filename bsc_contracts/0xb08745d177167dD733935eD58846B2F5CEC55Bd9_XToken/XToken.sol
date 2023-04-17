/**
 *Submitted for verification at BscScan.com on 2023-04-16
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
contract Ownable is Context {
    address internal _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
}
interface IUniswapV2Pair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function sync() external;
}
contract XToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
  
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 _decimals=18;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    mapping(address => bool) public ammPairs;
    address private uad;

    address private projectad;
    address private communityad;
    address private Privatead;
    address private poolad;
    address private mechanismad;
    address payable private    bnbad;
    address private marketingad;
    address private airdropad;

    mapping(address=>uint256) private smamount;
    uint256 private starttime;
    uint256 private endtime;
    uint256 private oncecount;
    uint256 private allcount;
    
    uint256[] private round;
    uint256 private allcoin;
    constructor(string memory name,string memory symbol,address owner) public {
        _totalSupply = 100000000*10**_decimals;
        _name = name;
        _symbol = symbol;

        projectad=0x93B881a077c214CB24e0f73bb149C58C29910962;
        communityad=0xDc934b26cbAb55f6Cce2eb76dff52256b6beC33F;
        Privatead=0xD82E20E41Ff606E39660bb685c4c910b5A18d64A;
        poolad=0xFC397050088EeBb63d24572eFcC03ee73c7A3b15;
        mechanismad=0xD35c7975Ab4126AA6c2964a27617Ac007904b7f2;
        bnbad=0x89C7c9CdB217c2f3bfB1ea1edF164323f153E7F1;
        marketingad=0xF81F71a3F4e2135df6e953461faE8AE228a9272A;
        airdropad=0xd41E41Eb3f9913ee99547021E80b2B923815839d;

        _owner = owner;
        starttime=block.timestamp;
        endtime=starttime.add(3600*24*10);

        if(round.length==0){
            round.push(0);
        }

        _balances[projectad] = _totalSupply.mul(10).div(100);
        emit Transfer(address(0), projectad, _totalSupply.mul(10).div(100));

        _balances[communityad] = _totalSupply.mul(10).div(100);
        emit Transfer(address(0), communityad, _totalSupply.mul(10).div(100));

        _balances[Privatead] = _totalSupply.mul(40).div(100);
        emit Transfer(address(0), Privatead, _totalSupply.mul(40).div(100));

        _balances[poolad] = _totalSupply.mul(19).div(100);
        emit Transfer(address(0), poolad, _totalSupply.mul(19).div(100));

        _balances[mechanismad] = _totalSupply.mul(21).div(100);
        emit Transfer(address(0), mechanismad, _totalSupply.mul(21).div(100));



        uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uad=0x55d398326f99059fF775485246999027B3197955;


        // uniswapV2Router = IUniswapV2Router02(0xCc7aDc94F3D80127849D2b41b6439b7CF1eB4Ae0);
        // uad=0x069bC435949F28a9AD6c1073cbD4ac77098e5166;

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), uad);

        ammPairs[uniswapV2Pair] = true;
      
    }
    
     function _isLiquidity(address from, address to) internal  view returns (bool isAdd, bool isDel, bool isSell, bool isBuy){
        address token0 = IUniswapV2Pair(address(uniswapV2Pair)).token0();
        (uint r0,,) = IUniswapV2Pair(address(uniswapV2Pair)).getReserves();
        uint bal0 = IERC20(token0).balanceOf(address(uniswapV2Pair));

        if (ammPairs[to]) {
            if (token0 != address(this) && bal0 > r0) {
                isAdd = bal0 - r0 > 0;
            }
            if (!isAdd) {
                isSell = true;
            }
        }
        if (ammPairs[from]) {
            if (token0 != address(this) && bal0 < r0) {
                isDel = r0 - bal0 > 0;
            }
            if (!isDel) {
                isBuy = true;
            }
        }
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
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    receive() external payable {}
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  
   
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
     
        (, , bool isSell, bool isBuy) = _isLiquidity(from, to);
        if(_isExcludedFromFee[from]==true ||_isExcludedFromFee[to]==true){
            _balances[from] = _balances[from].sub(amount);
            _balances[to] = _balances[to].add(amount);
            emit Transfer(from, to, amount);
        }else{
            if(isSell==true || isBuy ==true){
                _balances[from] = _balances[from].sub(amount);
                _balances[to] = _balances[to].add(amount.mul(95).div(100));
                emit Transfer(from, to, amount.mul(95).div(100));

                _balances[marketingad] = _balances[marketingad].add(amount.mul(2).div(100));
                emit Transfer(from, marketingad, amount.mul(2).div(100));

                _balances[airdropad] = _balances[airdropad].add(amount.mul(3).div(100));
                emit Transfer(from, airdropad, amount.mul(3).div(100));

            }else if(to==address(0)){
                burn(amount);
            }
            else{
                _balances[from] = _balances[from].sub(amount);
                _balances[to] = _balances[to].add(amount);
                emit Transfer(from, to, amount);     
            }
            
        }
        
    }
    function sm() public payable{
        require(msg.value>=1e17 && msg.value+smamount[msg.sender]<=40e18,"Min 0.1, Max 40");
        require(round.length<=7,"Up to 7 rounds");
        smamount[msg.sender]=smamount[msg.sender].add(msg.value); 
        oncecount=oncecount.add(msg.value);
        allcount=allcount.add(msg.value);
        if(oncecount>=400*1e18 && round.length<7){
            oncecount=0;
            round.push(0);
            endtime=block.timestamp.add(10*24*3600);
        }
        if(block.timestamp>=endtime  && round.length<7){
            oncecount=0;
            round.push(0);
            endtime=block.timestamp.add(10*24*3600);
        }
        if(round.length==7 &&(oncecount>=400*1e18 || block.timestamp>endtime)){
            require(1==2,"End of private placement");
        }
        bnbad.transfer(address(this).balance);
        uint256 tmp=round.length-1;
        allcoin=allcoin.add(msg.value.mul(25000).mul(85**tmp).div(100**tmp));
        require(allcoin<=40000000*1e18,"40000000 sold out");
        IERC20(address(this)).transfer(msg.sender,msg.value.mul(25000).mul(85**tmp).div(100**tmp));
    }
    function excludeFromFee(address[] memory accounts) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = true;
        }
    }
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
    function withdraw(address to,uint256 amount) public onlyOwner{
        IERC20(address(this)).transfer(to,amount);
    }

    function getendtime() public view returns(uint256){
        return endtime;
    }
    function setendtime(uint256 _endtime) public onlyOwner{
        endtime=_endtime;
    }

    function getrount() public view returns(uint256){
        
        return round.length;
    }
    function testround() public onlyOwner{
        endtime=endtime.add(10*24*3600);
        round.push(0);
    }
    function getrountsum() public view returns(uint256,uint256){
        uint256 tmp=round.length-1;
        return (25000*1e18*85**tmp/100**tmp,tmp);
    }

    
    function getnowoncecount() public view returns(uint256){
        return oncecount;
    }

    function getallcount() public  view returns(uint256){
        return allcount;
    }

    function getlask(address _fromad) public view returns(uint256){
        return (40*1e18-smamount[_fromad]);
    }

   
    function gettoken01() public view returns (address, address, bool){
        return (IUniswapV2Pair(address(uniswapV2Pair)).token0(), address(this), IUniswapV2Pair(address(uniswapV2Pair)).token0() < address(this));
    }
}