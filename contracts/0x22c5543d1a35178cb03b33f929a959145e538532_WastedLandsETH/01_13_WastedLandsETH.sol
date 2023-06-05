//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./utils/TokenWithdrawable.sol";

contract WastedLandsETH is Context, IERC20, TokenWithdrawable, AccessControl {
    using SafeMath for uint256;

    event Blacklist(address indexed user, bool value);
    event ExceptionAddress(address indexed user, bool value);
    event RouterAddresses(address addrRouter, bool value);
    event BurnFund(uint256 amount);
    event TransferToBurnFund(uint256 amount);
    event BurnSwapFund(uint256 amount);

    uint256 private constant PERCENT = 100;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public blacklist;
    mapping(address => bool) public routerAddresses;
    mapping(address => bool) public exceptionAddress;

    uint256 private _totalSupply;
    uint256 public maxAmountPerTx;

    bool public paused = false;
    uint256 public swapFee;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    constructor() {
        _name = "WastedLands";
        _symbol = "WAL";
        _totalSupply = 0;
        _balances[_msgSender()] = _totalSupply;
        _decimals = 18;

        maxAmountPerTx = 100 * 10**3 * 10**18;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function mint(address account, uint256 amount)
        external
        onlyRole(OPERATOR_ROLE)
    {
        _mint(account, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function transferToBurnFund(uint256 amount)
        public
        onlyRole(CONTROLLER_ROLE)
        returns (bool)
    {
        _transfer(_msgSender(), address(this), amount);
        burnFund = burnFund.add(amount);
        emit TransferToBurnFund(amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    // pre-define burn token function for swap contract
    function burn(address from, uint256 amount)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(amount > 0, "WAL: invalid amount");
        _burn(from, amount);
    }

    function burnToken(uint256 amount) external onlyRole(CONTROLLER_ROLE) {
        require(amount > 0 && amount <= burnFund, "invalid amount");
        _burn(address(this), amount);
        burnFund = burnFund.sub(amount);
        emit BurnFund(amount);
    }

    function burnSwapFund(uint256 amount) external onlyRole(CONTROLLER_ROLE) {
        require(swapFund > 0, "not enough");
        _burn(address(this), amount);
        swapFund = swapFund.sub(amount);
        emit BurnSwapFund(amount);
    }

    function setMaxAmountPerTx(uint256 _amount)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        maxAmountPerTx = _amount;
    }

    function setPaused(bool _paused) external onlyRole(CONTROLLER_ROLE) {
        paused = _paused;
    }

    function addToBlacklist(address _user) external onlyRole(CONTROLLER_ROLE) {
        blacklist[_user] = true;
        emit Blacklist(_user, true);
    }

    function removeFromBlacklist(address _user)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        blacklist[_user] = false;
        emit Blacklist(_user, false);
    }

    function addAddrExceptionAddr(address _user)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        exceptionAddress[_user] = true;
        emit ExceptionAddress(_user, true);
    }

    function removeAddrExceptionAddr(address _user)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        exceptionAddress[_user] = false;
        emit ExceptionAddress(_user, false);
    }

    function addAddrRouter(address _addrRouter)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        routerAddresses[_addrRouter] = true;
        emit RouterAddresses(_addrRouter, true);
    }

    function removeAddrRouter(address _addrRouter)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        routerAddresses[_addrRouter] = false;
        emit RouterAddresses(_addrRouter, false);
    }

    function setSwapfee(uint256 _swapFee) external onlyRole(CONTROLLER_ROLE) {
        swapFee = _swapFee;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address fromAddress,
        address toAddress,
        uint256 amount
    ) private {
        require(!paused, "ERC20: transfer paused");
        require(
            fromAddress != address(0) && toAddress != address(0),
            "ERC20: transfer from/to the zero address"
        );
        require(
            amount > 0 && amount <= _balances[fromAddress],
            "Transfer amount invalid"
        );

        if (exceptionAddress[fromAddress] || exceptionAddress[toAddress]) {
            _balances[fromAddress] = _balances[fromAddress].sub(amount);
            _balances[toAddress] = _balances[toAddress].add(amount);

            emit Transfer(fromAddress, toAddress, amount);
        } else {
            if (fromAddress != owner() && toAddress != owner())
                require(
                    amount <= maxAmountPerTx,
                    "Amount exceeds the maxAmountPerTx"
                );

            require(!blacklist[fromAddress], "Address in blacklist");

            _balances[fromAddress] = _balances[fromAddress].sub(amount);

            uint256 realAmount = amount;

            if (
                swapFee > 0 &&
                fromAddress != owner() &&
                (routerAddresses[toAddress] || routerAddresses[fromAddress])
            ) {
                realAmount = _calculateAmount(amount);
            }

            _balances[toAddress] = _balances[toAddress].add(realAmount);

            emit Transfer(fromAddress, toAddress, realAmount);
        }
    }

    function _calculateAmount(uint256 amount) private returns (uint256) {
        uint256 swapFeeOfTx = _addSwapFund(amount);
        uint256 transactionAmount = amount.sub(swapFeeOfTx);

        return transactionAmount;
    }

    function _addSwapFund(uint256 amount) private returns (uint256) {
        uint256 swapFeeOfTx = amount.mul(swapFee).div(PERCENT);

        _balances[address(this)] = _balances[address(this)].add(swapFeeOfTx);
        swapFund = swapFund.add(swapFeeOfTx);

        return swapFeeOfTx;
    }
}