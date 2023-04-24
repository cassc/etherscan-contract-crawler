/**
 *Submitted for verification at BscScan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;




/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
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
    constructor () internal {
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

interface IPlantCore {
    function mintPlantByPermission(address _owner, uint8 _ticketType, uint8 _parity, uint8 _zone, uint256 _startRange, uint256 _endRange) external;
    function burnPlantByPermission(address _owner,uint256 _tokenId) external;
    function getPlant(uint256 _tokenId) external view returns (uint8 ticketType, uint8 parity, uint8 _zone, uint256 startRange, uint256 endRange);
}

interface IRandomIDGenertor {

    function getRandomID(address _owner) external returns(uint256);

}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}



contract RandomIDGenertor is Ownable, IRandomIDGenertor {


    uint256 private nonce = 0;
    mapping(address => bool) public permission;
    mapping(uint256 => uint256[]) public skillPool;
    mapping(uint256 => uint256[]) public skillZonePool;

    modifier onlyPermission() {
        require(permission[msg.sender], "NOT_THE_PERMISSION");
        _;
    }

    function setPermission(address _address, bool _status) external onlyOwner {
        permission[_address] = _status;
    }


    function getRandomID(address _owner) external override onlyPermission returns(uint256){
        uint256 number = _randomNumber(_owner) % 10000 + 1;
        uint256 plantID;

        if(number <= 9600){
            uint256 plantType = number % 9 + 1;
            plantID = 100000000000 + plantType * 10**10;
            uint256 plantNumber;

            if(number <= 5500){ //common
                plantNumber = number % 2 + 1;
                plantID += plantNumber * 10**8;
            } else if (number > 5500 && number <= 8500){
                plantNumber = 3;
                plantID += plantNumber * 10**8;
            } else if (number > 8500 && number <= 9400){
                plantNumber = 4;
                plantID += plantNumber * 10**8;
            } else{
                plantNumber = 5;
                plantID += plantNumber * 10**8;
            }

            plantID +=  _randomSkill(_owner) * 10**6 + _randomSkillZone(_owner) * 10**4 + _randomSupport(_owner) * 10**2 + _randomSabotage(_owner);
            return plantID;

        } else {
            plantID = 2000000000;
            uint256 plantType = number % 9 + 1;
            uint256 plantNumber = number % 4+ 1;
            plantID += plantType * 10**8 + plantNumber * 10**6;
            if(number <= 9850){
                plantID += 1 * 10 ** 4 +1 * 10**2 + 1;
            }else if(number > 9850 && number <= 9850){
                plantID += 2 * 10 ** 4 +1 * 10**2 + 2;
            }else if(number > 9850 && number <= 9890){
                plantID += 3 * 10 ** 4 +1 * 10**2 + 3;
            }else{
                plantID += 4 * 10 ** 4 +1 * 10**2 + 4;
            }
            return plantID;
        }

    }

    function _randomSkill(address _owner) private returns(uint256){
        uint256 number =  _randomNumber(_owner) % 1000 + 1;
        uint256 skill;
        if(number <= 700){
            skill = number % skillPool[3].length;
            return skillPool[3][skill];
        }else if(number > 700 && number <= 955){
            skill = number % skillPool[2].length;
            return skillPool[2][skill];
        }else{
            skill = number % skillPool[1].length;
            return skillPool[1][skill];
        }
    }

    function _randomSkillZone(address _owner) private returns(uint256){
        uint256 number =  _randomNumber(_owner) % 1000 + 1;
        uint256 skillZone;

        if(number <= 600){
            skillZone = number % skillZonePool[3].length;
            return skillZonePool[3][skillZone];
        }else if(number > 600 && number <= 980){
            skillZone = number % skillZonePool[2].length;
            return skillZonePool[2][skillZone];
        }else{
            skillZone = number % skillZonePool[1].length;
            return skillZonePool[1][skillZone];
        }
    }

    function _randomSupport(address _owner) private returns(uint256) {
        uint256 number =  _randomNumber(_owner) % 1000 + 1;

        if(number <= 200){
            return 1;
        } else if(number > 200 && number <= 380){
            return 2;
        } else if(number > 380 && number <= 540){
            return 3;
        } else if(number > 540 && number <= 680){
            return 4;
        } else if(number > 680 && number <= 800){
            return 5;
        } else if(number > 800 && number <= 880){
            return 6;
        } else if(number > 880 && number <= 940){
            return 7;
        } else if(number > 940 && number <= 970){
            return 8;
        } else if(number > 970 && number <= 990){
            return 9;
        } else {
            return 10;
        }
    }

    function _randomSabotage(address _owner) private returns(uint256){
        uint256 number =  _randomNumber(_owner) % 1000 + 1;

        if(number <= 200){
            return 1;
        } else if(number > 200 && number <= 380){
            return 2;
        } else if(number > 380 && number <= 540){
            return 3;
        } else if(number > 540 && number <= 680){
            return 4;
        } else if(number > 680 && number <= 800){
            return 5;
        } else if(number > 800 && number <= 880){
            return 6;
        } else if(number > 880 && number <= 940){
            return 7;
        } else if(number > 940 && number <= 970){
            return 8;
        } else if(number > 970 && number <= 990){
            return 9;
        } else {
            return 10;
        }
    }

    function _randomNumber(address _owner) private returns (uint256) {
        uint256 randomN = uint256(blockhash(block.number));
        uint256 number = uint256(keccak256(abi.encodePacked(randomN, block.timestamp, nonce, _owner)));
        nonce++;

        return number;
    }

    function setSkillPool(uint256 _id, uint256[] memory _skills) external onlyOwner {
        skillPool[_id] = _skills;
    }

    function setSkillZonePool(uint256 _id, uint256[] memory _skillZone) external onlyOwner {
        skillZonePool[_id] = _skillZone;
    }

    function withdrawBalance(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

}