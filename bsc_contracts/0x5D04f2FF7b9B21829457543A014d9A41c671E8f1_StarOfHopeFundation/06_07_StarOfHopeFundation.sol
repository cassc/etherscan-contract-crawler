// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./SwapInterface.sol";

contract StarOfHopeFundation is Ownable, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "Star of Hope Fundation";
    string private _symbol = "SHF";
    uint8 private _decimals = 18;

    uint256 public immutable MAX_TOTAL_SUPPLY = 1680000 * 10 ** _decimals;
    uint256 public immutable MIN_TOTAL_SUPPLY = 21000 * 10 ** _decimals;
    uint256 public totalBurned;

    address public swapV2RouterAddress;
    IUniswapV2Router02 public swapV2Router;
    address public swapV2PairBNB;
    address public swapV2PairUSDT;
    address public usdt;

    address private member;
    address private nodeBonusManager;
    address private techAddress;

    mapping(address => bool) private excluded;

    uint256 public startTime;
    bool public buyState;

    uint8 public buyNodeBonusRate = 45;
    uint8 public buyTechRate = 15;
    uint8 public sellNodeBonusRate = 60;
    uint8 public sellTechRate = 20;
    uint8 public sellBurnRate = 40;

    bool swapLock;
    modifier lockSwap() {
        require(!swapLock, "StarOfHopeFundation: locked");
        swapLock = true;
        _;
        swapLock = false;
    }

    constructor(address _swapV2RouterAddress, address _usdt, address _techAddress) {
        require(_techAddress != address(0), "StarOfHopeFundation: tech address is 0");

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

    function initNodeBonusManager(address _nodeBonusManager, uint256 _minDealTokenCount) public onlyOwner {
        nodeBonusManager = _nodeBonusManager;
        excluded[nodeBonusManager] = true;
        Address.functionCall(
            nodeBonusManager,
            abi.encodeWithSelector(
                0x5e9ab149,
                swapV2RouterAddress,
                address(this),
                usdt,
                swapV2PairUSDT,
                _minDealTokenCount
            )
        );
    }

    function transToken(address token, address addr, uint256 amount) public onlyOwner {
        require(addr != address(0), "StarOfHopeFundation: address is 0");
        require(amount > 0, "StarOfHopeFundation: amount equal to 0");
        require(amount <= IERC20Metadata(token).balanceOf(address(this)), "StarOfHopeFundation: insufficient balance");
        Address.functionCall(token, abi.encodeWithSelector(0xa9059cbb, addr, amount));
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        require(startTime == 0, "StarOfHopeFundation: start time has been set");
        require(_startTime > 0, "StarOfHopeFundation: start time is 0");
        startTime = _startTime;
    }

    function setBuyState(bool _buyState) public onlyOwner {
        require(_buyState != buyState, "StarOfHopeFundation: same state");
        buyState = _buyState;
    }

    function setExcluded(address _addr, bool _state) public onlyOwner {
        require(excluded[_addr] != _state, "StarOfHopeFundation: same state");
        excluded[_addr] = _state;
    }

    function setMember(address _member) public onlyOwner {
        require(_member != address(0), "StarOfHopeFundation: address is 0");
        member = _member;
        excluded[member] = true;
    }

    function setTechAddress(address _techAddress) public onlyOwner {
        require(_techAddress != address(0), "StarOfHopeFundation: address is 0");
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
        require(currentAllowance >= subtractedValue, "StarOfHopeFundation: decreased allowance below zero");
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
        require(amount > 0, "StarOfHopeFundation: transfer amount is 0");
        require(from != address(0), "StarOfHopeFundation: transfer from the zero address");
        require(to != address(0), "StarOfHopeFundation: transfer to the zero address");

        _transferControl(from, to);

        if (from != swapV2PairUSDT && !swapLock) {
            _swapForNodeBonus();
        }

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "StarOfHopeFundation: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }

        uint256 finalAmount = _countFee(from, to, amount);

        _transferTo(from, to, finalAmount);

        _releasePreSale();
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "StarOfHopeFundation: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "StarOfHopeFundation: burn from the zero address");
        require(amount > 0, "StarOfHopeFundation: burn amount is 0");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "StarOfHopeFundation: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }

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
        require(owner != address(0), "StarOfHopeFundation: approve from the zero address");
        require(spender != address(0), "StarOfHopeFundation: approve to the zero address");

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
            require(currentAllowance >= amount, "StarOfHopeFundation: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transferControl(address from, address to) view private {
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
                revert("StarOfHopeFundation: trade not started");
            }

            if (from == address(swapV2PairBNB) || from == address(swapV2PairUSDT)) {
                if (!buyState) {
                    revert("StarOfHopeFundation: can not buy");
                }
            }
        }
    }

    function _countFee(address from, address to, uint256 amount) private returns (uint256 finalAmount) {
        finalAmount = amount;
        if (from == address(swapV2PairUSDT) || to == address(swapV2PairUSDT)) {
            address addr = (from == address(swapV2PairUSDT)) ? to : from;

            uint256 nodeBonusFee;
            uint256 techFee;
            uint256 burnFee;

            if (!excluded[addr] && _totalSupply > MIN_TOTAL_SUPPLY) {
                if (from == address(swapV2PairUSDT)) {
                    nodeBonusFee = amount * buyNodeBonusRate / 1000;
                    techFee = amount * buyTechRate / 1000;
                } else {
                    nodeBonusFee = amount * sellNodeBonusRate / 1000;
                    techFee = amount * sellTechRate / 1000;
                    burnFee = amount * sellBurnRate / 1000;
                }
            }

            if (nodeBonusFee > 0) {
                _transferTo(from, nodeBonusManager, nodeBonusFee);
            }
            if (techFee > 0) {
                _transferTo(from, techAddress, techFee);
            }
            if (burnFee > 0) {
                _burn(from, burnFee);
            }

            finalAmount = amount - nodeBonusFee - techFee - burnFee;
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

    function _swapForNodeBonus() private lockSwap {
        Address.functionCall(nodeBonusManager, abi.encodeWithSelector(0xd7186378));
    }

    function _releasePreSale() private {
        Address.functionCall(member, abi.encodeWithSelector(0x4925decf));
    }
}