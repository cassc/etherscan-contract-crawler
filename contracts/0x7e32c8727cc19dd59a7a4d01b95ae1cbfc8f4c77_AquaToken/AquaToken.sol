/**
 *Submitted for verification at Etherscan.io on 2020-12-27
*/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.0;



contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// File: @openzeppelin/contracts/access/roles/WhitelistAdminRole.sol

pragma solidity ^0.5.0;



/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/AquaToken.sol

pragma solidity ^0.5.17;




contract AquaToken is
    MinterRole,
    WhitelistAdminRole
{
    using SafeMath for uint256;

    mapping (address => uint256) private _wOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private constant MAX = ~uint256(0);
    // denotes display total (aqua)
    uint256 private _aTotal = 0;
    // denotes actual total (waves)
    uint256 private _wTotal = 0;
    // display total fees
    uint256 private _aFeeTotal;

    address public fountainAddress;
    address public uniswapPairAddress;
    // tax divisor - 25 => 4% (100/25)
    uint256 public taxDivisor = 25;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    bool public tokenPaused;
    mapping (address => bool) public pauseWhitelist;
    //set claimable amounts for the token swap
    mapping (address => uint256) public claimingAmounts;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event RewardLiquidityProviders(uint256 value);

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        pauseWhitelist[_msgSender()] = true;

        //mint max supply ~17418, rest will be burned after claim is over
        _mint(address(this), 17418000000000);
        // enable token pause to avoid frontrunning lp listing, once LP is listed, we destroy the usage of tokenPaused
        tokenPaused = true;
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

    function setTokenPaused(bool paused) external onlyWhitelistAdmin {
        require(paused == false, "AquaToken::setTokenPaused: you can only unpause the token");
        tokenPaused = paused;
        // burn the rest of the tokens this contract has
        _transferStandard(address(this), address(0), balanceOf(address(this)));
    }

    function setTaxDivisor(uint256 _taxDivisor) public onlyWhitelistAdmin {
        require(_taxDivisor == 0 || _taxDivisor >= 10, "AquaToken::setTaxDivisor: too small");
        taxDivisor = _taxDivisor;
    }

    function setUniswapPair(address _uniswapPairAddress) public onlyWhitelistAdmin {
        uniswapPairAddress = _uniswapPairAddress;
    }

    function setFountainAddress(address _fountainAddress) public onlyWhitelistAdmin {
        fountainAddress = _fountainAddress;
    }

    function rewardLiquidityProviders() external {
        require(balanceOf(address(this)) > 0, "Transfer amount must be greater than zero");
        require(balanceOf(address(_msgSender())) > 0, "You must be an account holder to call this function");

        uint256 originalBalance = balanceOf(address(this));

        uint256 uniswapPairAmount = originalBalance.mul(475).div(575); // ~83%
        uint256 fountainPairAmount = originalBalance.mul(72).div(575); // ~12%
        uint256 userRewardAmount = originalBalance.mul(28).div(575); // ~5%

        _transferStandard(address(this), uniswapPairAddress, uniswapPairAmount);
        IUniswapV2Pair(uniswapPairAddress).sync();

        _transferStandard(address(this), fountainAddress, fountainPairAmount);
        IUniswapV2Pair(fountainAddress).sync();

        _transferStandard(address(this), _msgSender(), userRewardAmount);

        emit RewardLiquidityProviders(originalBalance);
    }

    function totalSupply() public view returns (uint256) {
        // since we burn tokens, return supply - current burn balance
        return _aTotal.sub(balanceOf(address(0)));
    }

    // display only
    function totalFees() public view returns (uint256) {
        return _aFeeTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        require(_wOwned[account] <= _wTotal, "Amount must be less than total waves");
        uint256 currentRate =  _getRate();
        return _wOwned[account].div(currentRate);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");
        require(pauseWhitelist[from] == true || tokenPaused == false, "ERC20: Token is currently paused");

        // disable tax for whitelisters (crowdsale and treasury)
        if (taxDivisor != 0 && pauseWhitelist[from] == false) {
            uint256 taxAmount = amount.div(taxDivisor);

            uint256 uniswapPairAmount = taxAmount.mul(500).div(1000); // 50%
            uint256 fountainAmount = taxAmount.mul(75).div(1000); // 7.5%
            uint256 burnedAmount = taxAmount.mul(250).div(1000);  // 25%
            uint256 holdersAmount = taxAmount.mul(175).div(1000); // 17.5%

            require(fountainAmount.add(uniswapPairAmount).add(burnedAmount).add(holdersAmount) <= taxAmount, "ERC20Transfer::taxTransfer: Math is broken");
            _transferStandard(from, address(this), uniswapPairAmount.add(fountainAmount));
            _transferStandard(from, address(0), burnedAmount);
            _transferStandard(from, to, amount.sub(taxAmount));

            _distributeFee(from, holdersAmount);
        }
        else {
            _transferStandard(from, to, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 amount) private {
        uint256 currentRate =  _getRate();

        uint256 rAmount = amount.mul(currentRate);
        _wOwned[sender] = _wOwned[sender].sub(rAmount);
        _wOwned[recipient] = _wOwned[recipient].add(rAmount);

        emit Transfer(sender, recipient, amount);
    }

    function _distributeFee(address sender, uint256 aFee) private {
        uint256 currentRate =  _getRate();

        uint256 wFee = aFee.mul(currentRate);
        _wOwned[sender] = _wOwned[sender].sub(wFee);

        _wTotal = _wTotal.sub(wFee);
        _aFeeTotal = _aFeeTotal.add(aFee);

        emit Transfer(sender, address(0), aFee);
    }

    function _getRate() private view returns(uint256) {
        return _wTotal.div(_aTotal);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        require(amount > 0, "ERC20: mint amount is zero");
        _aTotal = _aTotal.add(amount);
        _wTotal = (MAX - (MAX % _aTotal));

        // only have 1 minter, they will have the entire supply
        _wOwned[account] = _wTotal;

        pauseWhitelist[account] = true;

        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setClaims(address[] calldata _recipients, uint256[] calldata _values) external onlyWhitelistAdmin {
        for (uint256 index = 0; index < _recipients.length; index++) {
            claimingAmounts[_recipients[index]] = _values[index];
        }
    }

    function claimTokens() external {
        uint256 amount = claimingAmounts[_msgSender()];
        require(amount > 0, "ERC20: beneficiary is not due any tokens");

        claimingAmounts[_msgSender()] = 0;
        _transferStandard(address(this), _msgSender(), amount);
    }
}

interface IUniswapV2Pair {
    function sync() external;
}