// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title TIME Token contract
 * @notice Smart contract used for main interaction with the TIME tokenomics system
 **/
contract TimeToken is IERC20 {

    using SafeMath for uint256;

    event Mining(address indexed miner, uint256 amount, uint256 blockNumber);
    event Donation(address indexed donator, uint256 donatedAmount);

    bool private _isMintLocked = false;
    bool private _isOperationLocked;

    uint8 private constant _decimals = 18;

    address public constant DEVELOPER_ADDRESS = 0x731591207791A93fB0Ec481186fb086E16A7d6D0;

    uint256 private constant FACTOR = 10**18;
    uint256 private constant D = 10**_decimals;

    uint256 public constant BASE_FEE = 0.1 ether; // 10 ether; (Polygon) | 0.1 ether; (BSC) | 20 ether; (Fantom) | 0.01 ether; (Ethereum)
    uint256 public constant COMISSION_RATE = 2;
    uint256 public constant SHARE_RATE = 4;
    uint256 public constant TIME_BASE_LIQUIDITY = 200000 * D; // 200000 * D; (Polygon and BSC) | 400000 * D; (Fantom) | 40000 * D; (Ethereum)
    uint256 public constant TIME_BASE_FEE = 4800000 * D; // 4800000 * D; (Polygon and BSC) | 9600000 * D; (Fantom) | 960000 * D; (Ethereum)
    uint256 public constant TOLERANCE = 10;

    uint256 private _totalSupply;
    uint256 public dividendPerToken;
    uint256 public firstBlock;
    uint256 public liquidityFactorNative = 11;
    uint256 public liquidityFactorTime = 20;
    uint256 public numberOfHolders;
    uint256 public numberOfMiners;
    uint256 public sharedBalance;
    uint256 public poolBalance;
    uint256 public totalMinted;

    string private _name;
    string private _symbol;

    mapping (address => bool) public isMiningAllowed;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _consumedDividendPerToken;
    mapping (address => uint256) private _credits;
    mapping (address => uint256) private _lastBalances;
    mapping (address => uint256) private _lastBlockMined;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor(
        string memory name_,
        string memory symbol_
    ) {
        _name = name_;
        _symbol = symbol_;
        firstBlock = block.number;
    }

    modifier nonReentrant() {
	    require(!_isOperationLocked, "TIME: This operation is locked for security reasons");
		_isOperationLocked = true;
		_;
		_isOperationLocked = false;
	}

    receive() external payable {
        saveTime();
    }

    fallback() external payable {
        require(msg.data.length == 0);
        saveTime();
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
      	return _symbol;
    }

    function decimals() public pure returns (uint8) {
      	return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external override view returns (uint256) {
        return _balances[account];
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function transfer(address to, uint256 amount) external override returns (bool success) {
        if (to == address(this))
            success = spendTime(amount);
        else
            success = _transfer(msg.sender, to, amount);
		return success;
    }

    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
		return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool success) {
		success = _transfer(from, to, amount);
		_approve(from, msg.sender, _allowances[from][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return success;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (_balances[to] > 0 && to != address(0) && to != address(this) && _lastBalances[to] != _balances[to] && _lastBalances[to] == 0)
            numberOfHolders++;

        if (_balances[from] == 0 && from != address(0) && to != address(this) && _lastBalances[from] != _balances[from])
            numberOfHolders--;

        _lastBalances[from] = _balances[from];
        _lastBalances[to] = _balances[to];    
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        _credit(from);
        _credit(to);
        _lastBalances[from] = _balances[from];
        _lastBalances[to] = _balances[to];
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }

        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        totalMinted += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);

        return true;
    }

    /**
     * @notice Calculate the amount some address has to claim and credit for it
     * @param account The account address
     **/
    function _credit(address account) private {
        _credits[account] += accountShareBalance(account);
        _consumedDividendPerToken[account] = dividendPerToken;
    }

    /**
     *  @notice Obtain the aproximate amount of blocks needed to drain the whole internal LP (considering the current TIME mining rate)
     **/
    function _getAmountOfBlocksToDrainLP(bool isFeeInTime) private view returns (uint256) {
        if (averageMiningRate() == 0) {
            if (isFeeInTime)
                return TIME_BASE_FEE;
            else
                return TIME_BASE_LIQUIDITY;
        } else {
            return ((_balances[address(this)] * D) / averageMiningRate());
        }
    }

    /**
     * @notice Called when an investor wants to exchange ETH for TIME. A comission in ETH is paid to miner (block.coinbase) and developer
     * @param comissionAmount The amount in ETH which will be paid (two times)
    **/
    function _payComission(uint256 comissionAmount) private {
        payable(DEVELOPER_ADDRESS).transfer(comissionAmount);
        if (block.coinbase == address(0))
            payable(DEVELOPER_ADDRESS).transfer(comissionAmount);
        else
            payable(block.coinbase).transfer(comissionAmount);

        sharedBalance += comissionAmount;
        poolBalance += comissionAmount;
        dividendPerToken += ((comissionAmount * FACTOR) / (_totalSupply - _balances[address(this)] + 1));
    }

    /**
     * @notice Called when an investor wants to exchange TIME for ETH. A comission in TIME token is paid to miner (block.coinbase) and developer
     * @param comissionAmount The amount in TIME tokens which will be paid (two times)
     **/
    function _payComissionInTime(uint256 comissionAmount) private {
        _transfer(msg.sender, DEVELOPER_ADDRESS, comissionAmount);
        if (block.coinbase == address(0))
            _transfer(msg.sender, DEVELOPER_ADDRESS, comissionAmount);
        else
            _transfer(msg.sender, block.coinbase, comissionAmount);

        _burn(msg.sender, comissionAmount);
    }

    /**
     * @notice Returns the average rate of TIME tokens mined per block (mining rate)
     **/
    function averageMiningRate() public view returns (uint256) {
        if (totalMinted > TIME_BASE_LIQUIDITY) 
            return ((totalMinted - TIME_BASE_LIQUIDITY) / (block.number - firstBlock));
        else
            return 0;
    }

    /**
     *  @notice Just verify if the msg.value has any ETH value for donation
     **/
    function donateEth() public payable nonReentrant {
        require(msg.value > 0, "TIME: please specify any amount you would like to donate");
        emit Donation(msg.sender, msg.value);
        uint256 remaining = msg.value;
        uint256 totalComission = (msg.value * COMISSION_RATE) / 100;
        uint256 comission = totalComission / SHARE_RATE;
        _payComission(comission);
        remaining -= totalComission;
        sharedBalance += (remaining / 2);
        dividendPerToken += (((remaining / 2) * FACTOR) / (_totalSupply - _balances[address(this)] + 1));
        remaining /= 2;
        poolBalance += remaining;
    }

    /** 
     * @notice An address call this function to be able to mine TIME by paying with ETH (native cryptocurrency)
     * @dev An additional amount of TIME should be created for the AMM address to provide initial liquidity if the contract does not have any miners enabled
    **/
    function enableMining() public payable nonReentrant {
        uint256 f = fee();
        uint256 tolerance;
        if (msg.value < f) {
            tolerance = (f * TOLERANCE) / 100;
            require(msg.value >= (f - tolerance), "TIME: to enable mining for an address you need at least the fee() amount in native currency");
        }
        require(!isMiningAllowed[msg.sender], "TIME: the address is already enabled");
        uint256 remaining = msg.value;
        isMiningAllowed[msg.sender] = true;
        _lastBlockMined[msg.sender] = block.number;
        if (numberOfMiners == 0)
            _mint(address(this), TIME_BASE_LIQUIDITY);
        
        uint256 totalComission = ((remaining * COMISSION_RATE) / 100);
        uint256 comission = totalComission / SHARE_RATE;
        _payComission(comission);
        remaining -= totalComission;
        sharedBalance += (remaining / 2);
        dividendPerToken += (((remaining / 2) * FACTOR) / (_totalSupply - _balances[address(this)] + 1));
        remaining /= 2;
        poolBalance += remaining;
        if (numberOfMiners == 0) {
            poolBalance += sharedBalance;
            sharedBalance = 0;
            dividendPerToken = 0;
        }
        numberOfMiners++;
    }

    /**
     * @notice An address call this function to be able to mine TIME with its earned (or bought) TIME tokens
     **/
    function enableMiningWithTimeToken() public nonReentrant {
        uint256 f = feeInTime();
        require(_balances[msg.sender] >= f, "TIME: to enable mining for an address you need at least the feeInTime() amount in TIME tokens");
        require(!isMiningAllowed[msg.sender], "TIME: the address is already enabled");
        _burn(msg.sender, f);
        isMiningAllowed[msg.sender] = true;
        _lastBlockMined[msg.sender] = block.number;
        numberOfMiners++;
    }

    /**
     * @notice Query the fee amount needed, in ETH, to enable an address for mining TIME
     * @dev Function has now dynamic fee calculation. Fee should not be so expensive and not cheap at the same time
     * @return Fee amount (in native cryptocurrency)
     **/
    function fee() public view returns (uint256) {
        return (((BASE_FEE * TIME_BASE_LIQUIDITY) / _getAmountOfBlocksToDrainLP(false)) / (numberOfMiners + 1));
    }

    /**
     * @notice Query the fee amount needed, in TIME, to enable an address for mining TIME
     * @dev Function has now dynamic fee calculation. Fee should not be so expensive and not cheap at the same time
     * @return Fee amount (in TIME Tokens)
     **/
    function feeInTime() public view returns (uint256) {
        return ((TIME_BASE_FEE * TIME_BASE_FEE) / _getAmountOfBlocksToDrainLP(true));
    }

    /**
     * @notice An allowed address call this function in order to mint TIME tokens according to the number of blocks which has passed since it has enabled mining
     **/
    function mining() public nonReentrant {
        if (isMiningAllowed[msg.sender]) {
            uint256 miningAmount = (block.number - _lastBlockMined[msg.sender]) * D;
            _mint(msg.sender, miningAmount);
            if (block.coinbase != address(0))
                _mint(block.coinbase, (miningAmount / 100));
            _lastBlockMined[msg.sender] = block.number;
            emit Mining(msg.sender, miningAmount, block.number);
        }
    }

    /**
     * @notice Investor send native cryptocurrency in exchange for TIME tokens. Here, he sends some amount and the contract calculates the equivalent amount in TIME units
     * @dev msg.value - The amount of TIME in terms of ETH an investor wants to 'save'
     **/
    function saveTime() public payable nonReentrant returns (bool success) {
        if (msg.value > 0) {
            uint256 totalComission = ((msg.value * COMISSION_RATE) / 100);
            uint256 comission = totalComission / SHARE_RATE;
            uint256 nativeAmountTimeValue = (msg.value * swapPriceNative(msg.value)) / FACTOR;
            require(nativeAmountTimeValue <= _balances[address(this)], "TIME: the pool does not have a sufficient amount to trade");
            _payComission(comission);
            success = _transfer(address(this), msg.sender, nativeAmountTimeValue - (((nativeAmountTimeValue * COMISSION_RATE) / 100) / SHARE_RATE));
            poolBalance += (msg.value - totalComission);
            liquidityFactorNative = liquidityFactorNative < 20 ? liquidityFactorNative + 1 : liquidityFactorNative;
            liquidityFactorTime = liquidityFactorTime > 11 ? liquidityFactorTime - 1 : liquidityFactorTime;
        }
        return success;
    }

    /**
     * @notice Investor send TIME tokens in exchange for native cryptocurrency
     * @param timeAmount The amount of TIME tokens for exchange
     **/
    function spendTime(uint256 timeAmount) public nonReentrant returns (bool success) {
        require(_balances[msg.sender] >= timeAmount, "TIME: there is no enough time to spend");
        uint256 comission = ((timeAmount * COMISSION_RATE) / 100) / SHARE_RATE;
        uint256 timeAmountNativeValue = (timeAmount * swapPriceTimeInverse(timeAmount)) / FACTOR;
        require(timeAmountNativeValue <= poolBalance, "TIME: the pool does not have a sufficient amount to trade");
        _payComissionInTime(comission);
        timeAmount -= comission.mul(3);
        success = _transfer(msg.sender, address(this), timeAmount);
        poolBalance -= timeAmountNativeValue;
        payable(msg.sender).transfer(timeAmountNativeValue - (((timeAmountNativeValue * COMISSION_RATE) / 100) / SHARE_RATE));
        liquidityFactorTime = liquidityFactorTime < 20 ? liquidityFactorTime + 1 : liquidityFactorTime;
        liquidityFactorNative = liquidityFactorNative > 11 ? liquidityFactorNative - 1 : liquidityFactorNative;
        return success;
    }

    /**
     * @notice Query for market price before swap, in TIME/ETH, in terms of native cryptocurrency (ETH)
     * @dev Constant Function Market Maker
     * @param amountNative The amount of ETH a user wants to exchange
     * @return Local market price, in TIME/ETH, given the amount of ETH a user informed
     **/
    function swapPriceNative(uint256 amountNative) public view returns (uint256) {
        if (poolBalance > 0 && _balances[address(this)] > 0) {
            uint256 ratio = (poolBalance * FACTOR) / (amountNative + 1);
            uint256 deltaSupply = (_balances[address(this)] * amountNative * ratio) / (poolBalance + ((amountNative * liquidityFactorNative) / 10));
            return (deltaSupply / poolBalance);
        } else {
            return 1;
        }
    }

    /**
     * @notice Query for market price before swap, in ETH/TIME, in terms of ETH currency
     * @param amountTime The amount of TIME a user wants to exchange
     * @return Local market price, in ETH/TIME, given the amount of TIME a user informed
     **/
    function swapPriceTimeInverse(uint256 amountTime) public view returns (uint256) {
        if (poolBalance > 0 && _balances[address(this)] > 0) {
            uint256 ratio = (_balances[address(this)] * FACTOR) / (amountTime + 1);
            uint256 deltaBalance = (poolBalance * amountTime * ratio) / (_balances[address(this)] + ((amountTime * liquidityFactorTime) / 10));
            return (deltaBalance / _balances[address(this)]);      
        } else {
            return 1;
        }
    }

    /**
     * @notice Show the amount in ETH an account address can credit to itself
     * @param account The address of some account
     * @return The claimable amount in ETH
     **/
    function accountShareBalance(address account) public view returns (uint256) {
        return ((_balances[account] * (dividendPerToken - _consumedDividendPerToken[account])) / FACTOR);
    }

    /**
     * @notice Show the amount in ETH an account address can withdraw to itself
     * @param account The address of some account
     * @return The withdrawable amount in ETH
     **/
    function withdrawableShareBalance(address account) public view returns (uint256) {
        return (accountShareBalance(account) + _credits[account]);
    }

    /**
     * @notice Withdraw the available amount returned by the accountShareBalance(address account) function
     **/
    function withdrawShare() public nonReentrant {
        uint256 withdrawableAmount = accountShareBalance(msg.sender);
        withdrawableAmount += _credits[msg.sender];
        require(withdrawableAmount > 0, "TIME: you don't have any amount to withdraw");
        require(withdrawableAmount <= sharedBalance, "TIME: there is no enough balance to share");
        _credits[msg.sender] = 0;
        _consumedDividendPerToken[msg.sender] = dividendPerToken;
        sharedBalance -= withdrawableAmount;
        payable(msg.sender).transfer(withdrawableAmount);
    }
}