/**
 *Submitted for verification at Etherscan.io on 2019-08-28
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

contract ERC20Burnable is ERC20 {
    
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

interface ISwarmTokenControlled {
    event DocumentUpdated(bytes32 hash, string url);
    event ClaimedTokens(address indexed token, address indexed controller, uint256 amount);
    event ClaimedEther(address indexed controller, uint256 amount);

    function updateDocument(bytes32 hash, string calldata url) external returns (bool);
    function claimTokens(IERC20 token) external returns (bool);
    function claimEther() external returns (bool);
}

interface ISwarmTokenRecipient {
    function receiveApproval(address from, uint256 amount, address token, bytes calldata data) external;
}

contract Controlled {
    address private _controller;

    
    event ControllerTransferred(address recipient);

    
    constructor (address controller) internal {
        _controller = controller;
        emit ControllerTransferred(_controller);
    }

    
    modifier onlyController() {
        require(msg.sender == _controller, "Controlled: caller is not the controller address");
        _;
    }

    
    function controller() public view returns (address) {
        return _controller;
    }

    
    function transferController(address recipient) public onlyController {
        require(recipient != address(0), "Controlled: new controller is the zero address");
        _controller = recipient;
        emit ControllerTransferred(_controller);
    }
}

contract SwarmToken is ISwarmTokenControlled, ERC20Burnable, ERC20Detailed, Controlled {
    struct Document {
        bytes32 hash;
        string url;
    }

    Document private _document;

    constructor(
        address controller,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address initialAccount,
        uint256 totalSupply
    )
        ERC20Detailed(name, symbol, decimals)
        Controlled(controller)
        public
    {
        _mint(initialAccount, totalSupply);
    }

    
    function approveAndCall(address spender, uint256 value, bytes memory extraData) public returns (bool) {
        require(value == 0 || allowance(msg.sender, spender) == 0, 'SwarmToken: not clean allowance state');

        _approve(msg.sender, spender, value);
        ISwarmTokenRecipient(spender).receiveApproval(msg.sender, value, address(this), extraData);
        return true;
    }

    
    function getDocument() external view returns (bytes32, string memory) {
        return (_document.hash, _document.url);
    }

    
    function updateDocument(bytes32 hash, string calldata url) external onlyController returns (bool) {
        return _updateDocument(hash, url);
    }

    
    function claimTokens(IERC20 token) external onlyController returns (bool) {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);

        emit ClaimedTokens(address(token), msg.sender, balance);

        return true;
    }

    
    function claimEther() external onlyController returns (bool) {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);

        emit ClaimedEther(msg.sender, balance);

        return true;
    }

    
    function() external payable {
        require(msg.data.length == 0);
    }

    
    function _updateDocument(bytes32 hash, string memory url) internal returns (bool) {
        _document.hash = hash;
        _document.url = url;

        emit DocumentUpdated(hash, url);

        return true;
    }
}