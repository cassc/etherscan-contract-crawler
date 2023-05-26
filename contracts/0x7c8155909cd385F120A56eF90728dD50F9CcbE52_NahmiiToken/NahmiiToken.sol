/**
 *Submitted for verification at Etherscan.io on 2020-02-03
*/

pragma solidity >=0.4.25 <0.6.0;
pragma experimental ABIEncoderV2;


contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
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

contract ERC20 is Context, IERC20 {
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
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
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

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract ERC20Mintable is ERC20, MinterRole {
    
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

library Math {
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

interface BalanceRecordable {
    
    function balanceRecordsCount(address account)
    external
    view
    returns (uint256);

    
    function recordBalance(address account, uint256 index)
    external
    view
    returns (uint256);

    
    function recordBlockNumber(address account, uint256 index)
    external
    view
    returns (uint256);

    
    function recordIndexByBlockNumber(address account, uint256 blockNumber)
    external
    view
    returns (int256);
}

contract TokenUpgradeAgent {

    
    address public origin;

    constructor(address _origin)
    public
    {
        origin = _origin;
    }

    
    
    
    function upgradeFrom(address from, uint256 value)
    public
    returns (bool);

    
    
    
    modifier onlyOrigin() {
        require(msg.sender == origin);
        _;
    }
}

contract RevenueToken is ERC20Mintable, BalanceRecordable {
    using SafeMath for uint256;
    using Math for uint256;

    struct BalanceRecord {
        uint256 blockNumber;
        uint256 balance;
    }

    mapping(address => BalanceRecord[]) public balanceRecords;

    bool public mintingDisabled;

    event DisableMinting();
    event Upgrade(TokenUpgradeAgent tokenUpgradeAgent, address from, uint256 value);
    event UpgradeFrom(TokenUpgradeAgent tokenUpgradeAgent, address upgrader, address from, uint256 value);
    event UpgradeBalanceRecords(address account, uint256 startIndex, uint256 endIndex);

    
    function disableMinting()
    public
    onlyMinter
    {
        
        mintingDisabled = true;

        
        emit DisableMinting();
    }

    
    function mint(address to, uint256 value)
    public
    onlyMinter
    returns (bool)
    {
        
        require(!mintingDisabled, "Minting disabled [RevenueToken.sol:68]");

        
        bool minted = super.mint(to, value);

        
        if (minted)
            _addBalanceRecord(to);

        
        return minted;
    }

    
    function transfer(address to, uint256 value)
    public
    returns (bool)
    {
        
        bool transferred = super.transfer(to, value);

        
        if (transferred) {
            _addBalanceRecord(msg.sender);
            _addBalanceRecord(to);
        }

        
        return transferred;
    }

    
    function approve(address spender, uint256 value)
    public
    returns (bool)
    {
        
        require(
            0 == value || 0 == allowance(msg.sender, spender),
            "Value or allowance non-zero [RevenueToken.sol:117]"
        );

        
        return super.approve(spender, value);
    }

    
    function transferFrom(address from, address to, uint256 value)
    public
    returns (bool)
    {
        
        bool transferred = super.transferFrom(from, to, value);

        
        if (transferred) {
            _addBalanceRecord(from);
            _addBalanceRecord(to);
        }

        
        return transferred;
    }

    
    function upgrade(TokenUpgradeAgent tokenUpgradeAgent, uint256 value)
    public
    returns (bool)
    {
        
        _burn(msg.sender, value);

        
        bool upgraded = tokenUpgradeAgent.upgradeFrom(msg.sender, value);

        
        require(upgraded, "Upgrade failed [RevenueToken.sol:168]");

        
        emit Upgrade(tokenUpgradeAgent, msg.sender, value);

        
        return upgraded;
    }

    
    function upgradeFrom(TokenUpgradeAgent tokenUpgradeAgent, address from, uint256 value)
    public
    returns (bool)
    {
        
        _burnFrom(from, value);

        
        bool upgraded = tokenUpgradeAgent.upgradeFrom(from, value);

        
        require(upgraded, "Upgrade failed [RevenueToken.sol:195]");

        
        emit UpgradeFrom(tokenUpgradeAgent, msg.sender, from, value);

        
        return upgraded;
    }

    
    function balanceRecordsCount(address account)
    public
    view
    returns (uint256)
    {
        return balanceRecords[account].length;
    }

    
    function recordBalance(address account, uint256 index)
    public
    view
    returns (uint256)
    {
        return balanceRecords[account][index].balance;
    }

    
    function recordBlockNumber(address account, uint256 index)
    public
    view
    returns (uint256)
    {
        return balanceRecords[account][index].blockNumber;
    }

    
    function recordIndexByBlockNumber(address account, uint256 blockNumber)
    public
    view
    returns (int256)
    {
        for (uint256 i = balanceRecords[account].length; i > 0;) {
            i = i.sub(1);
            if (balanceRecords[account][i].blockNumber <= blockNumber)
                return int256(i);
        }
        return - 1;
    }

    
    function upgradeBalanceRecords(address account, BalanceRecord[] memory _balanceRecords)
    public
    onlyMinter
    {
        
        if (0 < _balanceRecords.length) {
            
            require(!mintingDisabled, "Minting disabled [RevenueToken.sol:280]");

            
            uint256 startIndex = balanceRecords[account].length;
            uint256 endIndex = startIndex.add(_balanceRecords.length).sub(1);

            
            uint256 previousBlockNumber = startIndex > 0 ? balanceRecords[account][startIndex - 1].blockNumber : 0;

            
            for (uint256 i = 0; i < _balanceRecords.length; i++) {
                
                require(previousBlockNumber <= _balanceRecords[i].blockNumber, "Invalid balance record block number [RevenueToken.sol:292]");

                
                balanceRecords[account].push(_balanceRecords[i]);

                
                previousBlockNumber = _balanceRecords[i].blockNumber;
            }

            
            emit UpgradeBalanceRecords(account, startIndex, endIndex);
        }
    }

    
    function _addBalanceRecord(address account)
    private
    {
        balanceRecords[account].push(BalanceRecord(block.number, balanceOf(account)));
    }
}

contract NahmiiToken is RevenueToken {

    string public name = "Nahmii";

    string public symbol = "NII";

    uint8 public constant decimals = 15;

    event SetName(string name);

    event SetSymbol(string symbol);

    
    function setName(string memory _name)
    public
    onlyMinter
    {
        name = _name;
        emit SetName(name);
    }

    
    function setSymbol(string memory _symbol)
    public
    onlyMinter
    {
        symbol = _symbol;
        emit SetSymbol(_symbol);
    }
}