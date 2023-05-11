/**
 *Submitted for verification at BscScan.com on 2023-05-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
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

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed owner, address indexed to, uint value);
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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}

 contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
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

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
    )external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

library EnumerableSet {
   
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

    
            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }


    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

   
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }


    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

   
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

   
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

contract AAA is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _updated;
    mapping (address => uint256) public _shareTime;
   
    uint8 private _decimals = 18;
    uint256 private _tTotal;
    uint256 public supply = 10000000 * (10 ** 8) * (10 ** 18);

    string private _name = "AAA";
    string private _symbol = "AAA";

    uint256 public _lpFee = 1;

    uint256 public _marketFee = 1;
    address public marketAddress = 0x93f6983388a733Df9D24F78BC3171d41EF7782b5;

    uint256 public _buyBackFee = 1;
    address public buyBackAddress = 0x93f6983388a733Df9D24F78BC3171d41EF7782b5;

    address public initPoolAddress = 0x93f6983388a733Df9D24F78BC3171d41EF7782b5;

    uint256 public totalFee = 3;

    IUniswapV2Router02 public uniswapV2Router;

    mapping(address => bool) public ammPairs;

    IERC20 public uniswapV2Pair;
    address public wbnb;

    uint256 public lpCondition = 1 * 10 ** 14;
    uint256 public holdingLimit = 5000 * (10 ** 8) * (10 ** 18);

    mapping(address => bool) isBlackList;

    address constant rootAddress = address(0x000000000000000000000000000000000000dEaD);

    uint256 currentIndex;
    uint256 distributorGas = 500000;
    uint256 public minPeriod = 3600;
    uint256 lpInitAmount;

    address private fromAddress;
    address private toAddress;

    uint256 launchedAt = 1683806400;

    EnumerableSet.AddressSet lpProviders;

    bool public swapEnabled = true;
    uint256 public swapThreshold = supply / 100000; // 0.001%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    constructor (address _router) {
        _tOwned[initPoolAddress] = supply;
        _tTotal = supply;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[rootAddress] = true;
        _isExcludedFromFee[initPoolAddress] = true;
        _isExcludedFromFee[marketAddress] = true;
        _isExcludedFromFee[buyBackAddress] = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Router = _uniswapV2Router;

        address bnbPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        wbnb = _uniswapV2Router.WETH();

        uniswapV2Pair = IERC20(bnbPair);
        ammPairs[bnbPair] = true;

        emit Transfer(address(0), initPoolAddress, _tTotal);
    }

    function setAddress(address _marketAddress, address _buyBackAddress)external onlyOwner{
        marketAddress = _marketAddress;
        buyBackAddress = _buyBackAddress;
    }

    function addToBlackList(address user) external onlyOwner {
        isBlackList[user] = true;
    }

    function removeFromBlackList(address user) external onlyOwner {
        isBlackList[user] = false;
    }

    function setAmmPair(address pair,bool hasPair)external onlyOwner{
        ammPairs[pair] = hasPair;
    }

    function setCondition(uint lc)external onlyOwner{
        lpCondition = lc;
    }

    function setMinPeriod(uint period)external onlyOwner{
        minPeriod = period;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)external onlyOwner{
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
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
    
    function setExcludeFromFee(address account, bool _isExclude) public onlyOwner {
        _isExcludedFromFee[account] = _isExclude;
    }
    
    receive() external payable {}

    function _take(uint256 tValue,address from,address to) private {
        _tOwned[to] = _tOwned[to].add(tValue);
        emit Transfer(from, to, tValue);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setFees(uint256 marketFee, uint256 lpFee,uint256 buyBackFee) external onlyOwner {
        _marketFee = marketFee;
        _lpFee = lpFee;
        _buyBackFee = buyBackFee;
        totalFee = _marketFee.add(_lpFee).add(_buyBackFee);
    }

    struct Param{
        bool takeFee;
        uint tTransferAmount;
        uint tContract;
        address user;
    }

     function _initParam(uint256 tAmount,Param memory param) private view  {
        uint tFee;
        
        if (block.timestamp - launchedAt > 10) {
            tFee = tAmount * totalFee / 100;
            param.tContract = tAmount * (_marketFee.add(_buyBackFee).add(_lpFee)) / 100;
        } else {
            tFee = tAmount * 80 / 100;
            param.tContract = tFee;
        }

        param.tTransferAmount = tAmount.sub(tFee);
    }

    function _takeFee(Param memory param,address from)private {
        if( param.tContract > 0 ){
            _take(param.tContract, from, address(this));
        }
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function shouldSwapBack(address to) internal view returns (bool) {
        return ammPairs[to]
        && !inSwap
        && swapEnabled
        && balanceOf(address(this)) >= swapThreshold;
    }

    function swapBack() internal swapping {
        _allowances[address(this)][address(uniswapV2Router)] = swapThreshold;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = wbnb;
        uint256 balanceBefore = address(this).balance;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 amountToMarket = amountBNB.mul(_marketFee).div(totalFee);
        uint256 amountToBuyBack = amountBNB.mul(_buyBackFee).div(totalFee);

        payable(marketAddress).transfer(amountToMarket);
        payable(buyBackAddress).transfer(amountToBuyBack);  
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");

        if (!_isExcludedFromFee[from] && ammPairs[to] && !inSwap) {
            uint256 fromBalance = balanceOf(from).mul(99).div(100);
            if (fromBalance < amount) {
                amount = fromBalance;
            }
        }

        bool takeFee;
        Param memory param;
        param.tTransferAmount = amount;

        if( ammPairs[from] ){
            param.user = to;
        } else {
            param.user = address(this);
        }

        if( ammPairs[to] && IERC20(to).totalSupply() == 0  ){
            require(from == initPoolAddress,"Not allow init");
        }

        if(inSwap || _isExcludedFromFee[from] || _isExcludedFromFee[to]){
            return _tokenTransfer(from,to,amount,param); 
        }

        if( isBlackList[from] || block.timestamp < launchedAt ){
            require(false,"Not allow");
        }

        if (
            launchedAt > 0 &&
            ammPairs[from] &&
            !_isExcludedFromFee[to]
        ) {
            require(isContract(to) == false, "Buy Limit");
            if (block.timestamp - launchedAt < 6) {
                isBlackList[from] = true;
            }
        }

        if (block.timestamp - launchedAt < 120) {
            require(_isExcludedFromFee[from] || _isExcludedFromFee[to] || ammPairs[to] || balanceOf(to).add(amount) <= holdingLimit, "Holding Limit Exceeded");
        }

        if(ammPairs[to] || ammPairs[from]){
            takeFee = true;
        }

        if(shouldSwapBack(to)){ swapBack(); }

        param.takeFee = takeFee;
        if( takeFee ){
            _initParam(amount,param);
        }
        
        _tokenTransfer(from,to,amount,param);

        if( address(uniswapV2Pair) != address(0) ){
            if (fromAddress == address(0)) fromAddress = from;
            if (toAddress == address(0)) toAddress = to;
            if ( !ammPairs[fromAddress] ) setShare(fromAddress);
            if ( !ammPairs[toAddress] ) setShare(toAddress);
            fromAddress = from;
            toAddress = to;

            if (
                from != address(this) 
                && address(this).balance > 0
                && uniswapV2Pair.totalSupply() > 100 ) {

                process(distributorGas);
            }
        }
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount,Param memory param) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(param.tTransferAmount);
        emit Transfer(sender, recipient, param.tTransferAmount);
        if(param.takeFee){
            _takeFee(param,sender);
        }
    }
    
     function process(uint256 gas) private {
        uint256 shareholderCount = lpProviders.length();

        if (shareholderCount == 0) return;

        uint256 nowbanance = address(this).balance;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        if (lpInitAmount == 0){
            lpInitAmount = uniswapV2Pair.balanceOf(initPoolAddress);
        }
        uint ts = uniswapV2Pair.totalSupply().sub(lpInitAmount);
        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (_shareTime[lpProviders.at(currentIndex)] == 0) {
                _shareTime[lpProviders.at(currentIndex)] = block.timestamp;
            }

            uint256 amount = nowbanance.mul(uniswapV2Pair.balanceOf(lpProviders.at(currentIndex))).div(ts);

            if (address(this).balance < amount) return;

            if (amount >= lpCondition && _shareTime[lpProviders.at(currentIndex)].add(minPeriod) <= block.timestamp) {
                payable(lpProviders.at(currentIndex)).transfer(amount);
                _shareTime[lpProviders.at(currentIndex)] = block.timestamp;
            }
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function setShare(address shareholder) private {
        if (_updated[shareholder]) {
            if (uniswapV2Pair.balanceOf(shareholder) == 0) quitShare(shareholder);
            return;
        }
        if (uniswapV2Pair.balanceOf(shareholder) == 0) return;
        if (shareholder == initPoolAddress || isContract(shareholder)) return;
        lpProviders.add(shareholder);
        _updated[shareholder] = true;
    }

    function quitShare(address shareholder) private {
        lpProviders.remove(shareholder);
        _updated[shareholder] = false;
    }

}