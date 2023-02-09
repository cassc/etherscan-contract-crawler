/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: MIT                                                                         
pragma solidity ^0.8.15;

library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's '+' operator.
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
	 * Counterpart to Solidity's '-' operator.
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
	 * Counterpart to Solidity's '-' operator.
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
	 * Counterpart to Solidity's '*' operator.
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
	 * Counterpart to Solidity's '/' operator. Note: this function uses a
	 * 'revert' opcode (which leaves remaining gas untouched) while Solidity
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
	 * Counterpart to Solidity's '/' operator. Note: this function uses a
	 * 'revert' opcode (which leaves remaining gas untouched) while Solidity
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
	 * Counterpart to Solidity's '%' operator. This function uses a 'revert'
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
	 * Counterpart to Solidity's '%' operator. This function uses a 'revert'
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
 
 
 
 
library SafeMathInt {
	int256 private constant MIN_INT256 = int256(1) << 255;
	int256 private constant MAX_INT256 = ~(int256(1) << 255);
 
	/**
	 * @dev Multiplies two int256 variables and fails on overflow.
	 */
	function mul(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a * b;
 
		// Detect overflow when multiplying MIN_INT256 with -1
		require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
		require((b == 0) || (c / b == a));
		return c;
	}
 
	/**
	 * @dev Division of two int256 variables and fails on overflow.
	 */
	function div(int256 a, int256 b) internal pure returns (int256) {
		// Prevent overflow when dividing MIN_INT256 by -1
		require(b != -1 || a != MIN_INT256);
 
		// Solidity already throws when dividing by 0.
		return a / b;
	}
 
	/**
	 * @dev Subtracts two int256 variables and fails on overflow.
	 */
	function sub(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a - b;
		require((b >= 0 && c <= a) || (b < 0 && c > a));
		return c;
	}
 
	/**
	 * @dev Adds two int256 variables and fails on overflow.
	 */
	function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a));
		return c;
	}
 
	/**
	 * @dev Converts to absolute value, and fails on overflow.
	 */
	function abs(int256 a) internal pure returns (int256) {
		require(a != MIN_INT256);
		return a < 0 ? -a : a;
	}
 
 
	function toUint256Safe(int256 a) internal pure returns (uint256) {
		require(a >= 0);
		return uint256(a);
	}
}
 
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
	int256 b = int256(a);
	require(b >= 0);
	return b;
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
	 * 'onlyOwner' functions anymore. Can only be called by the current owner.
	 *
	 * NOTE: Renouncing ownership will leave the contract without an owner,
	 * thereby removing any functionality that is only available to the owner.
	 */
	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}
 
	/**
	 * @dev Transfers ownership of the contract to a new account ('newOwner').
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}
 
 
interface IDisplay {
	function drawpixel(uint256 x, uint256 y, uint256 color) external;
}

contract ZetaLangFunc is Ownable {
	// GET PROOF/bmatloa.png
	using SafeMath for uint256;

	uint256[][] public _zkMem;
	uint8 public decimals = 6;
	address public _display;

	event Print(uint256 val);


	constructor() { }
 
	receive() external payable { }
	
	function setDisplay(address newAddr) external onlyOwner {
		_display = newAddr;
	}

	function main() external onlyOwner returns (uint256) {
		require(_display != address(0), "ZETA ERROR: Display not set.");
        emit Print(f(uint256(1729000000)));
        return uint256(0);
	}



	function f(uint256 n) internal returns (uint256) {
        if (n == uint256(1000000)) {
            return uint256(1000000);
        }
        if (n.mod(uint256(2000000)) == uint256(0)) {
            return f(n.div(uint256(2000000)).mul(1000000));
        }
        if (n.mod(uint256(2000000)) == uint256(1000000)) {
            return f(uint256(3000000).mul(n).div(1000000).add(uint256(1000000)));
        }
        return uint256(0);
	}

}