/**
 *Submitted for verification at Etherscan.io on 2019-08-22
*/

pragma solidity ^0.5.11;

// Voken Shareholders Contract for Voken2.0
//
// More info:
//   https://vision.network
//   https://voken.io
//
// Contact us:
//   [email protected]
//   [email protected]


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow checks.
 */
library SafeMath256 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


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


/**
 * @dev Interface of the ERC20 standard
 */
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @dev Interface of an allocation contract
 */
interface IAllocation {
    function reservedOf(address account) external view returns (uint256);
}


/**
 * @dev Interface of Voken2.0
 */
interface IVoken2 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mintWithAllocation(address account, uint256 amount, address allocationContract) external returns (bool);
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
contract Ownable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipAccepted(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the addresses of the current and new owner.
     */
    function owner() public view returns (address currentOwner, address newOwner) {
        currentOwner = _owner;
        newOwner = _newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     *
     * IMPORTANT: Need to run {acceptOwnership} by the new owner.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);
        _newOwner = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     *
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Accept ownership of the contract.
     *
     * Can only be called by the new owner.
     */
    function acceptOwnership() public {
        require(msg.sender == _newOwner, "Ownable: caller is not the new owner address");
        require(msg.sender != address(0), "Ownable: caller is the zero address");

        emit OwnershipAccepted(_owner, msg.sender);
        _owner = msg.sender;
        _newOwner = address(0);
    }

    /**
     * @dev Rescue compatible ERC20 Token
     *
     * Can only be called by the current owner.
     */
    function rescueTokens(address tokenAddr, address recipient, uint256 amount) external onlyOwner {
        IERC20 _token = IERC20(tokenAddr);
        require(recipient != address(0), "Rescue: recipient is the zero address");
        uint256 balance = _token.balanceOf(address(this));

        require(balance >= amount, "Rescue: amount exceeds balance");
        _token.transfer(recipient, amount);
    }

    /**
     * @dev Withdraw Ether
     *
     * Can only be called by the current owner.
     */
    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Withdraw: recipient is the zero address");

        uint256 balance = address(this).balance;

        require(balance >= amount, "Withdraw: amount exceeds balance");
        recipient.transfer(amount);
    }
}


/**
 * @title Voken Shareholders
 */
