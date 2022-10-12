// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract LUAToken is Context, IERC20, IERC20Metadata, AccessControl {
    using SafeMath for uint256;
    using Address for address;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SET_ENV_ROLE = keccak256("SET_ENV_ROLE");
    bytes32 public constant SETTLEMENT_ROLE = keccak256("SETTLEMENT_ROLE");
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    uint256 public rate = 1e6;
    uint256 public txMaxAmount = 99e4;
    uint256 private buyFee = 1e4;
    uint256 private sellFee = 3e4;
    uint256 private burnReward = 2e4;
    //    uint256 private oneDay = 1 days;
    uint256 private oneDay = 10 minutes;
    uint256 private perSettle;

    address public liquidityAddress;

    address public USDT_ADDRESS;
    uint256[8] public rewardRates = [3e5, 5e4, 1e5, 15e4, 2e5, 1e5, 1e5, 1e5];
    mapping(address => bool) public pairMap;

    struct burnOrderInfo {
        address account;
        uint256 amount;
        uint256 startTime;
        bool end;
    }

    burnOrderInfo[] public burnOrderList;
    mapping(address => uint256[]) public _burnRewardOrders;

    mapping(address => uint256) public _recommenderNumber;
    mapping(address => address) public recommender;
    mapping(address => bool) private _isExcludedFromFee;

    constructor (address router, address usdt) {
        _name = "LUA";
        _symbol = "LUA";

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SET_ENV_ROLE, msg.sender);

        _grantRole(DEFAULT_ADMIN_ROLE, 0x6d19b5679e65297EF60F2F220aCDbB892Cd073DF);
        _grantRole(MINTER_ROLE, 0x6d19b5679e65297EF60F2F220aCDbB892Cd073DF);
        _grantRole(SETTLEMENT_ROLE, 0x5cF18Ba96b4ae0e60760F8dD3928353003221796);
        _grantRole(SET_ENV_ROLE, 0x6d19b5679e65297EF60F2F220aCDbB892Cd073DF);

        _mint(0xce2400087eeF83265B8046D2595F234FcefD80eD, 1e14);

        liquidityAddress = 0xce2400087eeF83265B8046D2595F234FcefD80eD;
        perSettle = 100;

        USDT_ADDRESS = usdt;

        _isExcludedFromFee[0xce2400087eeF83265B8046D2595F234FcefD80eD] = true;
        _isExcludedFromFee[0x2676e2d89A4d9C863578B5D86000ADf856ED7A70] = true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return 9;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
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

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
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

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function settlementReward() public onlyRole(SETTLEMENT_ROLE) {
        uint256 number = 0;
        for (uint256 i = 0; i < burnOrderList.length; i++) {
            if (burnOrderList[i].end) {
                continue;
            }
            if (block.timestamp > burnOrderList[i].startTime.add(oneDay) && !burnOrderList[i].end) {
                uint256 reward = burnOrderList[i].amount.mul(burnReward).div(rate);
                _newMint(burnOrderList[i].account, burnOrderList[i].amount.add(reward));

                address cacheAccount = recommender[burnOrderList[i].account];
                uint256 newReward = 0;

                for (uint256 j = 0; j < rewardRates.length; j++) {
                    if (cacheAccount == address(0)) {
                        break;
                    } else {
                        uint256 cacheAmount = getAccountCurrentMaxAmount(cacheAccount);
                        if (_recommenderNumber[cacheAccount] > j && cacheAmount > 0) {
                            if (burnOrderList[i].amount > cacheAmount) {
                                newReward = cacheAmount.mul(burnReward).div(rate);
                            } else {
                                newReward = reward;
                            }
                            if (newReward > 0) {
                                _newMint(cacheAccount, newReward.mul(rewardRates[j]).div(rate));
                            }
                        }
                        cacheAccount = recommender[cacheAccount];
                    }
                }
                burnOrderList[i].end = true;
                number++;
            }
            if (number == perSettle) {
                break;
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");

        uint256 fromBalance = _balances[from];
        uint256 onlyBalance = fromBalance.mul(txMaxAmount).div(rate);
        if (_isExcludedFromFee[from]) {
            onlyBalance = _balances[from];
        }
        require(onlyBalance >= amount, "ERC20: transfer amount exceeds balance");

        if (to == DEAD_ADDRESS) {
            burnOrderInfo memory newOrder = burnOrderInfo(from, amount, block.timestamp, false);
            burnOrderList.push(newOrder);
            _burnRewardOrders[from].push(burnOrderList.length - 1);
            _newBurn(from, amount);
            return;
        }

    unchecked {
        _balances[from] = fromBalance - amount;
    }
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            if (
                recommender[to] == address(0) &&
                recommender[from] != to &&
                !from.isContract() &&
                !to.isContract() &&
                to != DEAD_ADDRESS &&
                to != address(0)
            ) {
                recommender[to] = from;
                _recommenderNumber[from]++;
            }
        }

        uint256 fee = 0;
        if (pairMap[from]) {
            if (!_isExcludedFromFee[to]) {
                fee = amount.mul(buyFee).div(rate);
            }
            if (fee > 0) {
                _balances[liquidityAddress] = _balances[liquidityAddress].add(fee);
                emit Transfer(from, liquidityAddress, fee);
            }
        }

        if (pairMap[to]) {
            if (!_isExcludedFromFee[from]) {
                fee = amount.mul(sellFee).div(rate);
            }
            if (fee > 0) {
                _balances[liquidityAddress] = _balances[liquidityAddress].add(fee);
                emit Transfer(from, liquidityAddress, fee);
            }
        }
        _balances[to] += amount.sub(fee);
        emit Transfer(from, to, amount.sub(fee));
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _newMint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        emit Transfer(address(0), address(this), amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(this), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _newBurn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, DEAD_ADDRESS, amount);
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

    function getAccountCurrentMaxAmount(address account) public view returns (uint256 amount) {
        if (_burnRewardOrders[account].length == 0) {
            return 0;
        }
        uint256 max = 0;
        for (uint256 i = 0; i < _burnRewardOrders[account].length; i++) {
            if (!burnOrderList[_burnRewardOrders[account][i]].end && burnOrderList[_burnRewardOrders[account][i]].amount > max) {
                max = burnOrderList[_burnRewardOrders[account][i]].amount;
            }
        }
        return max;
    }

    function getBurnRewardOrders() public view returns (burnOrderInfo[] memory infos) {
        return burnOrderList;
    }

    function setLiquidityAddress(address _liquidityAddress) external onlyRole(SET_ENV_ROLE) {
        liquidityAddress = _liquidityAddress;
    }

    function setPerSettle(uint256 _newPerSettle) external onlyRole(SET_ENV_ROLE) {
        perSettle = _newPerSettle;
    }

    function setPair(address pair, bool isFee) external onlyRole(SET_ENV_ROLE) {
        pairMap[pair] = isFee;
    }

    function excludeFromFee(address account) external onlyRole(SET_ENV_ROLE) {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyRole(SET_ENV_ROLE) {
        _isExcludedFromFee[account] = false;
    }

    receive() external payable {}
}