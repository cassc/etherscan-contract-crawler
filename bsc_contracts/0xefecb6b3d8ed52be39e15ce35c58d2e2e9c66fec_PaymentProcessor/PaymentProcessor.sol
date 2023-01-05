/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

contract PaymentProcessor is Ownable{

    address feeAddress;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    using SafeMath for uint256;
    mapping(uint256 => contracts) _contractinfo;

    struct contracts {
        uint256 contractNumber;
        address addressOwner;
        address addressPartner;
        address addressThirdparty;
        uint256 contractAmount;
        mapping(address => mapping(address => bool)) _Agreement;
    }


    function setFeeAddress(address _feeAddress) external onlyOwner{
        feeAddress = _feeAddress;
    }

    function viewFeeAddress() external view onlyOwner returns (address){
        return feeAddress;
    }

    function randomnumber(uint256 MaxNumber) internal view returns (uint256){ 
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % MaxNumber +1;
    }

    function newContract(address addOwner, address addPartner, address addThirdparty, uint256 randomcode, uint256 amount) external payable returns(uint256){
        require(msg.sender == addOwner);
        require(amount <= msg.value , "Insufficient Funds");
        uint256 contractcode = randomcode.add(randomnumber(_tokenIdTracker.current()));
        _tokenIdTracker.increment();
        contracts storage newcontract = _contractinfo[contractcode];
        newcontract.contractNumber = contractcode;
        newcontract.addressOwner = addOwner;
        newcontract.addressPartner = addPartner;
        newcontract.addressThirdparty = addThirdparty;
        newcontract.contractAmount = amount;

        return contractcode;
    }

/////////APPROVE FUNCTIONS START////////////////////////////////////////////////////
    function setThirdpartyApproval(uint256 contractcode, address approveAddress, bool vote) external {
        require(msg.sender == _contractinfo[contractcode].addressThirdparty, "Only predefined Contract Thirdparty can approve");
        require(approveAddress == _contractinfo[contractcode].addressPartner || approveAddress == _contractinfo[contractcode].addressOwner, "Can only Appove funds for Contract Owner or Partner");
        _contractinfo[contractcode]._Agreement[msg.sender][approveAddress] = vote;
    }


    function setOwnerApproval(uint256 contractcode, bool vote) external {
        require(msg.sender == _contractinfo[contractcode].addressOwner, "Only predefined Contract owner can approve");
        _contractinfo[contractcode]._Agreement[msg.sender][_contractinfo[contractcode].addressPartner] = vote;
    }
/////////APPROVE FUNCTIONS END/////////////////////////////////////////////////////////

/////////BALANCE START/////////////////////////////////////////////////////////////////
    function contractbalance(uint256 contractcode) public view returns (uint256) {
        return _contractinfo[contractcode].contractAmount;
    }
/////////BALANCE END///////////////////////////////////////////////////////////////////


/////////WITHDRAWL START///////////////////////////////////////////////////////////////
/////////PARTNER WITHDRAWAL START//////////////////////////////////////////////////////
    function withdrawalPartner(uint256 contractcode, uint256 amount) public {
        require(msg.sender == _contractinfo[contractcode].addressPartner, "Only Partner of contract can make this withdrawal");
        require(contractbalance(contractcode) >= amount, "Insufficient Balance");
        require(_contractinfo[contractcode]._Agreement[_contractinfo[contractcode].addressThirdparty][msg.sender], "Thirdparty does not agree with this release payment");
        uint256 fee = amount.mul(2).div(100);
        _withdraw(msg.sender, amount.sub(fee));
        _withdraw(feeAddress, fee);
        _contractinfo[contractcode].contractAmount -= amount;

    }
/////////PARTNER WITHDRAWAL END////////////////////////////////////////////////////////
/////////OWNER RECLAIM FUNDS START/////////////////////////////////////////////////////
    function withdrawalOwner(uint256 contractcode, uint256 amount) public {
        require(contractbalance(contractcode) >= amount);
        require(msg.sender == _contractinfo[contractcode].addressOwner, "Only owner of contract can make this withdrawal");
        require(_contractinfo[contractcode]._Agreement[_contractinfo[contractcode].addressThirdparty][msg.sender], "Thirdparty does not agree with this release payment");
        uint256 fee = amount.mul(2).div(100);
        _withdraw(msg.sender, amount.sub(fee));
        _withdraw(feeAddress, fee);
        _contractinfo[contractcode].contractAmount-= amount;
    }
/////////OWNER RECLAIM FUNDS END///////////////////////////////////////////////////////
function _withdraw(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
    }
/////////WITHDRAWL END/////////////////////////////////////////////////////////////////


/////////VIEW OWNER PARTNER AND THIRDPARTY ADDRESS START/////////////////////////////////////
    function contractPartnerIs(uint256 contractcode) external view returns (address) {
        return _contractinfo[contractcode].addressPartner;
    }

    function contractThirdpartyIs(uint256 contractcode) external view returns (address) {
        return _contractinfo[contractcode].addressThirdparty;
    }

    function contractOwnerIs(uint256 contractcode) external view returns (address) {
        return _contractinfo[contractcode].addressOwner;
    }
/////////VIEW PARTNER AND THIRDPARTY ADDRESS END/////////////////////////////////////

}