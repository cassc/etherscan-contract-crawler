// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./SwapInterface.sol";

contract CBTDao is Ownable, IERC20Metadata{
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "Come back Bitcoin";
    string private _symbol = "CBT";
    uint8 private _decimals = 18;

    uint256 public minTotalSupply;
    uint256 public burnTotal;

    address public uniswapV2RouterAddress;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2PairBNB;
    address public uniswapV2PairUSDT;
    address public usdt;

    uint8 private lpRate = 10;
    uint8 private nftBonusRate = 10;

    address private liquidityManager;
    address private nftBonusManager;
    address private fundManager;

    mapping(address => bool) private excluded;

    uint256 private startTime;

    bool swapLock;
    modifier lockSwap() {
        require(!swapLock, "CBTDao: locked");
        swapLock = true;
        _;
        swapLock = false;
    }

    constructor(address _uniswapV2RouterAddress, address _usdt) {
        _mint(owner(), 10500000 * 10 ** _decimals);
        minTotalSupply = 1050000 * 10 ** _decimals;

        uniswapV2RouterAddress = _uniswapV2RouterAddress;
        usdt = _usdt;

        uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);
        uniswapV2PairBNB = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2PairUSDT = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), usdt);

        excluded[owner()] = true;
        excluded[address(this)] = true;
    }

    function initLiquidityManager(address _liquidityManager, uint256 _minLpDealTokenCount) public onlyOwner {
        liquidityManager = _liquidityManager;
        excluded[liquidityManager] = true;
        Address.functionCall(
            liquidityManager,
            abi.encodeWithSelector(
                0x544b08b5,
                uniswapV2RouterAddress,
                address(this),
                usdt,
                uniswapV2PairUSDT,
                owner(),
                _minLpDealTokenCount
            )
        );
    }

    function initNFTBonusManager(address _nftBonusManager, uint256 _minDealTokenCount) public onlyOwner {
        nftBonusManager = _nftBonusManager;
        excluded[nftBonusManager] = true;
        Address.functionCall(
            nftBonusManager,
            abi.encodeWithSelector(
                0x5e9ab149,
                uniswapV2RouterAddress,
                address(this),
                usdt,
                uniswapV2PairUSDT,
                _minDealTokenCount
            )
        );
    }

    function transToken(address token, address addr, uint256 amount) public onlyOwner {
        require(addr != address(0), "CBTDao: address is 0");
        require(amount > 0, "CBTDao: amount equal to 0");
        require(amount <= IERC20Metadata(token).balanceOf(address(this)), "CBTDao: insufficient balance");
        Address.functionCall(token, abi.encodeWithSelector(0xa9059cbb, addr, amount));
    }

    function setFundManager(address _fundManager) public onlyOwner {
        require(_fundManager != address(0), "CBTDao: address is 0");
        fundManager = _fundManager;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        require(_startTime > 0, "CBTDao: start time is 0");
        startTime = _startTime;
    }

    function setExcluded(address _addr, bool _state) public onlyOwner {
        require(excluded[_addr] != _state, "CBTDao: same state");
        excluded[_addr] = _state;
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
        require(currentAllowance >= subtractedValue, "CBTDao: decreased allowance below zero");
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
    ) private {
        require(from != address(0), "CBTDao: transfer from the zero address");
        require(to != address(0), "CBTDao: transfer to the zero address");

        _transferControl(from, to);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "CBTDao: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }

        if (from != uniswapV2PairUSDT && !swapLock) {
            _swapForLiquidity();
        }

        if (from != uniswapV2PairUSDT && !swapLock) {
            _swapForNFTBonus();
        }

        _releaseFund();

        _balances[to] += _countFee(from, to, amount);

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "CBTDao: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "CBTDao: burn from the zero address");
        require(_totalSupply > minTotalSupply, "CBTDao: can not burn");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "CBTDao: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }

        uint256 finalBurn = amount;
        if (_totalSupply - amount < minTotalSupply) {
            finalBurn = _totalSupply - minTotalSupply;
        }
        _totalSupply -= finalBurn;
        burnTotal += finalBurn;

        if (finalBurn < amount) {
            _basicTransfer(account, liquidityManager, amount - finalBurn);
        }

        emit Transfer(account, address(0), finalBurn);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "CBTDao: approve from the zero address");
        require(spender != address(0), "CBTDao: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "CBTDao: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transferControl(address from, address to) view private {
        if (
            from == address(uniswapV2PairBNB) ||
            to == address(uniswapV2PairBNB) ||
            from == address(uniswapV2PairUSDT) ||
            to == address(uniswapV2PairUSDT)
        ) {
            address addr = (from == address(uniswapV2PairBNB) || from == address(uniswapV2PairUSDT)) ? to : from;
            if (excluded[addr]) {
                return;
            }

            if (startTime == 0 || startTime > block.timestamp) {
                revert("CBTDao: trade not started");
            }
        }
    }

    function _countFee(address from, address to, uint256 amount) private returns (uint256 finalAmount) {
        finalAmount = amount;
        if (from == address(uniswapV2PairUSDT) || to == address(uniswapV2PairUSDT)) {
            address addr = (from == address(uniswapV2PairUSDT)) ? to : from;
            if (!excluded[addr]) {
                uint256 lpFee = amount * lpRate / 1000;
                uint256 nftBonusFee = amount * nftBonusRate / 1000;

                if (lpFee > 0) {
                    _basicTransfer(from, liquidityManager, lpFee);
                }
                if (nftBonusFee > 0) {
                    _basicTransfer(from, nftBonusManager, nftBonusFee);
                }

                finalAmount = amount - lpFee - nftBonusFee;
            }
        }
    }

    function _basicTransfer(
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

    function _swapForNFTBonus() private lockSwap {
        Address.functionCall(nftBonusManager, abi.encodeWithSelector(0xd7186378));
    }

    function _releaseFund() private {
        Address.functionCall(fundManager, abi.encodeWithSelector(0x86d1a69f));
    }
}