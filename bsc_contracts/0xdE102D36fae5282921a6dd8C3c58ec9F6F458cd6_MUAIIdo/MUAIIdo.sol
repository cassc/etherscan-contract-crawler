/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

pragma solidity ^0.8.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value
        );
        require(token.approve(spender, newAllowance));
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address internal _owner;

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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
}


contract MUAIIdo is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public isActive;

    bool public switchFirst;

    bool public switchLast;

    address public marketAddress = address(0x2fE143Eb8a22F5d5Bc391C7a030B63DC990680EC);
    address public usdtAddress = address(0x55d398326f99059fF775485246999027B3197955);
    address public tokenAddress = address(0xf9D623f033a1616Df74c6a80194c2d69E1FF1327);

    mapping(uint256 => LevelInfo) private _levelInfo;
    mapping(address => UserInfo) private _userInfo;


    struct LevelInfo {
        uint256 TotalSupply;
        uint256 RemainSupply;
    }

    struct UserInfo {
        address Inviter;
        bool IsBlacklist;
        uint256 PurchaseNum;
        uint256 ClaimReward;
        uint256 DirectReward;
        uint256 InDirectReward;
        uint256[2] PurchaseType;
        address[] InviterSuns;
        address[] InDirectInviterSuns;
        uint256[4] Rewards;
    }

    event BindParent(address indexed user, address indexed inviter);
    event Purchase(address indexed user, uint256 indexed level);
    event Withdraw(address indexed user);

    constructor() {
        _owner = msg.sender;

        _levelInfo[10 * 10 ** 18] = LevelInfo(1500, 1500);
        _levelInfo[20 * 10 ** 18] = LevelInfo(1000, 1000);
        _levelInfo[50 * 10 ** 18] = LevelInfo(300, 300);

        isActive = true;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function bindParent(address parent) public returns (bool) {
        require(_userInfo[msg.sender].Inviter == address(0), "Already bind");
        require(parent != address(0), "ERROR parent");
        require(parent != msg.sender, "error parent");
        _userInfo[msg.sender].Inviter = parent;
        _userInfo[parent].InviterSuns.push(msg.sender);
        if (_userInfo[parent].Inviter != address(0)) {
            _userInfo[_userInfo[parent].Inviter].InDirectInviterSuns.push(msg.sender);
        }
        
        emit BindParent(msg.sender, parent);
        return true;
    }

    function purchase(uint256 level) public returns (bool) {
        require(isActive, "not active");

        LevelInfo memory l = _levelInfo[level];
        require(l.RemainSupply > 0, "not supply");

        UserInfo memory u = _userInfo[msg.sender];
        require(u.PurchaseNum < 2, "not quota");

        // if (u.Inviter == address(0) && parent != address(0)) {
        //     _userInfo[msg.sender].Inviter = parent;
        //     _userInfo[parent].InviterSuns.push(msg.sender);
        //     emit BindParent(msg.sender, parent);
        // }

        IERC20(usdtAddress).safeTransferFrom(msg.sender, marketAddress, level);

        _userInfo[msg.sender].PurchaseType[u.PurchaseNum] = level;
        _userInfo[msg.sender].PurchaseNum++; 

        _levelInfo[level].RemainSupply--;

        address cur = msg.sender;
        for (int256 i = 0; i < 2; i++) {
            cur = _userInfo[cur].Inviter;
            if (cur == address(0)) {
                break;
            }
            if (i == 0) {
                _userInfo[cur].DirectReward = level.mul(10).add(_userInfo[cur].DirectReward);
            } else {
                _userInfo[cur].InDirectReward = level.mul(5).add(_userInfo[cur].InDirectReward);
            }  
        }

        emit Purchase(msg.sender, level);

        return true;
    }

    function withdraw(uint256 level) public returns (bool) {
        require(!_userInfo[msg.sender].IsBlacklist, "user in black list");

        uint256 totalRewards = earned(msg.sender, level);

        IERC20(tokenAddress).safeTransfer(msg.sender, totalRewards);

        _userInfo[msg.sender].ClaimReward = _userInfo[msg.sender].ClaimReward.add(totalRewards);

        if (level == 0) {
            _userInfo[msg.sender].Rewards[0] = _userInfo[msg.sender].Rewards[0].add(totalRewards);
        } else if (level == 10 * 10 ** 18) {
            _userInfo[msg.sender].Rewards[1] = _userInfo[msg.sender].Rewards[1].add(totalRewards);
        } else if (level == 20 * 10 ** 18) {
            _userInfo[msg.sender].Rewards[2] = _userInfo[msg.sender].Rewards[2].add(totalRewards);
        } else if (level == 50 * 10 ** 18) {
            _userInfo[msg.sender].Rewards[3] = _userInfo[msg.sender].Rewards[3].add(totalRewards);
        } 

        emit Withdraw(msg.sender);

        return true;

    }

    function earned(address account, uint256 level) public view returns (uint256) {
        uint256 totalRewards;


        if (level == 0) {
            if (switchLast) {
                totalRewards = _userInfo[account].DirectReward.add(_userInfo[account].InDirectReward).sub(_userInfo[account].Rewards[0]);
                return totalRewards;
            }   
        } else {
            for (uint256 i = 0; i < 2; i++) {
                uint256 l = _userInfo[account].PurchaseType[i];
                if (l == level) {
                    totalRewards = l.mul(100).add(totalRewards);
                }      
            }
        }
             

        if (switchFirst) {
            if (!switchLast) {
                totalRewards = totalRewards.div(2);
            }  
        }else {
            return 0;
        }

        if (level == 10 * 10 ** 18) {
            totalRewards = totalRewards.sub(_userInfo[account].Rewards[1]);
        } else if (level == 20 * 10 ** 18) {
            totalRewards = totalRewards.sub(_userInfo[account].Rewards[2]);
        } else if (level == 50 * 10 ** 18) {
            totalRewards = totalRewards.sub(_userInfo[account].Rewards[3]);
        } 

        return totalRewards;
    }

    function getLevelInfo(uint256 level) public view returns (LevelInfo memory) {
        return _levelInfo[level];
    }

    function getUserInfo(address account) public view returns (UserInfo memory) {
        return _userInfo[account];
    }

    function getRewards(address account) public view returns (uint256[4] memory) {
        return _userInfo[account].Rewards;
    }

    function getInviterSuns(address account) public view returns (address[] memory) {
        return _userInfo[account].InviterSuns;
    }

    function getIndirectInviterSuns(address account) public view returns (address[] memory) {
        return _userInfo[account].InDirectInviterSuns;
    }

    function setSwitchFirst( bool newSwitchFirst) public onlyOwner {
        switchFirst = newSwitchFirst;
    }

    function setSwitchLast( bool newSwitchLast) public onlyOwner {
        switchLast = newSwitchLast;
    }

    function setActive(bool newActive) public onlyOwner {
        isActive = newActive;
    }

    function setBlacklist(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _userInfo[addresses[i]].IsBlacklist = status;
        }
    }

    function setMarketAddress(address newMarketAddress) public onlyOwner {
        marketAddress = newMarketAddress;
    }

    function OwnerWithdraw(address to, uint256 tAmount) public onlyOwner {
        IERC20(tokenAddress).safeTransfer(to, tAmount);
    }

    function OwnerBrunAllWithdraw() public onlyOwner {
        IERC20(tokenAddress).safeTransfer(address(0), IERC20(tokenAddress).balanceOf(address(this)));
    } 
}