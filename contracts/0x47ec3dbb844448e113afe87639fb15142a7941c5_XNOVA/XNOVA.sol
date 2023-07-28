/**
 *Submitted for verification at Etherscan.io on 2023-07-22
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: d1.sol

pragma solidity ^0.8.0;

interface XNOVAinterface {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender,address recipient,uint256 amount ) external returns (bool);

    // function pledgeReward(address account, uint256 amount)external returns  (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
}

contract XNOVA is XNOVAinterface  {
    using SafeMath for uint256;
    address public  nftContractAddr;
    uint256 private _nonce;
    uint256 private _number;
    uint256 public  _proportion;
    address private _owner;
    uint256 public  bTokens;
    uint256 public  nftTokenNum;
    uint256 public  nftTokenNumed;
    uint256 public  receivedToken;
    uint256 private _totalSupply;
    string private  _name;
    string private  _symbol;
    mapping(address => bool) public blacklists; 
    struct AddressData {
        uint256 code;
        bool enabled;
    }
    mapping(uint256 => address) private _inviterAddr;
    mapping(address => AddressData) private lists; 
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _visited;

    event InvitationAddr(uint256 invitationCode,address indexed from);

    constructor(string memory name, string memory symbol,uint256 supply) {
         _name = name;
        _symbol = symbol;
        _owner = msg.sender;
        nftTokenNum=supply*50/100;
        _mint(msg.sender, supply);
        _balances[_owner]-=nftTokenNum;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "caller is not the owner");
        _;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
     function owner() public view virtual returns (address) {
        return _owner;
    }

    function setList(address account, bool isBool) external onlyOwner {
        require(account != address(0), "Approve from the zero address");
        require(!blacklists[account], "Blacklisted");
        uint256 code = uint256(keccak256(abi.encodePacked(block.timestamp, _nonce))) % 1000000;
        uint256 invitationCode=code+100000;
        _inviterAddr[invitationCode] = account;
        lists[account].code= invitationCode;
        lists[account].enabled= isBool;

        emit InvitationAddr(invitationCode,account);
        _nonce++;
    }

    function getInvitationCode(address from) public  view returns (uint256) {
        require(!blacklists[from], "Blacklisted");
        require(lists[from].enabled, "The invitation code is no longer allowed to be used"); 
        uint256 code = lists[from].code;
        return code;
    }

    function claimAirdrop(address account, uint256 invitationCode) public virtual returns (bool) {
        require(!blacklists[account], "Blacklisted");
        require(!_visited[account], "Address has already visited");
        require(_inviterAddr[invitationCode] != address(0), "Invitation code mismatch"); 
        address inviterAddr=_inviterAddr[invitationCode];
        require(lists[inviterAddr].enabled, "The invitation code is no longer allowed to be used"); 
        require(receivedToken + _number <= bTokens, string(abi.encodePacked("The current reward has been claimed completely")));
         _balances[account] += _number;
        if(account!=inviterAddr){
             _balances[inviterAddr] += _number/_proportion;
        }
        receivedToken+= _number;
        _visited[account] = true;
        return true;
    }


    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

      function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 12;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function pledgeReward(address account, uint256 amount)public virtual  returns (bool) {
        require(!blacklists[account], "Blacklisted");
        require(nftContractAddr!=address(0) && msg.sender==nftContractAddr,  "Only available for configuration contract calls");
        require(nftTokenNumed + amount <= nftTokenNum,"Staking rewards exceed settings");
       _balances[account] += amount;
        nftTokenNumed+=amount;
        return true;
    }

    function setNftContractAddr(address contractAddr) external onlyOwner {
        nftContractAddr=contractAddr;
    }

    function setAirdrop(uint256  number, uint256  proportion,uint256 supplyed)external onlyOwner {
        _number = number;
        _proportion = proportion;
        bTokens +=   supplyed ; 
        require(_balances[_owner]-bTokens >= 0, "Insufficient account balance");
        _balances[_owner]-=supplyed;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function transferFrom(address sender,address recipient,uint256 amount) public virtual onlyOwner override returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "burn from the zero address");
        require(!blacklists[account], "Blacklisted");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

     function _transfer(address sender, address recipient,uint256 amount ) internal virtual {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");
        require(!blacklists[recipient] && !blacklists[sender], "Blacklisted");
   
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _afterTokenTransfer(address from,address to,uint256 amount
    ) internal virtual {}
}