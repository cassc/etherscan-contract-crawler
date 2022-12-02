// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./owner/Operator.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";

contract ChamTokenV2 is ERC20 {
    using SafeERC20 for IERC20;

    address public immutable underlying;
    bool public constant underlyingIsMinted = false;

    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    // init flag for setting immediate vault, needed for CREATE2 support
    bool private _init;

    // flag to enable/disable swapout vs vault.burn so multiple events are triggered
    bool private _vaultOnly;

    // delay for timelock functions
    uint public constant DELAY = 2 days;

    // set of minters, can be this bridge or other bridges
    mapping(address => bool) public isMinter;
    address[] public minters;

    // primary controller of the token contract
    address public vault;

    address public pendingMinter;
    uint public delayMinter;

    address public pendingVault;
    uint public delayVault;

    // logic
    address public operator;
    address public polWallet;
    uint256 public constant INITIAL_SUPPLY = 72000 ether;

    mapping (address => bool) public marketLpPairs; // LP Pairs
    mapping(address => bool) public excludedAccountSellingLimitTime;

    uint256 public taxSellingPercent = 50;
    mapping(address => bool) public excludedSellingTaxAddresses;

    uint256 public taxBuyingPercent = 50;
    mapping(address => bool) public excludedBuyingTaxAddresses;

    uint256 public timeLimitSelling = 1 minutes;
    mapping(address => uint256) private _lastTimeReceiveToken;

    modifier onlyOperator() {
        require(operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    modifier onlyAuth() {
        require(isMinter[msg.sender], "AnyswapV6ERC20: FORBIDDEN");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "AnyswapV6ERC20: FORBIDDEN");
        _;
    }

    function owner() external view returns (address) {
        return vault;
    }

    function mpc() external view returns (address) {
        return vault;
    }

    function setVaultOnly(bool enabled) external onlyVault {
        _vaultOnly = enabled;
    }

    function initVault(address _vault) external onlyVault {
        require(_init);
        _init = false;
        vault = _vault;
        isMinter[_vault] = true;
        minters.push(_vault);
    }

    function setVault(address _vault) external onlyVault {
        require(_vault != address(0), "AnyswapV6ERC20: address(0)");
        pendingVault = _vault;
        delayVault = block.timestamp + DELAY;
    }

    function applyVault() external onlyVault {
        require(pendingVault != address(0) && block.timestamp >= delayVault);
        vault = pendingVault;

        pendingVault = address(0);
        delayVault = 0;
    }

    function setMinter(address _auth) external onlyVault {
        require(_auth != address(0), "AnyswapV6ERC20: address(0)");
        pendingMinter = _auth;
        delayMinter = block.timestamp + DELAY;
    }

    function applyMinter() external onlyVault {
        require(pendingMinter != address(0) && block.timestamp >= delayMinter);
        isMinter[pendingMinter] = true;
        minters.push(pendingMinter);

        pendingMinter = address(0);
        delayMinter = 0;
    }

    // No time delay revoke minter emergency function
    function revokeMinter(address _auth) external onlyVault {
        isMinter[_auth] = false;
    }

    function getAllMinters() external view returns (address[] memory) {
        return minters;
    }

    function changeVault(address newVault) external onlyVault returns (bool) {
        require(newVault != address(0), "AnyswapV6ERC20: address(0)");
        emit LogChangeVault(vault, newVault, block.timestamp);
        vault = newVault;
        pendingVault = address(0);
        delayVault = 0;
        return true;
    }

    function mint(address to, uint256 amount) external onlyAuth returns (bool) {
        _mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount) external onlyAuth returns (bool) {
        _burn(from, amount);
        return true;
    }

    function Swapin(bytes32 txhash, address account, uint256 amount) external onlyAuth returns (bool) {
        if (underlying != address(0) && IERC20(underlying).balanceOf(address(this)) >= amount) {
            IERC20(underlying).safeTransfer(account, amount);
        } else {
            _mint(account, amount);
        }
        emit LogSwapin(txhash, account, amount);
        return true;
    }

    function Swapout(uint256 amount, address bindaddr) external returns (bool) {
        require(!_vaultOnly, "AnyswapV6ERC20: vaultOnly");
        require(bindaddr != address(0), "AnyswapV6ERC20: address(0)");
        if (underlying != address(0) && _balances[msg.sender] < amount) {
            IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        } else {
            _burn(msg.sender, amount);
        }
        emit LogSwapout(msg.sender, bindaddr, amount);
        return true;
    }

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event LogChangeVault(address indexed oldVault, address indexed newVault, uint indexed effectiveTime);
    event LogSwapin(bytes32 indexed txhash, address indexed account, uint amount);
    event LogSwapout(address indexed account, address indexed bindaddr, uint amount);
    event SetPolWallet(address oldWallet, address newWallet);
    event SetTaxSellingPercent(uint256 oldValue, uint256 newValue);
    event SetTaxBuyingPercent(uint256 oldValue, uint256 newValue);
    event SetTimeLimitSelling(uint256 oldValue, uint256 newValue);

    constructor(address _underlying, address _vault, address _polWallet, address _wbnbAddress, address _router) ERC20("Champion", "CHAM") {
        require(_polWallet != address(0), "!_polWallet");
        require(_wbnbAddress != address(0), "!_wbnbAddress");
        require(_router != address(0), "!_router");

        underlying = _underlying;
        if (_underlying != address(0)) {
            require(decimals() == IERC20Metadata(_underlying).decimals());
        }

        // Use init to allow for CREATE2 accross all chains
        _init = true;

        // Disable/Enable swapout for v1 tokens vs mint/burn for v3 tokens
        _vaultOnly = false;

        vault = _vault;

        operator = msg.sender;
        polWallet = _polWallet;

        IUniswapV2Router _dexRouter = IUniswapV2Router(_router);
		address dexPair = IUniswapV2Factory(_dexRouter.factory()).createPair(address(this), _wbnbAddress);
        setMarketLpPairs(dexPair, true);
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function deposit() external returns (uint) {
        uint _amount = IERC20(underlying).balanceOf(msg.sender);
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), _amount);
        return _deposit(_amount, msg.sender);
    }

    function deposit(uint amount) external returns (uint) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        return _deposit(amount, msg.sender);
    }

    function deposit(uint amount, address to) external returns (uint) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        return _deposit(amount, to);
    }

    function depositVault(uint amount, address to) external onlyVault returns (uint) {
        return _deposit(amount, to);
    }

    function _deposit(uint amount, address to) internal returns (uint) {
        require(!underlyingIsMinted);
        require(underlying != address(0) && underlying != address(this));
        _mint(to, amount);
        return amount;
    }

    function withdraw() external returns (uint) {
        return _withdraw(msg.sender, _balances[msg.sender], msg.sender);
    }

    function withdraw(uint amount) external returns (uint) {
        return _withdraw(msg.sender, amount, msg.sender);
    }

    function withdraw(uint amount, address to) external returns (uint) {
        return _withdraw(msg.sender, amount, to);
    }

    function withdrawVault(address from, uint amount, address to) external onlyVault returns (uint) {
        return _withdraw(from, amount, to);
    }

    function _withdraw(address from, uint amount, address to) internal returns (uint) {
        require(!underlyingIsMinted);
        require(underlying != address(0) && underlying != address(this));
        _burn(from, amount);
        IERC20(underlying).safeTransfer(to, amount);
        return amount;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
		require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        _lastTimeReceiveToken[to] = block.timestamp;
        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override {
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

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(polWallet != address(0),"require to set polWallet address");
        address sender = _msgSender();
        // Buying token
        if(marketLpPairs[sender] && !excludedBuyingTaxAddresses[to] && taxBuyingPercent > 0) {
            uint256 taxAmount = amount * taxBuyingPercent / 10000;
            if(taxAmount > 0)
            {
                amount = amount - taxAmount;
                _transfer(sender, polWallet, taxAmount);
            }
        }

        _transfer(sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(polWallet != address(0),"require to set polWallet address");
        
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        // Selling token
		if(marketLpPairs[to] && !excludedSellingTaxAddresses[from]) {
            require(excludedAccountSellingLimitTime[from] || block.timestamp > (_lastTimeReceiveToken[from] + timeLimitSelling), "Selling limit time");
            if (taxSellingPercent > 0) {
                uint256 taxAmount = amount * taxSellingPercent / 10000;
                if(taxAmount > 0)
                {
                    amount = amount - taxAmount;
                    _transfer(from, polWallet, taxAmount);
                }
            }
		}

        _transfer(from, to, amount);
        return true;
    }

    function setPolWallet(address _polWallet) external onlyOperator {
        require(_polWallet != address(0), "_polWallet address cannot be 0 address");
		emit SetPolWallet(polWallet, _polWallet);
        polWallet = _polWallet;
    }

    function setTaxSellingPercent(uint256 _value) external onlyOperator returns (bool) {
		require(_value <= 50, "Max tax is 0.5%");
		emit SetTaxSellingPercent(taxSellingPercent, _value);
        taxSellingPercent = _value;
        return true;
    }

    function setTaxBuyingPercent(uint256 _value) external onlyOperator returns (bool) {
		require(_value <= 50, "Max tax is 0.5%");
		emit SetTaxBuyingPercent(taxBuyingPercent, _value);
        taxBuyingPercent = _value;
        return true;
    }

    function setTimeLimitSelling(uint256 _value) external onlyOperator returns (bool) {
		require(_value <= 30 minutes, "Max limit time is 30 minutes");
		emit SetTimeLimitSelling(timeLimitSelling, _value);
        timeLimitSelling = _value;
        return true;
    }

    function excludeSellingTaxAddress(address _address) external onlyOperator returns (bool) {
        require(!excludedSellingTaxAddresses[_address], "Address can't be excluded");
        excludedSellingTaxAddresses[_address] = true;
        return true;
    }

    function includeSellingTaxAddress(address _address) external onlyOperator returns (bool) {
        require(excludedSellingTaxAddresses[_address], "Address can't be included");
        excludedSellingTaxAddresses[_address] = false;
        return true;
    }

    function excludeBuyingTaxAddress(address _address) external onlyOperator returns (bool) {
        require(!excludedBuyingTaxAddresses[_address], "Address can't be excluded");
        excludedBuyingTaxAddresses[_address] = true;
        return true;
    }

    function includeBuyingTaxAddress(address _address) external onlyOperator returns (bool) {
        require(excludedBuyingTaxAddresses[_address], "Address can't be included");
        excludedBuyingTaxAddresses[_address] = false;
        return true;
    }

    function excludeAccountSellingLimitTime(address _address) external onlyOperator returns (bool) {
        require(!excludedAccountSellingLimitTime[_address], "Address can't be excluded");
        excludedAccountSellingLimitTime[_address] = true;
        return true;
    }

    function includeAccountSellingLimitTime(address _address) external onlyOperator returns (bool) {
        require(excludedAccountSellingLimitTime[_address], "Address can't be included");
        excludedAccountSellingLimitTime[_address] = false;
        return true;
    }

    //Add new LP's for selling / buying fees
    function setMarketLpPairs(address _pair, bool _value) public onlyOperator {
        marketLpPairs[_pair] = _value;
    }

    function transferOperator(address newOperator_) public onlyOperator {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(operator, newOperator_);
        operator = newOperator_;
    }
}