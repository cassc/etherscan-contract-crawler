/**
 *Submitted for verification at Etherscan.io on 2020-11-18
*/

// SPDX-License-Identifier: None
pragma solidity >=0.4.22 <0.8.0;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    
    constructor (string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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

    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

library EnumerableSet {
    
    
    
    
    
    
    
    

    struct Set {
        
        bytes32[] _values;

        
        
        mapping (bytes32 => uint256) _indexes;
    }

    
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            
            
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { 
            
            
            

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            
            

            bytes32 lastvalue = set._values[lastIndex];

            
            set._values[toDeleteIndex] = lastvalue;
            
            set._indexes[lastvalue] = toDeleteIndex + 1; 

            
            set._values.pop();

            
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    

    struct AddressSet {
        Set _inner;
    }

    
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    

    struct UintSet {
        Set _inner;
    }

    
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

abstract contract ITokenRecipient {
  
  function tokenFallback(address _from, uint256 _value, bytes memory _data) public virtual returns (bool);
}

interface ICommittee {

  function committee(uint256 _idx) external view returns (address);

}

contract DCAREToken is ERC20, AccessControl, Ownable {
  using SafeMath for uint256;

  address public INITIAL_FC_VOTING_CONTRACT_ADDRESS;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 public constant MAXIMUM_SUPPLY = 3500000;

  uint256[7] public INITIAL_SUPPLY = [105000, 50000, 35000, 25000, 10000, 10000, 10000];

  address[] public admins;
  address[] public minters;

  constructor(address fcVotingContractAddress) ERC20("DCARE Token", "DCARE") {
    INITIAL_FC_VOTING_CONTRACT_ADDRESS = fcVotingContractAddress;

    _setupDecimals(6);

    _setupRole(DEFAULT_ADMIN_ROLE, INITIAL_FC_VOTING_CONTRACT_ADDRESS);
    admins.push(INITIAL_FC_VOTING_CONTRACT_ADDRESS);

    _mintInitialSupply();
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an Admin");
    _;
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a Minter");
    _;
  }

  function grantAdminRole(address _adminAddress) public onlyAdmin {
    _setupRole(DEFAULT_ADMIN_ROLE, _adminAddress);

    admins.push(_adminAddress);
  }

  function revokeAdminRole(address _adminAddress) public onlyAdmin {
    revokeRole(DEFAULT_ADMIN_ROLE, _adminAddress);

    for (uint256 i = 0; i < admins.length; i++) {
      if (i >= admins.length) {
        break;
      }

      if (admins[i] == _adminAddress) {
        if (i != admins.length - 1) {
          admins[i] = admins[admins.length - 1];
        }
        admins.pop();
      }
    }
  }

  function grantMinterRole(address _minterAddress) public onlyAdmin {
    _setupRole(MINTER_ROLE, _minterAddress);

    minters.push(_minterAddress);
  }

  function revokeMinterRole(address _minterAddress) public onlyAdmin {
    revokeRole(MINTER_ROLE, _minterAddress);

    for (uint256 i = 0; i < minters.length; i++) {
      if (i >= minters.length) {
        break;
      }

      if (minters[i] == _minterAddress) {
        if (i != minters.length - 1) {
          minters[i] = minters[minters.length - 1];
        }
        minters.pop();
      }
    }
  }

  function mint(address _receiver, uint256 _amount) public onlyMinter {
    require(
      totalSupply().add(_amount) <= MAXIMUM_SUPPLY.mul(10 ** decimals()),
      "The limit of the maximum allowable emission of tokens has been exceeded"
    );

    _mint(_receiver, _amount);
  }

  function _mintInitialSupply() private {
    ICommittee committeeContract = ICommittee(INITIAL_FC_VOTING_CONTRACT_ADDRESS);

    address committee;
    for (uint8 i = 0; i < 7; i++) {
      committee = committeeContract.committee(i);
      _mint(committee, INITIAL_SUPPLY[i].mul(10 ** decimals()));
    }
  }

  
  function transfer(address _to, uint256 _value, bytes memory _data) public returns (bool success) {
    _transfer(_msgSender(), _to, _value);
    if (Address.isContract(_to)) {
      ITokenRecipient receiver = ITokenRecipient(_to);
      bool result = receiver.tokenFallback(_msgSender(), _value, _data);
      if (!result) {
        revert("The recipient contract has no fallback function to receive tokens properly");
      }
    }

    return true;
  }

  
  function transfer(address _to, uint256 _value) public override returns (bool success) {
    _transfer(_msgSender(), _to, _value);
    if (Address.isContract(_to)) {
      ITokenRecipient receiver = ITokenRecipient(_to);
      bool result = receiver.tokenFallback(
        _msgSender(), _value, hex"00");
      if (!result) {
        revert("The recipient contract has no fallback function to receive tokens properly");
      }
    }

    return true;
  }

  function adminsNumber() public view returns (uint256) {
    return admins.length;
  }

  function mintersNumber() public view returns (uint256) {
    return minters.length;
  }

}

interface ITerminable {

  function terminate() external;

}

struct Stake {
  uint256 stakingTime; 
  uint256 stakedUntilTime; 
  uint256 amount;
}

contract DCAREMining is Ownable, ITerminable {
  using SafeMath for uint256;

  address public constant SOLVE_TOKEN_CONTRACT_ADDRESS = address(0x446C9033E7516D820cc9a2ce2d0B7328b579406F); 
  uint256 public constant SOLVE_TOKEN_DECIMALS = 8;

  address public constant DCARE_TOKEN_CONTRACT_ADDRESS = address(0x29C7653F1bdb29C5f2cD44DAAA1d3FAd18475B5D); 
  uint256 public constant DCARE_TOKEN_DECIMALS = 6;

  address public constant COMMITTEE_CONTRACT_ADDRESS = address(0x972A5AFcAaBa9352E6DCCDc8Da872c987f1d13aF); 

  uint256 public constant PROMOTIONAL_MINING_RATE = 75; 
  uint256 public constant NORMAL_MINING_RATE = 100; 

  uint256 public constant PROMOTION_PERIOD = 9 days;
  uint256 public constant STAKING_PERIOD = 365 days;
  uint256 public constant TERMINATION_TIME = 1640908800; 
  uint256 public deploymentTime;

  mapping (address => Stake[]) public stakes;

  bool public terminated;

  IERC20 SOLVEToken;
  DCAREToken token;

  event Staked(address indexed _address, uint256 indexed _amount);
  event Unstaked(address indexed _address, uint256 indexed _amount);
  event Terminate();

  constructor() {
    SOLVEToken = IERC20(SOLVE_TOKEN_CONTRACT_ADDRESS);
    token = DCAREToken(DCARE_TOKEN_CONTRACT_ADDRESS);

    deploymentTime = block.timestamp;
  }

  modifier onlyCommittee() {
    require(COMMITTEE_CONTRACT_ADDRESS == _msgSender(), "Caller is not the DCARE Committee contract");
    _;
  }

  function stake(uint256 _amount) public {
    require(!terminated, "Contract is terminated by voting");
    require(block.timestamp < TERMINATION_TIME, "Contract is terminated due to expiration");
    require(_amount % miningRate() == 0, "Invalid stake amount"); 

    if (SOLVEToken.transferFrom(msg.sender, address(this), _amount.mul(10 ** SOLVE_TOKEN_DECIMALS))) { 
      token.mint(msg.sender, _amount.mul(10 ** DCARE_TOKEN_DECIMALS).div(miningRate()));

      stakes[msg.sender].push(Stake({
        stakingTime: block.timestamp,
        stakedUntilTime: block.timestamp.add(STAKING_PERIOD),
        amount: _amount
      }));

      emit Staked(msg.sender, _amount);
    }
  }

  function unstake() public { 
    Stake[] storage memberStakes = stakes[msg.sender];

    uint256 tokensAmount = 0;
    for (uint8 i = 0; i < memberStakes.length; i++) {
      if (block.timestamp > memberStakes[i].stakedUntilTime && memberStakes[i].amount > 0) {
        tokensAmount = tokensAmount.add(memberStakes[i].amount);

        memberStakes[i].amount = 0;
      }
    }

    if (tokensAmount > 0) {
      SOLVEToken.transfer(msg.sender, tokensAmount.mul(10 ** SOLVE_TOKEN_DECIMALS));

      emit Unstaked(msg.sender, tokensAmount);
    }
  }

  function terminate() public override onlyCommittee {
    terminated = true;

    emit Terminate();
  }

  function miningRate() public view returns (uint256) {
    if (block.timestamp < deploymentTime.add(PROMOTION_PERIOD)) {
      return PROMOTIONAL_MINING_RATE;
    }

    return NORMAL_MINING_RATE;
  }

  function retrieveTokens(address _tokenContractAddress, uint256 _amount) public onlyOwner {
    require(_tokenContractAddress != SOLVE_TOKEN_CONTRACT_ADDRESS, "You can't withdraw SOLVE tokens");

    IERC20 tokenContract = IERC20(_tokenContractAddress);
    tokenContract.transfer(msg.sender, _amount);
  }

  receive() external payable {
    msg.sender.transfer(msg.value);
  }

  function retrieveEther() public onlyOwner {
    if (address(this).balance > 0) {
      msg.sender.transfer(address(this).balance);
    }
  }

}