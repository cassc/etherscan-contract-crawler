//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PLPC is IERC20, Ownable {
    string constant _name = "Pepe Le Pew Coin";
    string constant _symbol = "$PLPC";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 165_165_125_165_230 * (10 ** _decimals);

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isAuthorized;

    bool public isTradeEnabled = false;

    uint256 public burnIntevel = 131400;
    uint256 public burnPercentage = 314;

    address public burnManager = 0xe5ea5e472B76C6542847501d48C02B4D451E1A57;

    uint256 public nextBurnTime;

    event AddAuthorizedWallet(address holder, bool status);

    constructor() {
        address deployer = 0xe5ea5e472B76C6542847501d48C02B4D451E1A57;

        isAuthorized[deployer] = true;
        isAuthorized[address(this)] = true;

        _balances[deployer] = _totalSupply;
        emit Transfer(address(0), deployer, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
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

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(
                _allowances[sender][msg.sender] >= amount,
                "Insufficient Allowance"
            );
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (!isTradeEnabled) require(isAuthorized[sender], "Trading disabled");

        require(_balances[sender] >= amount, "Insufficient Balance");
        _balances[sender] = _balances[sender] - amount;

        _balances[recipient] = _balances[recipient] + amount;

        if (nextBurnTime <= block.timestamp && isTradeEnabled) {
            burnTokens();
        }

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function enableTrading() external onlyOwner {
        require(!isTradeEnabled, "Trading already enabled");
        isTradeEnabled = true;
        nextBurnTime = block.timestamp + burnIntevel;
    }

    function setAuthorizedWallets(
        address _wallet,
        bool _status
    ) external onlyOwner {
        isAuthorized[_wallet] = _status;
    }

    function rescueETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No enough ETH to transfer");

        payable(msg.sender).transfer(balance);
    }

    function burnTokens() public {
        require(block.timestamp >= nextBurnTime, "Not the time to burn");

        uint256 currentBalance = _balances[address(this)];

        if (currentBalance > 0) {
            uint256 tokensToBurn = (currentBalance * burnPercentage) / 10000;

            _balances[address(this)] = _balances[address(this)] - tokensToBurn;

            _balances[address(0)] = _balances[address(0)] + tokensToBurn;

            emit Transfer(address(this), address(0), tokensToBurn);

            nextBurnTime += burnIntevel;
        }
    }

    function changeBurnSettings(
        uint256 _burnIntevel,
        uint256 _percentage
    ) external {
        require(
            msg.sender == burnManager,
            "Only Burn Manager can call this function"
        );

        burnIntevel = _burnIntevel;
        burnPercentage = _percentage;
    }

    function changeBurnManager(address _burnManager) external onlyOwner {
        burnManager = _burnManager;
    }
}