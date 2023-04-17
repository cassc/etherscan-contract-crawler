/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
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
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library EnumerableSet {
    struct AddressSet {
        address[] _values;
        mapping (address => uint256) _indexes;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            address lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
}

interface ISwapRouter {
    function factory() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin,address to,uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakePair {
    function balanceOf(address owner) external view returns (uint);
    function totalSupply() external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract GasToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    string private _name = "GAS";
    string private _symbol = "GAS";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1300000000 * 10**18;

    address public marker = 0x318d426Fee2C28b608caB277506c76823b7693d0; // PRO
    address private usdtAddr = 0x55d398326f99059fF775485246999027B3197955;// PRO
    address private routerAddr = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // PRO
    address public bonusAddr = 0xfb5B838b6cfEEdC2873aB27866079AC55363D37E; // PRO

    IERC20 public usdtToken = IERC20(usdtAddr);
    IERC20 public bonusToken = IERC20(bonusAddr);
    ISwapRouter public swapRouter;
    address public lpAddr;
    IPancakePair public lpToken;
    uint256 public swapMinVol = 1000 * 10**18;
    bool public swapByMin = true;
    bool public excLock = false;
    mapping(address => bool) public feeWhiteList;
    mapping(address => bool) public excWhiteList;
    mapping(address => bool) public excBlackList;
    mapping(address => bool) public bonusBlackList;
    uint256[] public buyFeeRate = [10,20,30,10,10];//destory、foundation、bonus、first generation、second generation
    uint256[] public sellFeeRate = [10,20,30,10,10];//destory、foundation、bonus、first generation、second generation
    uint256 public constant MAX = ~uint256(0);

    uint256 public lpKeeperNum = 10;
    EnumerableSet.AddressSet private lpKeeperSet;
    uint256 public bonusTokenVolPer = 100000 * 10**18;
    uint256 public bonusFeeMin = 1000 * 10**18;
    uint256 public bonusFeeVol = 0;

    mapping(address => address) public parentMap;
    
    constructor () {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        swapRouter = ISwapRouter(routerAddr);
        _allowances[address(this)][address(swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        lpAddr = swapFactory.createPair(address(this), usdtAddr);
        lpToken = IPancakePair(lpAddr);

        feeWhiteList[address(this)] = true;
        feeWhiteList[address(routerAddr)] = true;
        feeWhiteList[msg.sender] = true;
    }

    receive() external payable {}

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
 
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
  
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _transfer(from, to, amount);
        uint256 currentAllowance = _allowances[from][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(from,_msgSender(), currentAllowance.sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(!excBlackList[from] && !excBlackList[to],"in the blacklist");
        uint256 realVol = amount;
        uint256 feeRate = 0;
        if(lpAddr == from || lpAddr == to){
            require(excWhiteList[from] || excWhiteList[to] || !excLock, "cannot trade");
            if(lpAddr == from && !feeWhiteList[to]){ //buy
                feeRate = _transferFee(from,amount,to,buyFeeRate);
            }else if(lpAddr == to && !feeWhiteList[from]){//sell
                feeRate = _transferFee(from,amount,from,sellFeeRate);
            }
            realVol = amount.mul(1000 - feeRate).div(1000);
            if(lpAddr == from){ //buy
                recordLp(to);
            }else if(lpAddr == to){//sell
                recordLp(from);
            }
            bool swapDone = false;
            if(address(this) != from && lpAddr == to ){
                uint256 allAmount = balanceOf(address(this));
                if (allAmount > swapMinVol) {
                    uint256 curVol = swapByMin?swapMinVol:allAmount;
                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = usdtAddr;
                    swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(curVol,0,path,address(marker),block.timestamp);
                    swapDone = true;
                }
            }
            if(!swapDone && address(this) != from && bonusFeeVol >= bonusFeeMin){
                sendBonus();
            }
        }else if(!from.isContract() && !to.isContract() && parentMap[to] == address(0)){
            parentMap[to] = from;
        }
        _balances[from] = _balances[from].sub(amount);
        if(realVol > 0){
            _balances[to] = _balances[to].add(realVol);
            emit Transfer(from, to, realVol);
        }
    }

    function _transferFee(address from,uint256 amount,address cur,uint256[] memory feeRateList) internal returns(uint256){
        uint256 feeRate = 0;
        _baseTransfer(from,address(0),amount.mul(feeRateList[0]).div(1000));//destory
        _baseTransfer(from,address(this),amount.mul(feeRateList[1]+feeRateList[2]).div(1000));//foundation,bonus
        bonusFeeVol += amount.mul(feeRateList[2]).div(1000);
        feeRate = feeRateList[0] + feeRateList[1] + feeRateList[2];
        address p1 = parentMap[cur];
        if(feeRateList[3] > 0 && p1 != address(0)){
            _baseTransfer(from,p1,amount.mul(feeRateList[3]).div(1000)); //first generation
            feeRate += feeRateList[3];
        }
        address p2 =parentMap[p1];
        if(feeRateList[4] > 0 && p2 != address(0)){
            _baseTransfer(from,p2,amount.mul(feeRateList[4]).div(1000)); //second generation
            feeRate += feeRateList[4];
        }
        return feeRate;
    }

    function _baseTransfer(address from,address to,uint256 amount) internal{
        if(amount > 0){
            _balances[to] = _balances[to].add(amount);
            emit Transfer(from, to, amount);
        }
    }

    function sendBonus() internal {
        if(bonusTokenVolPer == 0 || bonusToken.balanceOf(address(this)) < bonusTokenVolPer){
            return;
        }
        uint256 lpTotal = 0;
        for(uint256 i=0;i<lpKeeperSet.length();i++){
            lpTotal += lpToken.balanceOf(lpKeeperSet.at(i));
        }
        if(lpTotal > 0){
            for(uint256 i=0;i<lpKeeperSet.length() && i<20;i++){
                address keeper = lpKeeperSet.at(i);
                uint256 lpVol = lpToken.balanceOf(keeper);
                if(lpVol > 0){
                    bonusToken.transfer(lpKeeperSet.at(i), bonusTokenVolPer * lpVol / lpTotal);
                }
            }
        }
        bonusFeeVol = bonusFeeVol - bonusFeeMin;
    }

    function recordLp(address curAddr) internal  {
        if(curAddr == address(0) || curAddr.isContract()){
            return;
        }
        if(bonusBlackList[curAddr]){
            return;
        }
        if(!lpKeeperSet.contains(curAddr)){
            uint256 curVol = lpToken.balanceOf(curAddr);
            if(curVol > 0){
                if(lpKeeperSet.length() < lpKeeperNum){
                    lpKeeperSet.add(curAddr);
                }else{
                    (address minAddr,uint256 minVol) = getMinKeeper();
                    if(curVol > minVol){
                        lpKeeperSet.remove(minAddr);
                        lpKeeperSet.add(curAddr);
                    }
                }
            }
        }
    }

    function getMinKeeper() public view returns(address,uint256){
        if(lpKeeperSet.length() == 0){
            return (address(0),0);
        }
        address minAddr = lpKeeperSet.at(0);
        uint256 minVol = lpToken.balanceOf(minAddr);
        if(minVol == 0){
            return (minAddr,0);
        }
        for(uint256 i=1;i<lpKeeperSet._values.length;i++){
            address ta = lpKeeperSet._values[i];
            uint256 tv = lpToken.balanceOf(ta);
            if(tv == 0){
                return (ta,0);
            }
            if(tv < minVol){
                minAddr = ta;
                minVol = tv;
            }
        }
        return (minAddr,minVol);
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _balances[address(0)] = _balances[address(0)].add(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setExcLock(bool _excLock) public onlyOwner {
        excLock = _excLock;
    }

    function setSwap(bool _swapByMin,uint256 _swapMinVol) public onlyOwner {
        swapMinVol = _swapMinVol;
        swapByMin = _swapByMin;
    }

    function setList(address[] memory addrList,bool isIn,uint256 num) public onlyOwner {
        require(addrList.length > 0  && addrList.length <= 50 && num >= 1 && num <=4);
        for (uint256 i; i < addrList.length; ++i) {
            if(num == 1){
                feeWhiteList[addrList[i]] = isIn;
            }else if(num == 2){
                excWhiteList[addrList[i]] = isIn;
            }else if(num == 3){
                excBlackList[addrList[i]] = isIn;
            }else if(num == 4){
                bonusBlackList[addrList[i]] = isIn;
                if(isIn){
                    lpKeeperSet.remove(addrList[i]);
                }
            }
        }
    }

    function setFeeRate(uint256[] memory _buyFeeRate,uint256[] memory _sellFeeRate) public onlyOwner{
        require(_buyFeeRate.length == 5 && (_buyFeeRate[0]+_buyFeeRate[1]+_buyFeeRate[2]+_buyFeeRate[3]+_buyFeeRate[4]) <= 1000);
        require(_sellFeeRate.length == 5 && (_sellFeeRate[0]+_sellFeeRate[1]+_sellFeeRate[2]+_sellFeeRate[3]+_sellFeeRate[4]) <= 1000);
        buyFeeRate = _buyFeeRate;
        sellFeeRate = _sellFeeRate;
    }

    function setBonusParam(uint256 _lpKeeperNum,uint256 _bonusTokenVolPer ,uint256 _bonusFeeMin) public onlyOwner{
        lpKeeperNum = _lpKeeperNum;
        bonusTokenVolPer = _bonusTokenVolPer;
        bonusFeeMin = _bonusFeeMin;
    }
}