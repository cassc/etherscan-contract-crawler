/**
 *Submitted for verification at Etherscan.io on 2023-08-02
*/

/**
 *Submitted for verification at Etherscan.io on 2023-07-31
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol
// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
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

// File: CashBox.sol



pragma solidity ^0.8.0;


interface  ERC20Basic {    
    function transfer(address to, uint value) external;  
    function balanceOf(address who) external returns (uint); 
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

interface  IERC721 {
     function balanceOf(address owner) external view returns (uint256 balance);
}



contract CashBox  {
    using SafeMath for uint;     

    ERC20Basic USDT = ERC20Basic(0xdAC17F958D2ee523a2206206994597C13D831ec7);   
    IERC721 Minerpunk = IERC721(0x90544049d50c012caF6F5F1C10344b7A9c05A064); 
    IERC1155 badges = IERC1155(0x73b8CeB6D96202c37D2d168931D3e4D4F33e8c7D); 

     modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    constructor(uint256 _openingHours, uint256 _USDTamount){
        owner = msg.sender;
        round = 1;
        openingHours = _openingHours;
        time = 1 hours;
        USDTamount = _USDTamount;
    }


    address owner;
    uint256 private round;
    uint256 private openingHours;
    uint256 private time;
    uint256 private USDTamount;
    mapping(address =>mapping(uint256 =>bool)) roundParticipation ; //該回合資格
    mapping(uint256 => uint256)achievementStatus;  // 1. badge01 2. minerpunk 3.badge05
    mapping (uint256=>address)acquirer;
    


    function USDTGrabber () external {
        require (block.timestamp >= openingHours);
        require(roundParticipation[msg.sender][round] == false );
        require(badges.balanceOf(msg.sender, 1) >= achievementStatus[1],"you don't have a badge01");
        require(Minerpunk.balanceOf(msg.sender) >= achievementStatus[2],"you don't have a Minerpunk NFTs" );
        require(badges.balanceOf(msg.sender, 5) >= achievementStatus[3],"you don't have a badge05");

        USDT.transfer(msg.sender, USDTamount);
        roundParticipation[msg.sender][round] = true;
        acquirer[round] = msg.sender;

        if(USDT.balanceOf(address(this)) <= 100000){
             openingHours =  openingHours.add(365 days);            
        }else{
            openingHours = openingHours.add(time);
        }
        
      
    }

    function ViewroundParticipation (address _addr, uint256 _round) external  view returns (bool){
        return   roundParticipation[_addr][_round] ;
    }

    function Viewacquirer (uint256 _round) external  view returns (address){
        return   acquirer[_round] ;
    }



    function setAchievementStatus (uint256 _regulations, uint256 _condition) external onlyOwner {
        achievementStatus[_regulations] = _condition;
    }

    function ViewAchievementStatus (uint256 _regulations) external  view returns (uint256){
        return   achievementStatus[_regulations] ;
    }

    function setRound (uint256 _Round) external onlyOwner {
        round = _Round;
    }

    
    function ViewRound () external  view returns (uint256){
        return  round;
    }

    function settime (uint256 _time) external onlyOwner {
        time = _time;
    }

    function Viewtime () external  view returns (uint256){
        return  time;
    }

    function setUSDTamount (uint256 _USDTamount) external onlyOwner {
        USDTamount = _USDTamount;
    }

     function ViewUSDTamount () external  view returns (uint256){
        return  USDTamount;
    }


    function setopeningHours (uint256 _openingHours) external onlyOwner {
        openingHours = _openingHours;
    }

    function ViewopeningHours () external  view returns (uint256){
        return  openingHours;
    }

    


   
   
    
}