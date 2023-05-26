/**
 *Submitted for verification at Etherscan.io on 2019-12-13
*/

pragma solidity ^0.5.0;


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

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

contract Pausable is PauserRole {
    
    event Paused(address account);

    
    event Unpaused(address account);

    bool private _paused;

    
    constructor () internal {
        _paused = false;
    }

    
    function paused() public view returns (bool) {
        return _paused;
    }

    
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

contract UnirisToken is ERC20Pausable, ERC20Detailed {

  
  uint256 public constant funding_pool_supply = 3820000000000000000000000000;

  
  uint256 public constant deliverable_supply = 2360000000000000000000000000;

  
  uint256 public constant network_pool_supply = 1460000000000000000000000000;

  
  uint256 public constant enhancement_supply = 900000000000000000000000000;

  
  uint256 public constant team_supply = 560000000000000000000000000;

  
  uint256 public constant exch_pool_supply = 340000000000000000000000000;

  
  uint256 public constant marketing_supply = 340000000000000000000000000;

  
  uint256 public constant foundation_supply = 220000000000000000000000000;

  address public funding_pool_beneficiary;
  address public deliverables_beneficiary;
  address public network_pool_beneficiary;
  address public enhancement_beneficiary;
  address public team_beneficiary;
  address public exch_pool_beneficiary;
  address public marketing_beneficiary;
  address public foundation_beneficiary;

  modifier onlyUnlocked(address from, uint256 value) {
    
    
    require(from != enhancement_beneficiary, "Enhancement wallet is locked forever until mainnet");

    
    
    
    
    if (from == deliverables_beneficiary) {
      uint256 _delivered = deliverable_supply - balanceOf(deliverables_beneficiary);
      require(_delivered.add(value) <= deliverable_supply.mul(10).div(100), "Only 10% of the deliverable supply is unlocked before mainnet");
    }
    else if (from == network_pool_beneficiary) {
      uint256 _delivered = network_pool_supply - balanceOf(network_pool_beneficiary);
      require(_delivered.add(value) <= network_pool_supply.mul(10).div(100), "Only 10% of the network supply is unlocked before mainnet");
    }
    _;
  }

  constructor(
    address _funding_pool_beneficiary,
    address _deliverables_beneficiary,
    address _network_pool_beneficiary,
    address _enhancement_beneficiary,
    address _team_beneficiary,
    address _exch_pool_beneficiary,
    address _marketing_beneficiary,
    address _foundation_beneficiary
    ) public ERC20Detailed("UnirisToken", "UCO", 18) {

    require(_funding_pool_beneficiary != address(0), "Invalid funding pool beneficiary address");
    require(_deliverables_beneficiary != address(0), "Invalid deliverables beneficiary address");
    require(_network_pool_beneficiary != address(0), "Invalid network pool beneficiary address");
    require(_enhancement_beneficiary != address(0), "Invalid enhancement beneficiary address");
    require(_team_beneficiary != address(0), "Invalid team beneficiary address");
    require(_exch_pool_beneficiary != address(0), "Invalid exch pool beneficiary address");
    require(_marketing_beneficiary != address(0), "Invalid marketing beneficiary address");
    require(_foundation_beneficiary != address(0), "Invalid foundation beneficiary address");

    funding_pool_beneficiary = _funding_pool_beneficiary;
    deliverables_beneficiary = _deliverables_beneficiary;
    network_pool_beneficiary = _network_pool_beneficiary;
    enhancement_beneficiary = _enhancement_beneficiary;
    team_beneficiary = _team_beneficiary;
    exch_pool_beneficiary = _exch_pool_beneficiary;
    marketing_beneficiary = _marketing_beneficiary;
    foundation_beneficiary = _foundation_beneficiary;

    _mint(funding_pool_beneficiary, funding_pool_supply);
    _mint(deliverables_beneficiary, deliverable_supply);
    _mint(network_pool_beneficiary, network_pool_supply);
    _mint(enhancement_beneficiary, enhancement_supply);
    _mint(team_beneficiary, team_supply);
    _mint(exch_pool_beneficiary, exch_pool_supply);
    _mint(marketing_beneficiary, marketing_supply);
    _mint(foundation_beneficiary, foundation_supply);
  }

  function transfer(address _to, uint256 _value) public onlyUnlocked(msg.sender, _value) returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public onlyUnlocked(_from, _value) returns (bool success) {
    return super.transferFrom(_from, _to, _value);
  }
}