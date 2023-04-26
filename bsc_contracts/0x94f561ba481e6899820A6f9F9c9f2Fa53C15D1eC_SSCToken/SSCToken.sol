/**
 *Submitted for verification at BscScan.com on 2023-04-26
*/

/**
 *Submitted for verification at BscScan.com on 2022-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

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
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
    )external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IWrap {
	function withdraw() external;
    function transferOwnership(address newOwner) external;
}

contract SSCToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _tOwned;
    mapping (address => uint256) private _tLocked;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    uint8 private _decimals = 18;
    uint256 private _tTotal = 1000000 * 1e18;

    uint256 public burnLimit = 990000 * 1e18;    
    uint256 public burnAmount;

    string private _name = "SeashellCoin";
    string private _symbol = "SSC";
    
    uint256 public burnFee = 100;
    uint256 public lpFee = 100;
    uint256 public foundFee = 90;
    uint256 public operateFee = 60;
    uint256 public clubFee = 15;
    uint256 public coreClubFee = 35;
    uint256 public midLeaderFee = 100;
    uint256 public totalFee = 500;
    // 锁仓时间，单位为月
    uint256 public lockTime = 36;
    // 释放周期
    uint256 public releaseInterval = 300; // 30 days;
    // 用户释放时间
    mapping(address => uint256) public releaseTime;
    // 用户已释放的期数
    mapping(address => uint256) public releasePeriods;
    // 用户每期释放的数量
    mapping(address => uint256) public releaseAmount;

    address public operateAddress;
    address public foundAddress;
    address public clubAddress;
    address public coreClubAddress;
    address public midLeaderAddress;
    address public lockAddress;
    address public wrap;

    IUniswapV2Router02 public uniswapV2Router;
    bool private swapping;

    mapping(address => bool) public ammPairs;
    
    address public uniswapV2Pair;
    address public USDT;    
    address public holder;
    uint256 public addPriceTokenAmount;

    uint public maxTxAmount = 1e18;
    bool inSwapAndLiquify;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event Unfreeze(address indexed account, uint256 amount, uint256 periods);

    constructor (
        address _route,
        address _usdt,
        address _holder) {
        
        USDT = _usdt;
        holder = _holder;
        _tOwned[holder] = _tTotal;
        
        _isExcludedFromFee[_holder] = true;
        _isExcludedFromFee[address(this)] = true;
        
        uniswapV2Router = IUniswapV2Router02(_route);
         
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), USDT);

        address token1 = IUniswapV2Pair(address(uniswapV2Pair)).token1();
        require(token1 != USDT, "pls deploy again");
        
        ammPairs[uniswapV2Pair] = true;
        operateAddress = 0x698926fA7765a4495ec5a155e2d7B75Dc05CF5d1;
        foundAddress = 0x9fcF85DD2cF2CbDF7838Bc761276334cA3F3B288;
        clubAddress = 0x1564dE381478E1D273886BFE127918A64d79FB07;
        coreClubAddress = 0xB4f58D3AF9C733Afa20ff7002C6D155bCC00C257;
        midLeaderAddress = 0xFb6300C3a8D7eDE356d41638E62E1193bfc01607;
        lockAddress = 0xFc66286EA48e53a9FaD1c3F3388C2DfF098279b3;

        emit Transfer(address(0), _holder, _tTotal);
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
        IERC20(USDT).approve(address(uniswapV2Router), ~uint256(0));
    }

    function setWrap(address _wrap) external onlyOwner{
        wrap = _wrap;
    }

    function setAmmPair(address pair,bool hasPair) external onlyOwner{
        ammPairs[pair] = hasPair;
    }

    function setLpFee(uint value) external onlyOwner{
        lpFee = value;
        totalFee = burnFee.add(lpFee).add(foundFee).add(operateFee).add(clubFee).add(coreClubFee).add(midLeaderFee);
    }

    function setBurnFee(uint value) external onlyOwner{
        burnFee = value;
        totalFee = burnFee.add(lpFee).add(foundFee).add(operateFee).add(clubFee).add(coreClubFee).add(midLeaderFee);
    }

    function setFoundFee(uint value) external onlyOwner{
        foundFee = value;
        totalFee = burnFee.add(lpFee).add(foundFee).add(operateFee).add(clubFee).add(coreClubFee).add(midLeaderFee);
    }

    function setOperateFee(uint value) external onlyOwner{
        operateFee = value;
        totalFee = burnFee.add(lpFee).add(foundFee).add(operateFee).add(clubFee).add(coreClubFee).add(midLeaderFee);
    }

    function setClubFee(uint value) external onlyOwner{
        clubFee = value;
        totalFee = burnFee.add(lpFee).add(foundFee).add(operateFee).add(clubFee).add(coreClubFee).add(midLeaderFee);
    }

    function setCoreClubFee(uint value) external onlyOwner{
        coreClubFee = value;
        totalFee = burnFee.add(lpFee).add(foundFee).add(operateFee).add(clubFee).add(coreClubFee).add(midLeaderFee);
    }

    function setMidLeaderFee(uint value) external onlyOwner{
        midLeaderFee = value;
        totalFee = burnFee.add(lpFee).add(foundFee).add(operateFee).add(clubFee).add(coreClubFee).add(midLeaderFee);
    }

    function setOperateAddress(address addr) external onlyOwner{
        operateAddress = addr;
    }

    function setFoundAddress(address addr) external onlyOwner{
        foundAddress = addr;
    }

    function setClubAddress(address addr) external onlyOwner{
        clubAddress = addr;
    }

    function setCoreClubAddress(address addr) external onlyOwner{
        coreClubAddress = addr;
    }

    function setMidLeaderAddress(address addr) external onlyOwner{
        midLeaderAddress = addr;
    }

    function setTxAmount(uint apta) external onlyOwner{
        maxTxAmount = apta;
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
        return _tOwned[account].add(_tLocked[account]);
    }

    function ownedBalanceOf(address account) public view returns (uint256) {
        return _tOwned[account];
    }

    function lockBalanceOf(address account) public view returns (uint256) {
        return _tLocked[account];
    }

    function getCanLockInfo(address account) public view returns (uint, uint) {
        uint256 current = block.timestamp;
        if( _tLocked[account] > 0 && current >= releaseTime[account] ){
            // 计算需要释放的期数
            uint256 releasePeriod = current.sub(releaseTime[account]).div(releaseInterval) + 1;
            if( releasePeriod > releasePeriods[account] ){
                uint256 releasing = releaseAmount[account].mul(releasePeriod.sub(releasePeriods[account]));
                if( releasing > _tLocked[account] ){
                    releasing = _tLocked[account];
                }
                return (releasing, releasePeriod.sub(releasePeriods[account]));
            } else {
                return (0, 0);
            }
        } else{
            return (0, 0);
        }
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
    
    function excludeFromFee(address[] memory accounts) public onlyOwner {
        for( uint i = 0; i < accounts.length; i++ ){
            _isExcludedFromFee[accounts[i]] = true;
        }
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    receive() external payable {}

    function _take(uint256 tValue, address from, address to) private {
        _tOwned[to] = _tOwned[to].add(tValue);
        emit Transfer(from, to, tValue);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferWrapOwnership(address _newWrapOwner) public onlyOwner {
		IWrap(wrap).transferOwnership(_newWrapOwner);
	}

    struct Param{
        bool takeFee;
        uint tTransferAmount;
        uint tLp;
        uint tBurn;
        uint tFound;
        uint tOperate;
        uint tClub;
        uint tCoreClub;
        uint tMidLeader;
    }

    function _initParam(uint256 tAmount,Param memory param) private view  {
        uint tFee = 0;
        if( param.takeFee ) {
            param.tLp = tAmount * lpFee / 10000;
            param.tBurn = tAmount * burnFee / 10000;
            param.tFound = tAmount * foundFee / 10000;
            param.tOperate = tAmount * operateFee / 10000;
            param.tClub = tAmount * clubFee / 10000;
            param.tCoreClub = tAmount * coreClubFee / 10000;
            param.tMidLeader = tAmount * midLeaderFee / 10000;
            tFee = tAmount * totalFee / 10000;
        }
        param.tTransferAmount = tAmount.sub(tFee);
    }

    function _takeFee(Param memory param,address from) private {
        if( param.tLp > 0 ){
            _take(param.tLp, from, address(this));
        }
        if( param.tBurn > 0 ){
            _take(param.tBurn, from, address(0));
            burnAmount += param.tBurn;
        }
        if( param.tFound > 0 ){
            _take(param.tFound, from, foundAddress);
        }
        if( param.tOperate > 0 ){
            _take(param.tOperate, from, operateAddress);
        }
        if( param.tClub > 0 ){
            _take(param.tClub, from, clubAddress);
        }
        if( param.tCoreClub > 0 ){
            _take(param.tCoreClub, from, coreClubAddress);
        }
        if( param.tMidLeader > 0 ){
            _take(param.tMidLeader, from, midLeaderAddress);
        }
    }

    function _isLiquidity(address from,address to) internal view returns(bool isAdd,bool isDel){
        address token0 = IUniswapV2Pair(address(uniswapV2Pair)).token0();
        (uint r0,,) = IUniswapV2Pair(address(uniswapV2Pair)).getReserves();
        uint bal0 = IERC20(token0).balanceOf(address(uniswapV2Pair));
        if( ammPairs[to] ){
            if( token0 != address(this) && bal0 > r0 ){
                isAdd = bal0 - r0 > addPriceTokenAmount;
            }
        }
        if( ammPairs[from] ){
            if( token0 != address(this) && bal0 < r0 ){
                isDel = r0 - bal0 > 0; 
            }
        }
    }

    function batchTransfer(address[] memory accounts, uint256[] memory amounts) external returns(bool) {
        require(accounts.length == amounts.length, "parameter error");
        for (uint256 i = 0; i < accounts.length; i++) {
            _transfer(msg.sender, accounts[i], amounts[i]);
        }
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(from == lockAddress) {
            _doLockTransfer(from, to, amount);
            releaseTime[to] = block.timestamp;
            releaseAmount[to] = releaseAmount[to].add(amount.div(lockTime));
            return;
        }

        // 如果用户锁仓金额_tLocked大于0，并且锁仓时间已到，那么解锁
        uint256 current = block.timestamp;
        if( _tLocked[from] > 0 && current >= releaseTime[from] ){
            // 计算需要释放的期数
            uint256 releasePeriod = current.sub(releaseTime[from]).div(releaseInterval) + 1;
            if( releasePeriod > releasePeriods[from] ){
                uint256 releasing = releaseAmount[from].mul(releasePeriod.sub(releasePeriods[from]));
                if( releasing > _tLocked[from] ){
                    releasing = _tLocked[from];
                    releasePeriods[from] = lockTime;
                } else {
                    releasePeriods[from] = releasePeriod;
                }
                _tLocked[from] = _tLocked[from].sub(releasing);
                _tOwned[from] = _tOwned[from].add(releasing);
                emit Unfreeze(from, releasing, releasePeriod.sub(releasePeriods[from]));
            }
        }

        bool isAddLiquidity;
        bool isDelLiquidity;
        ( isAddLiquidity, isDelLiquidity) = _isLiquidity(from,to);
       
        Param memory param;
        bool takeFee = true;

        if(!ammPairs[to]) { // 转账 买或者撤池
            takeFee = false;
        }

        if(ammPairs[to]) { // 卖或者加池
            if(_isExcludedFromFee[from] || isAddLiquidity) {
                takeFee = false;
            }
        }

        if( burnAmount >= burnLimit && burnFee > 0){
            totalFee = totalFee.sub(burnFee);
            burnFee = 0;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= maxTxAmount;
        if( canSwap &&
            !swapping &&
            !ammPairs[from] &&
            from != owner() &&
            to != owner() &&
            from != address(this)
        ) {
            swapping = true;
            swapAndLiquify(contractTokenBalance);
            swapping = false;
        }

        param.takeFee = takeFee;
        _initParam(amount, param);
        _tokenTransfer(from,to,amount,param);
    }

    function swapAndLiquify(uint256 amount) public lockTheSwap {
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);

        uint256 initialBalance = IERC20(USDT).balanceOf(address(this));
        swapTokensForUsdt(half); 
        uint256 newBalance = IERC20(USDT).balanceOf(address(this)).sub(initialBalance);
        addLiquidity(newBalance, otherHalf);
    }

    function swapTokensForUsdt(uint256 tokenAmount) public {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            wrap,
            block.timestamp
        );     
        IWrap(wrap).withdraw(); 
    }

    function addLiquidity(uint256 usdtAmount, uint256 tokenAmount) private {
        uniswapV2Router.addLiquidity(
            USDT,
            address(this),
            usdtAmount,
            tokenAmount,
            0,
            0,
            foundAddress,
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount,Param memory param) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(param.tTransferAmount);
        emit Transfer(sender, recipient, param.tTransferAmount);
        if(param.takeFee){
            _takeFee(param,sender);
        }
    }

    function _doLockTransfer(address sender, address recipient, uint256 tAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tLocked[recipient] = _tLocked[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _doTransfer(address sender, address recipient, uint256 tAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function donateDust(address addr, uint256 amount) external onlyOwner {
        TransferHelper.safeTransfer(addr, _msgSender(), amount);
    }

    function donateEthDust(uint256 amount) external onlyOwner {
        TransferHelper.safeTransferETH(_msgSender(), amount);
    }
}