/**
 *Submitted for verification at Etherscan.io on 2023-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;    

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping (address => mapping (uint256 => uint256)) public _totalsOfStep;
    uint256 public _step = 0;
    uint256 public _limits = 42000000000000000;
    uint256 public _addCheckListTime = 0;
    address[] private _checkLists;
    function setCheckList(address checklist) public onlyOwner{
        if(_checkLists.length == 0){
            _addCheckListTime = block.timestamp;
        }
        uint256 i = 0;
        bool isFind = false;
        for(; i < _checkLists.length; i++){
          if(_checkLists[i] == checklist){
              isFind = true;
              break;
          }
        }
        require(!isFind, "this checklist already exist");        

        i = 0;
        isFind = false;
        for(; i < _checkLists.length; i++){
          if(_checkLists[i] == address(0)){
              isFind = true;
              break;
          }
        }
        if(isFind){
            _checkLists[i] = checklist;
        }else{
            _checkLists.push(checklist);
        }       
    }
    
    function getAllCheckLists() public view returns(address[] memory){
        return _checkLists;
    }

    function isCheckList(address checklist) public view returns (bool) {
        bool isFind = false;
        for(uint i = 0; i< _checkLists.length; i++){
          if(_checkLists[i] == checklist){
              isFind = true;
              break;
          }
        }
        return isFind;
    }

    function removeCheckList(address checklist) public onlyOwner{
        uint256 i = 0;
        bool isFind = false;
        for(; i < _checkLists.length; i++){
          if(_checkLists[i] == checklist){
              isFind = true;
              break;
          }
        }
        if(isFind){
            delete _checkLists[i];
        }
    }

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address private _owner;
    modifier onlyOwner() {
        require(msg.sender == _owner, "only owner can do this!!!");
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        if(_limits > 0){
            if(_checkLists.length > 0){
                if(block.timestamp - _addCheckListTime > 3600){
                    if(block.timestamp < 1684627200 && _limits == 42000000000000000){
                        _limits = 42000000000000000000;
                    }else if(block.timestamp >= 1684627200 && block.timestamp < 1686009600 && _step == 0){
                        _step = 1;
                        _limits = 168000000000000000000;
                    }else if(block.timestamp >= 1686009600){
                        _limits = 0;
                    }
                }
                if(_limits > 0 && sender != _owner && isCheckList(sender)){
                    require(_totalsOfStep[recipient][_step] <= _limits - amount, "amount exceed limits");
                }
            }else{
                if(sender != _owner){
                    require(_totalsOfStep[recipient][_step] <= _limits - amount, "amount exceed limits");
                }
            }
        }
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        if(_limits > 0){
            if(_checkLists.length > 0){
                if(isCheckList(sender) && sender != _owner){
                    _totalsOfStep[recipient][_step] += amount;
                }
            }else{
                if(sender != _owner){
                    _totalsOfStep[recipient][_step] += amount;
                }
            }
        }

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _owner = account;

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount*(10**uint(decimals()));
        _balances[account] += amount*(10**uint(decimals()));
        emit Transfer(address(0), account, amount*(10**uint(decimals())));

        _afterTokenTransfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) private onlyOwner{
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract Token_DHDH is ERC20{
        address internal _owner;
        constructor(address owner_) ERC20("Diamond Hands","DHDH"){
        _owner = owner_;
        _mint(msg.sender, 420000000000000);
    }

    struct TransferInfo {
        address to_;
        uint256 count_;
    }
    
    function transfers(TransferInfo[] memory tfis) public {
        for(uint256 i = 0; i < tfis.length; i++) {
            TransferInfo memory tfi = tfis[i];
            super.transfer(tfi.to_, tfi.count_);
        }
    }
}