contract VokenShareholders is Ownable, IAllocation {
    using SafeMath256 for uint256;
    using Roles for Roles.Role;

    IVoken2 private _VOKEN = IVoken2(0xFfFAb974088Bd5bF3d7E6F522e93Dd7861264cDB);
    Roles.Role private _proxies;

    uint256 private _ALLOCATION_TIMESTAMP = 1598918399; // Sun, 30 Aug 2020 23:59:59 +0000
    uint256 private _ALLOCATION_INTERVAL = 1 days;
    uint256 private _ALLOCATION_STEPS = 60;

    uint256 private _page;
    uint256 private _weis;
    uint256 private _vokens;

    address[] private _shareholders;
    mapping (address => bool) private _isShareholder;

    mapping (address => uint256) private _withdrawPos;
    mapping (uint256 => address[]) private _pageShareholders;
    mapping (uint256 => mapping (address => bool)) private _isPageShareholder;

    mapping (uint256 => uint256) private _pageEndingBlock;
    mapping (uint256 => uint256) private _pageEthers;
    mapping (uint256 => uint256) private _pageVokens;
    mapping (uint256 => uint256) private _pageVokenSum;
    mapping (uint256 => mapping (address => uint256)) private _pageVokenHoldings;
    mapping (uint256 => mapping (address => uint256)) private _pageEtherDividends;

    mapping (address => uint256) private _allocations;

    event ProxyAdded(address indexed account);
    event ProxyRemoved(address indexed account);
    event Dividend(address indexed account, uint256 amount, uint256 page);


    /**
     * @dev Throws if called by account which is not a proxy.
     */
    modifier onlyProxy() {
        require(isProxy(msg.sender), "ProxyRole: caller does not have the Proxy role");
        _;
    }

    /**
     * @dev Returns true if the `account` has the Proxy role.
     */
    function isProxy(address account) public view returns (bool) {
        return _proxies.has(account);
    }

    /**
     * @dev Give an `account` access to the Proxy role.
     *
     * Can only be called by the current owner.
     */
    function addProxy(address account) public onlyOwner {
        _proxies.add(account);
        emit ProxyAdded(account);
    }

    /**
     * @dev Remove an `account` access from the Proxy role.
     *
     * Can only be called by the current owner.
     */
    function removeProxy(address account) public onlyOwner {
        _proxies.remove(account);
        emit ProxyRemoved(account);
    }

    /**
     * @dev Returns the VOKEN main contract address.
     */
    function VOKEN() public view returns (IVoken2) {
        return _VOKEN;
    }

    /**
     * @dev Returns the max page number.
     */
    function page() public view returns (uint256) {
        return _page;
    }

    /**
     * @dev Returns the amount of deposited Ether.
     */
    function weis() public view returns (uint256) {
        return _weis;
    }

    /**
     * @dev Returns the amount of VOKEN holding by all shareholders.
     */
    function vokens() public view returns (uint256) {
        return _vokens;
    }

    /**
     * @dev Returns the shareholders list on `pageNumber`.
     */
    function shareholders(uint256 pageNumber) public view returns (address[] memory) {
        if (pageNumber > 0) {
            return _pageShareholders[pageNumber];
        }

        return _shareholders;
    }

    /**
     * @dev Returns the shareholders counter on `pageNumber`.
     */
    function shareholdersCounter(uint256 pageNumber) public view returns (uint256) {
        if (pageNumber > 0) {
            return _pageShareholders[pageNumber].length;
        }

        return _shareholders.length;
    }

    /**
     * @dev Returns the amount of deposited Ether at `pageNumber`.
     */
    function pageEther(uint256 pageNumber) public view returns (uint256) {
        return _pageEthers[pageNumber];
    }

    /**
     * @dev Returns the amount of deposited Ether till `pageNumber`.
     */
    function pageEtherSum(uint256 pageNumber) public view returns (uint256) {
        uint256 __page = _pageNumber(pageNumber);
        uint256 __amount;

        for (uint256 i = 1; i <= __page; i++) {
            __amount = __amount.add(_pageEthers[i]);
        }

        return __amount;
    }

    /**
     * @dev Returns the amount of VOKEN holding by all shareholders at `pageNumber`.
     */
    function pageVoken(uint256 pageNumber) public view returns (uint256) {
        return _pageVokens[pageNumber];
    }

    /**
     * @dev Returns the amount of VOKEN holding by all shareholders till `pageNumber`.
     */
    function pageVokenSum(uint256 pageNumber) public view returns (uint256) {
        return _pageVokenSum[_pageNumber(pageNumber)];
    }

    /**
     * Returns the ending block number of `pageNumber`.
     */
    function pageEndingBlock(uint256 pageNumber) public view returns (uint256) {
        return _pageEndingBlock[pageNumber];
    }

    /**
     * Returns the page number greater than 0 by `pageNmber`.
     */
    function _pageNumber(uint256 pageNumber) internal view returns (uint256) {
        if (pageNumber > 0) {
            return pageNumber;
        }

        else {
            return _page;
        }
    }

    /**
     * @dev Returns the amount of VOKEN holding by `account` and `pageNumber`.
     */
    function vokenHolding(address account, uint256 pageNumber) public view returns (uint256) {
        uint256 __page;
        uint256 __amount;

        if (pageNumber > 0) {
            __page = pageNumber;
        }

        else {
            __page = _page;
        }

        for (uint256 i = 1; i <= __page; i++) {
            __amount = __amount.add(_pageVokenHoldings[i][account]);
        }

        return __amount;
    }

    /**
     * @dev Returns the ether dividend of `account` on `pageNumber`.
     */
    function etherDividend(address account, uint256 pageNumber) public view returns (uint256 amount,
                                                                                     uint256 dividend,
                                                                                     uint256 remain) {
        if (pageNumber > 0) {
            amount = pageEther(pageNumber).mul(vokenHolding(account, pageNumber)).div(pageVokenSum(pageNumber));
            dividend = _pageEtherDividends[pageNumber][account];
        }

        else {
            for (uint256 i = 1; i <= _page; i++) {
                uint256 __pageEtherDividend = pageEther(i).mul(vokenHolding(account, i)).div(pageVokenSum(i));
                amount = amount.add(__pageEtherDividend);
                dividend = dividend.add(_pageEtherDividends[i][account]);
            }
        }

        remain = amount.sub(dividend);
    }

    /**
     * @dev Returns the allocation of `account`.
     */
    function allocation(address account) public view returns (uint256) {
        return _allocations[account];
    }

    /**
     * @dev Returns the reserved amount of VOKENs by `account`.
     */
    function reservedOf(address account) public view returns (uint256 reserved) {
        reserved = _allocations[account];

        if (now > _ALLOCATION_TIMESTAMP && reserved > 0) {
            uint256 __passed = now.sub(_ALLOCATION_TIMESTAMP).div(_ALLOCATION_INTERVAL).add(1);

            if (__passed > _ALLOCATION_STEPS) {
                reserved = 0;
            }
            else {
                reserved = reserved.sub(reserved.mul(__passed).div(_ALLOCATION_STEPS));
            }
        }
    }


    /**
     * @dev Constructor
     */
    constructor () public {
        _page = 1;

        addProxy(msg.sender);
    }

    /**
     * @dev {Deposit} or {Withdraw}
     */
    function () external payable {
        // deposit
        if (msg.value > 0) {
            _weis = _weis.add(msg.value);
            _pageEthers[_page] = _pageEthers[_page].add(msg.value);
        }

        // withdraw
        else if (_isShareholder[msg.sender]) {
            uint256 __vokenHolding;

            for (uint256 i = 1; i <= _page.sub(1); i++) {
                __vokenHolding = __vokenHolding.add(_pageVokenHoldings[i][msg.sender]);

                if (_withdrawPos[msg.sender] < i) {
                    uint256 __etherAmount = _pageEthers[i].mul(__vokenHolding).div(_pageVokenSum[i]);

                    _withdrawPos[msg.sender] = i;
                    _pageEtherDividends[i][msg.sender] = __etherAmount;

                    msg.sender.transfer(__etherAmount);
                    emit Dividend(msg.sender, __etherAmount, i);
                }
            }
        }

        assert(true);
    }

    /**
     * @dev End the current page.
     */
    function endPage() public onlyProxy {
        require(_pageEthers[_page] > 0, "Ethers on current page is zero.");

        _pageEndingBlock[_page] = block.number;

        _page = _page.add(1);
        _pageVokenSum[_page] = _vokens;

        assert(true);
    }

    /**
     * @dev Push shareholders.
     *
     * Can only be called by a proxy.
     */
    function pushShareholders(address[] memory accounts, uint256[] memory values) public onlyProxy {
        require(accounts.length == values.length, "Shareholders: batch length is not match");

        for (uint256 i = 0; i < accounts.length; i++) {
            address __account = accounts[i];
            uint256 __value = values[i];

            if (!_isShareholder[__account]) {
                _shareholders.push(__account);
                _isShareholder[__account] = true;
            }

            if (!_isPageShareholder[_page][__account]) {
                _pageShareholders[_page].push(__account);
                _isPageShareholder[_page][__account] = true;
            }

            _vokens = _vokens.add(__value);
            _pageVokens[_page] = _pageVokens[_page].add(__value);
            _pageVokenSum[_page] = _vokens;
            _pageVokenHoldings[_page][__account] = _pageVokenHoldings[_page][__account].add(__value);

            _allocations[__account] = _allocations[__account].add(__value);
            assert(_VOKEN.mintWithAllocation(__account, __value, address(this)));
        }

        assert(true);
    }
}