/**
 *Submitted for verification at BscScan.com on 2023-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;



interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */

    /** 
     * @dev Moves `Refer Balance` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
     function Refer(address account) external view returns (uint256);
    
    

    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


library SafeMath  {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
  

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract TIMEUSDC {

   uint256 public DEFAULT_ROI = 4;
   uint256 public POWER_ROI_1 = 7;
   uint256 public POWER_ROI_2 = 9;
   uint256 public POWER_PRICE_1 = 200 ether;
   uint256 public POWER_PRICE_2 = 400 ether;
   uint256 public MIN_INVEST = 30 ether;
   uint256 public fee = 2;
   uint256 public reffee = 4;
   uint256 public BSC_BLOCK = 28800;
   address public dev = 0x34Baa5654AdC7D08088Aa288e5EEa143200357c1;
   uint256 public RD_FEE = 1;
   uint256 public total_investment = 0;
   uint256 public total_withdrawm = 0;
   bool public init = false;
   address owner;
   address public tokenAddress;
   IERC20 public USDC;

     constructor() {
        tokenAddress = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
        USDC = IERC20(tokenAddress);
        owner = msg.sender;
    }
   
   struct deposit_USDC {
       address _addr;
       uint256 amount;
       uint256 block_id;
       uint256 package;
       uint256 max;
       uint256 package_deadline;
   }

   struct withdraw_USDC {
       address _addr;
       uint256 amount;
   }

   struct BonusLevel {
       address _addr;
       uint256 amount;
       uint256 total_amount;
   }


 
   mapping(address => deposit_USDC) public deposit_usdc;
   mapping(address => withdraw_USDC) public withdraw_usdc;
   mapping(address => BonusLevel) public bonus;



   function deposit(uint256 usdc_amount, address _ref) public {
       require(usdc_amount>= MIN_INVEST,"You cannot invest less than 30 USDC");
       require(init,"Project is not started");
       require(_ref != msg.sender && _ref != address(0) && _ref != owner, "You cannot use the referral address the one you are using");
       deposit_USDC storage depomap = deposit_usdc[msg.sender];
       BonusLevel storage refD = bonus[_ref];

       uint256 directRef = ref_direct_calculator(usdc_amount);
       uint256 I_REF = ref_calculator(usdc_amount);
       uint256 value = fee_calculator(usdc_amount);
       uint256 directValue = value + directRef + I_REF;
       uint256 total = usdc_amount - directValue;
       uint256 total2 = usdc_amount - value;
       
       total_investment += usdc_amount;
       
       refD.amount += directRef;
       depomap._addr = msg.sender;
       
      if(depomap.amount == 0) {
        depomap.block_id = block.number;
       }
      
       if(depomap.package == 0) {
           depomap.package = 0;
       } 
       if(depomap.max == 0) {
          depomap.max = 1;
       }
      depomap.amount += total; 
      deposit_usdc[_ref].amount += I_REF;
      USDC.transferFrom(msg.sender,address(this),total2);
      USDC.transferFrom(msg.sender,dev,value);
      }


      function NEW_DEPOSIT_STOP() public {
          require(msg.sender == owner);
          init = false;
      }

      function START_DEPOSIT_AGAIN() public {
          require(msg.sender == owner);
          init = true;
      }
     

   

   function reinvest() public {
       
      deposit_USDC storage depoRe = deposit_usdc[msg.sender];
      require(depoRe.amount>0,"You must deposit first to get your Referral");
      depoRe.amount += ROI_NOW(msg.sender);
      depoRe.block_id = block.number;

        if(block.timestamp >= depoRe.package_deadline) {
          depoRe.package = 0;
          depoRe.max = 1;
      }
   }

   function withdraw_reward() public {
      withdraw_USDC storage withdraw = withdraw_usdc[msg.sender];
      deposit_USDC storage deposit1 = deposit_usdc[msg.sender];
      require(deposit1.amount>0,"You must deposit first to get your Referral");
      uint256 reward = ROI_NOW(msg.sender);
      uint256 fee_value = fee_calculator(reward);
      uint256 value = reward - fee;
      USDC.transfer(msg.sender,value);
      USDC.transfer(dev,fee_value);

      withdraw.amount += reward;
      deposit1.block_id = block.number;
      if(withdraw.amount >= deposit1.max * deposit1.amount) {
          deposit1.amount = 0;
          deposit1.package = 0;
          deposit1.max = 0;
      } 
      if(block.timestamp >= deposit1.package_deadline) {
          deposit1.package = 0;
          deposit1.max = 1;
      }
      total_withdrawm += reward;
   }
    
   function Buy_Power(uint256 usdc_amount, uint256 _id) public {
       deposit_USDC storage depoPower = deposit_usdc[msg.sender];
       if(_id == 1) {
           require(usdc_amount == POWER_PRICE_1, "You cannot buy power 1 with this amount");
           depoPower.max = 2;
           depoPower.package = 1;
           depoPower.package_deadline = block.timestamp + 20;
           USDC.transferFrom(msg.sender,address(this),usdc_amount);
       }
       else if(_id == 2) {
           require(usdc_amount == POWER_PRICE_2, "You cannot buy power 2 with this amount");
           depoPower.max = 3;
           depoPower.package = 2;
           depoPower.package_deadline = block.timestamp + 40;
           USDC.transferFrom(msg.sender,address(this),usdc_amount);
       }
    
   }

   function directWithdrawRef() public {
       deposit_USDC storage depoRe = deposit_usdc[msg.sender];
     
       require(depoRe.amount>0,"You must deposit first to get your Referral");
       BonusLevel storage refD = bonus[msg.sender];
       USDC.transfer(msg.sender,refD.amount);
       refD.total_amount += refD.amount;
       refD.amount = 0;
       total_withdrawm += refD.amount;
   }


   function ROI_NOW(address _addr) public view returns(uint256) {
       deposit_USDC storage RoiInfo = deposit_usdc[_addr];
      
       if(RoiInfo.package == 1) {
           uint256 capital = RoiInfo.amount / 100  * POWER_ROI_1;
           uint256 blockno = RoiInfo.block_id;
           uint256 currentblock = block.number;
           uint256 total = currentblock - blockno;
           uint256 perBlock = capital / BSC_BLOCK;
           return total * perBlock;
       }
        else if(RoiInfo.package == 2) {
           uint256 capital = RoiInfo.amount / 100  * POWER_ROI_2;
           uint256 blockno = RoiInfo.block_id;
           uint256 currentblock = block.number;
           uint256 total = currentblock - blockno;
           uint256 perBlock = capital / BSC_BLOCK;
           return total * perBlock;
       }

      else {
           uint256 capital = RoiInfo.amount / 100  * DEFAULT_ROI;
           uint256 blockno = RoiInfo.block_id;
           uint256 currentblock = block.number;
           uint256 total = currentblock - blockno;
           uint256 perBlock = capital / BSC_BLOCK;
           return total * perBlock;
       }
       
   } 

   function Start(uint256 seed_market) public {
       BonusLevel storage PortFolio = bonus[msg.sender];
       require(owner == msg.sender,"You are not an owner");
       require(!init,"You cannot call this function again");
       init = true;
       PortFolio.amount = seed_market;
     }

   

   function fee_calculator(uint256 _amount) public view returns(uint256) {
       return _amount / 100 * fee;
   }

   function ref_calculator(uint256 _amount) public view returns(uint256) {
       return _amount / 100 * reffee;
   }

   function ref_direct_calculator(uint256 _amount) public view returns(uint256) {
       return _amount / 100 * RD_FEE;
   }

   function TVL() public view returns(uint256) {
       return USDC.balanceOf(address(this));
   }

   
}