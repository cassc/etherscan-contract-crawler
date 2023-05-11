/**
 *Submitted for verification at BscScan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library ChainId {
	function get() internal view returns (uint256 chainId) {
		assembly {
			chainId := chainid()
		}
	}
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
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

// File: contracts/libs/IERC20Metadata.sol
interface IERC20Metadata is IERC20 {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/GSN/Context.sol
abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this;
		return msg.data;
	}
}


// File: @openzeppelin/contracts/ownership/Ownable.sol
abstract contract Ownable is Context {
	address private _owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor () {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}
	function owner() public view virtual returns (address) {
		return _owner;
	}
	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/libs/Address.sol
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
		return functionCallWithValue(target, data, 0, errorMessage);
	}
	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}
	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");
		(bool success, bytes memory returndata) = target.call{ value: value }(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}
	function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed");
	}
	function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");
		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}
	function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed");
	}

	function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}
	function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// File: contracts/libs/SafeERC20.sol
library SafeERC20 {
	using Address for address;

	function safeTransfer(
		IERC20 token,
		address to,
		uint256 value
	) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
	}

	function safeTransferFrom(
		IERC20 token,
		address from,
		address to,
		uint256 value
	) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
	}

	function safeApprove(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		require(
			(value == 0) || (token.allowance(address(this), spender) == 0),
			"SafeERC20: approve from non-zero to non-zero allowance"
		);
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
	}

	function safeIncreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		uint256 newAllowance = token.allowance(address(this), spender) + value;
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
	}

	function safeDecreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		unchecked {
			uint256 oldAllowance = token.allowance(address(this), spender);
			require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
			uint256 newAllowance = oldAllowance - value;
			_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
		}
	}
	function _callOptionalReturn(IERC20 token, bytes memory data) private {
		bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
		if (returndata.length > 0) {
			require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
		}
	}
}

// File: contracts/libs/TakeableV2.sol
abstract contract TakeableV2 is Ownable {
	using Address for address;
	using SafeERC20 for IERC20;

	event CfoTakedToken(address caller, address token, address to,uint256 amount);
	event CfoTakedETH(address caller,address to,uint256 amount);

	address public cfo;

	modifier onlyCfoOrOwner {
		require(msg.sender == owner(), "onlyCfo: forbidden");
		_;
	}

	constructor(){
		cfo = msg.sender;
	}

	function takeToken(address token,address to,uint256 amount) public onlyCfoOrOwner {
		require(token != address(0),"invalid token");
		require(amount > 0,"amount can not be 0");
		require(to != address(0),"invalid to address");
		IERC20(token).safeTransfer(to, amount);
		emit CfoTakedToken(msg.sender,token,to, amount);
	}

	function takeETH(address to,uint256 amount) public onlyCfoOrOwner {
		require(amount > 0,"amount can not be 0");
		require(address(this).balance>=amount,"insufficient balance");
		require(to != address(0),"invalid to address");		
		payable(to).transfer(amount);
		emit CfoTakedETH(msg.sender,to,amount);
	}

	function takeAllToken(address token, address to) public {
		uint balance = IERC20(token).balanceOf(address(this));
		if(balance > 0){
			takeToken(token, to, balance);
		}
	}

	function takeAllTokenToSelf(address token) external {
		takeAllToken(token,msg.sender);
	}

	function takeAllETH(address to) public {
		uint balance = address(this).balance;
		if(balance > 0){
			takeETH(to, balance);
		}
	}

	function takeAllETHToSelf() external {
		takeAllETH(msg.sender);
	}

	function setCfo(address _cfo) external onlyOwner {
		require(_cfo != address(0), "_cfo can not be address 0");
		cfo = _cfo;
	}
}

// File: @openzeppelin/contracts/math/SafeMath.sol
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
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// File: contracts/ipp-token.sol
contract WDZDTEST is TakeableV2, IERC20Metadata {
	using Address for address;
	using SafeMath for uint256;

	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;

	string private constant _name = "WDZDTEST";
	string private constant _symbol = "WDZDTEST";
	uint256 private constant _totalSupply = 14672831*10**18;

	mapping (address => bool) public SwapPair;

	uint private constant RATE_PERCISION = 10000;
	uint public buyFeeRate = 200;
	uint public sellFeeRate = 200;
	uint public sendFeeRate = 0;
	address public feeTo = address(0x26D6F38576a0A6c28A98AE38a425EE84ae36C18b);
	address public deadAdd = address(0x000000000000000000000000000000000000dEaD);

	constructor(
		address _initHolder
	){
		address holder = _initHolder == address(0) ? msg.sender : _initHolder;
		_balances[holder] = _totalSupply;
		emit Transfer(address(0), holder, _totalSupply);
	}

	function name() public pure override returns (string memory) {
		return _name;
	}

	function symbol() public pure override returns (string memory) {
		return _symbol;
	}

	function decimals() public pure override returns (uint8) {
		return 18;
	}

	function totalSupply() public pure override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view override returns (uint256) {
		return _balances[account];
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

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public override returns (bool) {
		_transfer(sender, recipient, amount);
		uint256 currentAllowance = _allowances[sender][_msgSender()];
		require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
		unchecked {
			_approve(sender, _msgSender(), currentAllowance - amount);
		}
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		uint256 currentAllowance = _allowances[_msgSender()][spender];
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
		unchecked {
			_approve(_msgSender(), spender, currentAllowance - subtractedValue);
		}
		return true;
	}

	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal {
		require(sender != address(0), "ERC20: transfer from the zero address");
		_beforeTokenTransfer(sender, recipient, amount);
		require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
		uint recipientAmount = amount;
		uint feeRate = _takeFee(sender, recipient);
		if (feeRate>0 && feeRate<=RATE_PERCISION){
			uint feeAmount = amount.mul(feeRate) / RATE_PERCISION;
			recipientAmount -= feeAmount;
			_balances[feeTo] = _balances[feeTo].add(feeAmount);
			emit Transfer(sender, feeTo, feeAmount);
		}		
		_balances[sender] = _balances[sender].sub(amount);
		_balances[recipient] = _balances[recipient].add(recipientAmount);
		emit Transfer(sender, recipient, recipientAmount);
		_afterTokenTransfer(sender, recipient, amount);
	}

	function _takeFee(address _from, address _to) internal view returns (uint) {
		uint feeRate = 0;
		if (SwapPair[_from]){
			feeRate = buyFeeRate;
		}
		if(SwapPair[_to]){
			feeRate = sellFeeRate;
		}
		if (feeRate==0 && _to != address(0) && _to != deadAdd){
			feeRate = sendFeeRate;
		}
		return feeRate;
	}

	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal {}

	function _afterTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal {}

	function isSwapPair(address pair) public view returns(bool){
		return SwapPair[pair];
	}

	function addSwapPair(address _swapPair) external onlyOwner {
		require(_swapPair != address(0),"_swapPair can not be address 0");
		SwapPair[_swapPair] = true;
	}

	function removeSwapPair(address _swapPair) external onlyOwner {
		require(_swapPair != address(0),"_swapPair can not be address 0");
		SwapPair[_swapPair] = false;
	}

	function setBuyFeeRate(uint _rate) external onlyOwner {
		require(_rate <= RATE_PERCISION,"rate too large");
		buyFeeRate = _rate;
	}

	function setSellFeeRate(uint _rate) external onlyOwner {
		require(_rate <= RATE_PERCISION,"rate too large");
		sellFeeRate = _rate;
	}

	function setSendFeeRate(uint _rate) external onlyOwner {
		require(_rate <= RATE_PERCISION,"rate too large");
		sendFeeRate = _rate;
	}

	function setFeeTo(address _feeTo) external onlyOwner {
		feeTo = _feeTo;
	}
}