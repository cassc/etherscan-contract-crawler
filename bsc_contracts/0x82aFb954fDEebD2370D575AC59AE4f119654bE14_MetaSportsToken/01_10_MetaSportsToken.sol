// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMetaSportsToken is IERC20 {
    function supplyCap() external view returns (uint256);
    function mint(address account, uint256 amount) external returns (bool);
}

contract MetaSportsToken is AccessControl, Ownable, IMetaSportsToken {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant SUPPLY_CAP = 1 * 10**9 * 10**18;
    uint256 public constant LP_CAP = 5 * 10**7 * 10**18;
    uint256 public constant MAX_BURN_CAP = 9 * 10**8 * 10**18;
    address private burnAddress =
        address(0x000000000000000000000000000000000000dEaD);

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public _uniswapPair;
    uint256 public launchedAt = 0;
    uint256 public burnStartBlock = 0;
    mapping(address => bool) private _blackList;
    mapping(address => bool) private _excluedFeeList;
    bool public swapAndLiquifyEnabled = false;

    constructor() {
        _name = "MetaSportsToken";
        _symbol = "MST";
        _decimals = 18;
        _mint(msg.sender, LP_CAP);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
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

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
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

    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
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
            msg.sender,
            _allowances[sender][msg.sender].sub(amount)
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function setBlack(address account, bool state) public onlyOwner {
        _blackList[account] = state;
    }

    function setExcludeFee(address[] memory accounts, bool state)
        public
        onlyOwner
    {
        for (uint i = 0; i < accounts.length; i++) {
            _excluedFeeList[accounts[i]] = state;
        }
    }

    function openTrading() external onlyOwner {
        launchedAt = block.number;
        swapAndLiquifyEnabled = true;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            !_blackList[sender] && !_blackList[recipient],
            "is bot address "
        );

        if (sender == _uniswapPair || recipient == _uniswapPair) {
            if(!_excluedFeeList[sender] || !_excluedFeeList[recipient]){
                require(swapAndLiquifyEnabled, "swap is enabled");
            }
        }

        if (
            recipient == _uniswapPair &&
            !_excluedFeeList[sender] &&
            balanceOf(burnAddress) < MAX_BURN_CAP
        ) {
            _transferReal(sender, recipient, amount.mul(99).div(100));
            _transferReal(sender, burnAddress, amount.mul(1).div(100));
        } else {
            _transferReal(sender, recipient, amount);
        }
    }

    function _transferReal(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(
            _balances[account] >= value,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, burnAddress, value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function setUniswapPair(address uniswapPair) public onlyOwner {
        _uniswapPair = uniswapPair;
    }

    function mint(address to, uint256 amount)
        public
        override
        onlyRole(MINTER_ROLE)
        returns (bool status)
    {
        if (totalSupply() + amount <= SUPPLY_CAP) {
            _mint(to, amount);
            return true;
        }
        return false;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function supplyCap() external pure override returns (uint256) {
        return SUPPLY_CAP;
    }
}