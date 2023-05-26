//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ERC20Interface.sol";
import "./Ownable.sol";

// import "./Treasurer.sol";

contract RightnerToken is ERC20Interface, Ownable, SafeMath {
    string private _symbol;
    string private _name;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 private _preSalePricePerUnit;

    //increase whenever preBuy and decrease while ending preSale
    // uint256 private preBoughtUnits;

    bool private _preSalePeriod;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _whiteListedUsers;
    uint256 private _whiteListCount;

    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_,
        uint256 preSalePricePerUnit_
    ) {
        owner = owner_;
        _symbol = symbol_;
        _name = name_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * 10**_decimals;
        _balances[owner_] = _totalSupply;
        _preSalePeriod = true;

        _preSalePricePerUnit = preSalePricePerUnit_;

        emit Transfer(address(0), owner_, _totalSupply);
    }

    function preSalePeriod() public view virtual returns (bool) {
        return _preSalePeriod;
    }

    function preSalePricePerUnit() public view virtual returns (uint256) {
        return _preSalePricePerUnit;
    }

    function updatePreSalePricePerUnit(uint256 price) public onlyOwner {
        _preSalePricePerUnit = price;
    }

    function whiteListedUsers(address _addr) public view returns (bool) {
        return _whiteListedUsers[_addr];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function balanceOf(address _account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[_account];
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool success)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 tokens)
        public
        override
        returns (bool success)
    {
        _allowances[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool success) {
        _allowances[from][msg.sender] = safeSub(
            _allowances[from][msg.sender],
            amount
        );
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual {
        require(_from != address(0), "cannot transfer from the zero address");
        require(_to != address(0), "cannot transfer to the zero address");
        require(_balances[_from] >= _amount, "Token not enough");

        _balances[_from] = safeSub(_balances[_from], _amount);
        _balances[_to] = safeAdd(_balances[_to], _amount);

        emit Transfer(_from, _to, _amount);
    }

    function addWhiteListUser(address _user) public onlyOwner preSaleOnly {
        _whiteListedUsers[_user] = true;
    }

    function addWhiteListUsers(address[] memory _users)
        public
        onlyOwner
        preSaleOnly
    {
        for (uint256 i = 0; i < _users.length; i++) {
            _whiteListedUsers[_users[i]] = true;
        }
    }

    function preBuy(uint256 tokens) public payable preSaleOnly {
        require(_whiteListedUsers[msg.sender], "You're not whitelisted");
        //check for price
        require(
            msg.value >= (tokens * _preSalePricePerUnit) / (10**_decimals),
            "Not enough ether sent"
        );
        _transfer(owner, msg.sender, tokens);
    }

    function closePreSales() public onlyOwner preSaleOnly {
        _preSalePeriod = false;

        //transfer collected ether to owner account
        payable(msg.sender).transfer(address(this).balance);
    }

    modifier preSaleOnly() {
        require(_preSalePeriod, "PreSale Ended");
        _;
    }
}