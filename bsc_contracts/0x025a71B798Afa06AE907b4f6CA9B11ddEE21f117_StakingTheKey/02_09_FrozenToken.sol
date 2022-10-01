// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./token/ERC20/IERC20.sol";
import "./token/ERC20/extensions/IERC20Metadata.sol";
import "./token/ERC20/utils/SafeERC20.sol";
import "./utils/Context.sol";
import "./access/Ownable.sol";

contract FrozenToken is Context, IERC20, IERC20Metadata, Ownable {

    address public root;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(uint256 => address) holders;
    mapping(address => uint256) numToHolders;
    uint256 countHolders = 1;

    uint256 _totalSupply;
    uint256 _supply = 8E26;

    string private _name;
    string private _symbol;

    uint256 immutable _months = 30 days;
    //uint256 immutable _months = 60 minutes;

    uint256 immutable _firstYear = 100;
    uint256 immutable _secondYear = 200;
    uint256 immutable _thirdYear = 534;

    uint256 immutable _firstYearPrivateRound = 416;
    uint256 immutable _secondYearPrivateRound = 416;

    bool public _startSales = false;

    struct User{
        uint256 amount;
        uint256 timestamp;
    }

    struct UserPR{
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => User) public frozenAmount;
    mapping(address => UserPR) public frozenAmountPrivateRound;

    mapping(address => bool) public freeOfCommission;

    uint256 public _comission;

    address commissionRecipient;

    modifier onlyLegalCaller() {
        require(msg.sender == owner() || msg.sender == root, "caller is not Legal Caller");
        _;
    }

    modifier isStartSales() {
        require(_startSales, "Sales is not activated");
        _;
    }

    event MintFrozenAmountMigration(address indexed user, uint256 value);
    event MintFrozenAmountPrivateRound(address indexed user, uint256 value);

    constructor(
        string memory name_,
        string memory symbol_,
        address owner
    ) {
        _name = name_;
        _symbol = symbol_;
        _transferOwnership(owner);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function supply() public view returns (uint256) {
        return _supply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function activeSales() public onlyLegalCaller{
        _startSales = !_startSales;
    }

    function setComission(uint256 comission) public onlyLegalCaller {
        _comission = comission;
    }

    function setCommissionRecipient(address user) public onlyLegalCaller {
        commissionRecipient = user;
    }

    function addUserToFreeOfComission(address user) public onlyLegalCaller {
        freeOfCommission[user] = true;
    }

    function setRoot(address _root) public onlyLegalCaller {
        root = _root;
    }

    function mintOwner(address user, uint256 amount) public onlyLegalCaller {
        _mint(user, amount);
    }

    function mint(address user, uint256 amount) public onlyLegalCaller isStartSales {
        _mint(user, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_supply > 0, "The maximum number of minted tokens has been reached");
        require(_supply >= amount, "The amount is greater than the maximum number of minted tokens");
        _beforeTokenTransfer(address(0), account, amount);

        _supply -= amount;
        _totalSupply += amount;
        _balances[account] += amount;
        holders[countHolders] = account;
        numToHolders[account] = countHolders;
        countHolders++;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function getDate(address user, uint8 round) public view returns(uint256 months){
        uint256 newTS;
        if(round == 0){
            newTS = block.timestamp - frozenAmount[user].timestamp;
        }else if(round == 1){
            newTS = block.timestamp - frozenAmountPrivateRound[user].timestamp;
        }
        while(newTS >= _months){
            newTS -= _months;
            months++;
        }
    }

    function getFrozenAmounts() public view returns(uint256 frozen, uint256 unfrozen, uint256 unfrozenAll){
        for(uint256 i; i < countHolders; i++){
            (uint256 f, uint256 u) = getFrozenAmount(holders[i]);
            frozen += f;
            unfrozen += u;
        }
    }

    function getFrozenAmountsPrivateRound() public view returns(uint256 frozen, uint256 unfrozen, uint256 unfrozenAll){
        for(uint256 i; i < countHolders; i++){
            (uint256 f, uint256 u) = getFrozenAmountPrivateRound(holders[i]);
            frozen += f;
            unfrozen += u;
        }
    }

    function getFrozenAmount(address user) public view returns(uint256 frozen, uint256 unfrozen){
        frozen = frozenAmount[user].amount;
        if(frozenAmount[user].timestamp != 0){
            uint256 monthsCount = getDate(user, 0);
            if(monthsCount <= 36){
                if(monthsCount != 0){
                    uint256 nPercents = 0;
                    uint256 i = 1;
                    while(i <= monthsCount){
                        if(i <= 12){
                            nPercents += _firstYear;
                        }else if(i > 12 && i <= 24){
                            nPercents += _secondYear;
                        }else{
                            nPercents += _thirdYear;
                        }
                        i++;
                    }
                    if(frozen >= frozen * nPercents / 10000){
                        frozen -= frozen * nPercents / 10000;
                    }else{
                        frozen = 0;
                    }
                }
            }else{
                frozen = 0;
            }
        }
        unfrozen = frozenAmount[user].amount - frozen;
    }

    function getFrozenAmountPrivateRound(address user) public view returns(uint256 frozen, uint256 unfrozen){
        frozen = frozenAmountPrivateRound[user].amount;
        if(frozenAmountPrivateRound[user].timestamp != 0){
            uint256 monthsCountPrivateRound = getDate(user, 1);
            if(monthsCountPrivateRound <= 24){
                if(monthsCountPrivateRound != 0){
                    uint256 nPercentsPrivateRound = 0;
                    uint256 i = 1;
                    while(i <= monthsCountPrivateRound){
                        if(i <= 12){
                            nPercentsPrivateRound += _firstYearPrivateRound;
                        }else{
                            nPercentsPrivateRound += _secondYearPrivateRound;
                        }
                        i++;
                    }
                    if(frozen >= frozen * nPercentsPrivateRound / 10000){
                        frozen -= frozen * nPercentsPrivateRound / 10000;
                    }else{
                        frozen = 0;
                    }
                }
            }else{
                frozen = 0;
            }
        }
        unfrozen = frozenAmountPrivateRound[user].amount - frozen;
    }

    function migrationFrozenAmountPrivateRoundOld(address[] memory users, uint256[] memory amounts, uint256[] memory timestamps) public onlyLegalCaller {
        for(uint256 i; i < users.length; i++){
            frozenAmountPrivateRound[users[i]] = UserPR(amounts[i], timestamps[i]);
            _mint(users[i], amounts[i]);
        }
    }

    function migrationFrozenAmountOld(address[] memory users, uint256[] memory amounts, uint256[] memory timestamps) public onlyLegalCaller {
        for(uint256 i; i < users.length; i++){
            frozenAmount[users[i]] = User(amounts[i], timestamps[i]);
            _mint(users[i], amounts[i]);
        }
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 fAmount = frozenAmount[from].amount;
        uint256 fAmountPR = frozenAmountPrivateRound[from].amount;

        if(frozenAmount[from].timestamp != 0){
            uint256 monthsCount = getDate(from, 0);
            if(monthsCount <= 36){
                if(monthsCount != 0){
                    uint256 nPercents = 0;
                    uint256 i = 1;
                    while(i <= monthsCount){
                        if(i <= 12){
                            nPercents += _firstYear;
                        }else if(i > 12 && i <= 24){
                            nPercents += _secondYear;
                        }else{
                            nPercents += _thirdYear;
                        }
                        i++;
                    }
                    if(fAmount >= fAmount * nPercents / 10000){
                        fAmount -= fAmount * nPercents / 10000;
                    }else{
                        fAmount = 0;
                    }
                }
            }else{
                fAmount = 0;
                frozenAmount[from] = User(0, 0);
            }
        }
        if(frozenAmountPrivateRound[from].timestamp != 0){
            uint256 monthsCountPrivateRound = getDate(from, 1);
            if(monthsCountPrivateRound <= 24){
                if(monthsCountPrivateRound != 0){
                    uint256 nPercentsPrivateRound = 0;
                    uint256 i = 1;
                    while(i <= monthsCountPrivateRound){
                        if(i <= 12){
                            nPercentsPrivateRound += _firstYearPrivateRound;
                        }else{
                            nPercentsPrivateRound += _secondYearPrivateRound;
                        }
                        i++;
                    }
                    if(fAmountPR >= fAmountPR * nPercentsPrivateRound / 10000){
                        fAmountPR -= fAmountPR * nPercentsPrivateRound / 10000;
                    }else{
                        fAmountPR = 0;
                    }
                }
            }else{
                fAmountPR = 0;
                frozenAmountPrivateRound[from] = UserPR(0, 0);
            }
        }

        require(balanceOf(from) - amount >= fAmount + fAmountPR, "The amount exceeds the allowed amount for withdrawal");
        
        unchecked {
            _balances[from] = fromBalance - amount;
        }

        if(_balances[to] == 0){
            holders[countHolders] = to;
            numToHolders[to] = countHolders;
            countHolders++;
        }

        if(freeOfCommission[from] || freeOfCommission[to]){
            _balances[to] += amount;
        }else{
            if(_comission == 0){
                _balances[to] += amount;
            }else{
                uint256 toBalance = _balances[to];
                uint256 commissionRecipientBalance = _balances[commissionRecipient];
                uint256 c = amount * _comission / 100;
                commissionRecipientBalance += c;
                toBalance += amount - c;
                _balances[commissionRecipient] = commissionRecipientBalance;
                _balances[to] = toBalance;
            }
        }

        if(fromBalance - amount == 0){
            holders[numToHolders[from]] = holders[countHolders-1];
            holders[countHolders-1] = address(0);
            numToHolders[from] == 0;
            countHolders--;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function burn(uint256 amount) public onlyLegalCaller {
        _burn(msg.sender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _supply += amount;
        _totalSupply -= amount;
        if(accountBalance - amount == 0){
            holders[numToHolders[account]] = holders[countHolders-1];
            holders[countHolders-1] = address(0);
            numToHolders[account] == 0;
            countHolders--;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function withdrawLostTokens(IERC20 tokenAddress) public {
        if (tokenAddress != IERC20(address(0))) {
            tokenAddress.transfer(msg.sender, tokenAddress.balanceOf(address(this)));
        }
    }
}