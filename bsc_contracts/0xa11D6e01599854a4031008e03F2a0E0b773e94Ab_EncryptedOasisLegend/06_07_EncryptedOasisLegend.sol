// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./SwapInterface.sol";

contract EncryptedOasisLegend is Ownable, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "Encrypted Oasis Legend";
    string private _symbol = "EOL";
    uint8 private _decimals = 18;

    uint256 public immutable MAX_TOTAL_SUPPLY = 600000000 * 10 ** _decimals;
    uint256 public immutable MIN_TOTAL_SUPPLY = 21000000 * 10 ** _decimals;
    uint256 public totalBurned;

    address public swapV2RouterAddress;
    IUniswapV2Router02 public swapV2Router;
    address public swapV2PairBNB;
    address public swapV2PairUSDT;
    address public usdt;

    address private memberManager;
    address private liquidityManager;
    address private techAddress;

    mapping(address => bool) private excluded;

    uint256 public startTime;

    uint8 public autoLPRate = 25;
    uint8 public burnRate = 15;
    uint8 public daoRate = 10;
    uint8 public techRate = 5;
    uint8 public transRate = 10;

    bool swapLock;
    modifier lockSwap() {
        require(!swapLock, "EncryptedOasisLegend: locked");
        swapLock = true;
        _;
        swapLock = false;
    }

    constructor(address _swapV2RouterAddress, address _usdt, address _techAddress) {
        require(_techAddress != address(0), "EncryptedOasisLegend: tech address is 0");

        _mint(owner(), MAX_TOTAL_SUPPLY);

        swapV2RouterAddress = _swapV2RouterAddress;
        usdt = _usdt;
        techAddress = _techAddress;

        swapV2Router = IUniswapV2Router02(swapV2RouterAddress);
        swapV2PairBNB = IUniswapV2Factory(swapV2Router.factory())
            .createPair(address(this), swapV2Router.WETH());
        swapV2PairUSDT = IUniswapV2Factory(swapV2Router.factory())
            .createPair(address(this), usdt);

        excluded[owner()] = true;
        excluded[address(this)] = true;
        excluded[techAddress] = true;
    }

    function transToken(address token, address addr, uint256 amount) public onlyOwner {
        require(addr != address(0), "EncryptedOasisLegend: address is 0");
        require(amount > 0, "EncryptedOasisLegend: amount equal to 0");
        require(amount <= IERC20Metadata(token).balanceOf(address(this)), "EncryptedOasisLegend: insufficient balance");
        Address.functionCall(token, abi.encodeWithSelector(0xa9059cbb, addr, amount));
    }

    function setLiquidityManager(address _liquidityManager) public onlyOwner {
        require(_liquidityManager != address(0), "EncryptedOasisLegend: address is 0");
        liquidityManager = _liquidityManager;
        excluded[liquidityManager] = true;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        require(startTime == 0, "EncryptedOasisLegend: start time has been set");
        require(_startTime > 0, "EncryptedOasisLegend: start time is 0");
        startTime = _startTime;
    }

    function setExcluded(address _addr, bool _state) public onlyOwner {
        require(excluded[_addr] != _state, "EncryptedOasisLegend: same state");
        excluded[_addr] = _state;
    }

    function setMemberManager(address _memberManager) public onlyOwner {
        require(_memberManager != address(0), "EncryptedOasisLegend: address is 0");
        memberManager = _memberManager;
        excluded[memberManager] = true;
    }

    function setTechAddress(address _techAddress) public onlyOwner {
        require(_techAddress != address(0), "EncryptedOasisLegend: address is 0");
        techAddress = _techAddress;
        excluded[techAddress] = true;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
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
        require(currentAllowance >= subtractedValue, "EncryptedOasisLegend: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function burn(uint256 amount) public {
        address spender = _msgSender();
        _burn(spender, amount);
    }

    function burnFrom(address from, uint256 amount) public {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        _burn(from, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(amount > 0, "EncryptedOasisLegend: transfer amount is 0");
        require(from != address(0), "EncryptedOasisLegend: transfer from the zero address");
        require(to != address(0), "EncryptedOasisLegend: transfer to the zero address");

        _transferControl(from, to, amount);

        if (from != swapV2PairUSDT && !swapLock) {
            _swapForLiquidity();
        }

        uint256 fromBalance = _balances[from];
        _balances[from] = fromBalance - amount;

        uint256 finalAmount = _countFee(from, to, amount);

        _transferTo(from, to, finalAmount);

        if (from == swapV2PairUSDT) {
            _bonus(to, amount);
        }
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "EncryptedOasisLegend: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "EncryptedOasisLegend: burn from the zero address");
        require(amount > 0, "EncryptedOasisLegend: burn amount is 0");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "EncryptedOasisLegend: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }

        _baseBurn(account, amount);
    }

    function _baseBurn(address account, uint256 amount) private {
        uint256 finalBurn = amount;
        if (_totalSupply - amount < MIN_TOTAL_SUPPLY) {
            finalBurn = _totalSupply - MIN_TOTAL_SUPPLY;
        }
        _totalSupply -= finalBurn;
        totalBurned += finalBurn;

        if (finalBurn < amount) {
            _transferTo(account, techAddress, amount - finalBurn);
        }

        emit Transfer(account, address(0), finalBurn);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "EncryptedOasisLegend: approve from the zero address");
        require(spender != address(0), "EncryptedOasisLegend: approve to the zero address");

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
            require(currentAllowance >= amount, "EncryptedOasisLegend: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transferControl(address from, address to, uint256 amount) view private {
        if (
            from == address(swapV2PairBNB) ||
            to == address(swapV2PairBNB) ||
            from == address(swapV2PairUSDT) ||
            to == address(swapV2PairUSDT)
        ) {
            address addr = (from == address(swapV2PairBNB) || from == address(swapV2PairUSDT)) ? to : from;

            if (excluded[addr]) {
                return;
            }

            if (startTime == 0 || startTime > block.timestamp) {
                revert("EncryptedOasisLegend: trading not started");
            }

            if (from != address(swapV2PairUSDT) && from != address(swapV2PairBNB)) {
                uint256 fromBalance = _balances[from];
                if (fromBalance * 99 / 100 < amount) {
                    revert("EncryptedOasisLegend: transfer amount exceeds balance");
                }
            }
        } else {
            if (excluded[from]) {
                return;
            }

            uint256 fromBalance = _balances[from];
            if (fromBalance * 99 / 100 < amount) {
                revert("EncryptedOasisLegend: transfer amount exceeds balance");
            }
        }
    }

    function _countFee(address from, address to, uint256 amount) private returns (uint256 finalAmount) {
        finalAmount = amount;
        if (from == address(swapV2PairUSDT) || to == address(swapV2PairUSDT)) {
            address addr = (from == address(swapV2PairUSDT)) ? to : from;

            uint256 lpFee;
            uint256 burnFee;
            uint256 daoFee;
            uint256 techFee;

            if (!excluded[addr] && _totalSupply > MIN_TOTAL_SUPPLY) {
                lpFee = amount * autoLPRate / 1000;
                burnFee = amount * burnRate / 1000;
                daoFee = amount * daoRate / 1000;
                techFee = amount * techRate / 1000;
            }

            if (lpFee + daoFee + techFee > 0) {
                _transferTo(from, liquidityManager, lpFee + daoFee + techFee);
            }
            if (burnFee > 0) {
                _baseBurn(from, burnFee);
            }

            finalAmount = amount - lpFee - burnFee - daoFee - techFee;
        } else {
            if (!excluded[from] && _totalSupply > MIN_TOTAL_SUPPLY) {
                uint256 transBurnFee = amount * transRate / 1000;
                if (transBurnFee > 0) {
                    _baseBurn(from, transBurnFee);
                }

                finalAmount = amount - transBurnFee;
            }
        }
    }

    function _transferTo(
        address from,
        address to,
        uint256 amount
    ) private {
        _balances[to] = _balances[to] + amount;
        emit Transfer(from, to, amount);
    }

    function _swapForLiquidity() private lockSwap {
        Address.functionCall(liquidityManager, abi.encodeWithSelector(0x7389b5fd));
    }

    function _bonus(address buyer, uint256 amount) private {
        if (memberManager == address(0)) {
            return;
        }
        Address.functionCall(memberManager, abi.encodeWithSelector(0x7da0c2ab, buyer, amount));
    }
}