// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ISync.sol";

import "../wrapper/MyWrapper.sol";


/**
 * @title The magical MyToken token contract.
 * @author int(200/0), slidingpanda
 */
contract MyToken is Context, IERC20, Ownable {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 private _nettoSupply;
    uint256 private _feeReserve;
    uint256 private _gFeeMultiplier;

    struct Accounts {
        uint256 nettoBalance;
        uint256 feeAccountMultiplier;
    }

    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isBlacklisted;

    address payable public wrapper;
    address public daoWallet;
    address public myShareToken;

    address public pegToken;

    uint256 private _fee = 100;
    uint256 private _daoTxnFee = 20;
    uint256 public constant FEE_DIVISOR = 10000;

    uint256 private constant MAX_POOLS = type(uint256).max;
    uint32 public constant REFLOW_PER = 10000;

    address[] public syncAddr;
    mapping(address => bool) public isLP;

    mapping(address => Accounts) private _accounts;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Reflow(uint256 totalSupply, uint256 multiplier, uint256 feeReserve);

    /**
     * Creates a myToken.
	 *
     * @param myName name of the myToken
     * @param mySymbol symbol of the myToken
     * @param myDecimals pegged token decimals
     * @param pegToken_ pegged token
     * @param daoWallet_ dao wallet address
     * @param myShareToken_ dao token address
     */
    constructor(
        string memory myName,
        string memory mySymbol,
        uint8 myDecimals,
        address pegToken_,
        address daoWallet_,
        address myShareToken_
    ) public {
        _name = myName;
        _symbol = mySymbol;
        _decimals = myDecimals;
        pegToken = pegToken_;
        wrapper = payable(msg.sender);
        daoWallet = daoWallet_;
        myShareToken = myShareToken_;
        isWhitelisted[wrapper] = true;
    }

    /**
     * Sets a staking contract for feeless liquidity adding.
	 *
     * @param inAddr address of the staking contract
     * @param toSet whitelist status
     */
    function setWhitelist(address inAddr, bool toSet) external onlyOwner {
        isWhitelisted[inAddr] = toSet;
    }

    /**
     * Rebases liquidity pool.
	 *
     * @param inAddr address of the UniswapV2Pair
     */
    function doSync(address inAddr) public {
        ISync(inAddr).sync();
    }

    /**
     * Synchronizes UniswapV2 pools because they do not do it by themselves with rebase tokens.
     */
    function doAnySync() public {
        _doAnySync();
    }

    /**
     * Returns the number of the sync addresses.
	 *
     * @return uint256 sync address count
     */
    function getSyncAddrLength() public view returns (uint256) {
        return syncAddr.length;
    }

    /**
     * Returns the name of the myToken.
	 *
     * @return string name
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * Returns the symbol of the myToken.
	 *
     * @return string symbol
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * Returns the decimals of the myToken.
	 *
     * @return uint8 decimals
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * Returns the total supply of the myToken.
	 *
     * @return uint256 total supply
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * Returns the netto supply of the myToken.
	 *
     * @return uint256 netto supply
     */
    function nettoSupply() external view returns (uint256) {
        return _nettoSupply;
    }

    /**
     * Returns the myToken balance of a wallet.
	 *
     * @param account account address
     * @return uint256 myToken balance
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * Calculates and returns the myToken balance of a wallet.
	 *
     * @param account account address
     * @return uint256 myToken balance
     */
    function _balanceOf(address account) internal view returns (uint256) {
        uint256 multiplier = _gFeeMultiplier - _accounts[account].feeAccountMultiplier;
        uint256 collectedReflows = (_accounts[account].nettoBalance * multiplier) / REFLOW_PER;

        return _accounts[account].nettoBalance + collectedReflows;
    }

    /**
     * Returns the myToken netto balance of a specific account.
	 *
     * @param account account address
     * @return uint256 myToken netto balance
     */
    function nettoBalanceOf(address account) external view returns (uint256) {
        return _accounts[account].nettoBalance;
    }

    /**
     * Returns the allowance.
	 *
     * @param toAllow toAllow address
     * @param spender spender address
     * @return allowance
     */
    function allowance(address toAllow, address spender) external view override returns (uint256) {
        return _allowances[toAllow][spender];
    }

    /**
     * Approves an amount to be transfered.
	 *
     * @param spender spender address
     * @param amount approve amount
     * @return bool 'true' if not reverted
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    /**
     * Approves an amount to be transfered.
	 *
     * @param toAllow toAllow address
     * @param spender spender address
     * @param amount approve amount
     */
    function _approve(address toAllow, address spender, uint256 amount) private {
        require(toAllow != address(0), "_approve: approve from the zero address");
        require(spender != address(0), "_approve: approve to the zero address");

        _allowances[toAllow][spender] = amount;

        emit Approval(toAllow, spender, amount);
    }

    /**
     * Increases the allowance.
	 *
     * @param spender spender address
     * @param addedValue added value
     * @return bool 'true' if not reverted
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );

        return true;
    }

    /**
     * Decreases the allowance.
	 *
     * @param spender spender address
     * @param subtractedValue subtracted value
     * @return bool 'true' if not reverted
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(_allowances[_msgSender()][spender] >= subtractedValue, "decreaseAllowance: decreased allowance below zero");

        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );

        return true;
    }

    /**
     * Calls the function which checks which type of transaction should happen.
	 *
     * @param sender spender address
     * @param recipient recipient address
     * @param amount transfer amount
     * @return bool 'true' if not reverted
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "transferFrom: transfer amount exceeds allowance");

        _interTransfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );

        return true;
    }

    /**
     * Calls the function which checks which type of transaction should happen.

     * @param recipient recipient address
     * @param amount token amount
     * @return bool 'true' if not reverted
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _interTransfer(_msgSender(), recipient, amount);

        return true;
    }

    /**
     * Checks if the transfer is feeless or with fees.
	 *
     * @param sender spender address
     * @param recipient recipient address
     * @param amount token amount
     */
    function _interTransfer(address sender, address recipient, uint256 amount) internal {
        require(amount > 0, "_interTransfer: Transfer amount must be greater than zero");
        require(_balanceOf(sender) >= amount, "_interTransfer: transfer amount exceeds balance");

        if (isWhitelisted[sender] || isWhitelisted[recipient]) {
            _doTransferFeeless(sender, recipient, amount);
        } else {
            _doTransfer(sender, recipient, amount);
        }
    }

    /**
     * Transfers an amount from a sender to a recipient.
	 *
     * @notice Users can reduce the fee by holding myShare tokens or by paying with myShare tokens.
     *         - fee * 1.0 by doing nothing
     *         - fee * 0.9 by holding myShare tokens
     *         - fee * 0.5 by reducing the fee on the reducer
     * @param sender spender address
     * @param recipient recipient address
     * @param amount transfer amount
     */
    function _doTransfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "_doTransfer: transfer from the zero address");
        require(recipient != address(0), "_doTransfer: transfer to the zero address");
        require(isBlacklisted[recipient] == false, "_doTransfer: This address is blacklisted");
        require(isBlacklisted[sender] == false, "_doTransfer: This address is blacklisted");

        uint256 toReserve = ((amount * _fee) / FEE_DIVISOR);
        uint256 toDao = ((amount * _daoTxnFee) / FEE_DIVISOR);

        uint256 feeMultiplier = 10;

        if (isLP[sender] == false) {
            (feeMultiplier, ) = MyWrapper(wrapper).userFee(sender);
        } else {
            (feeMultiplier, ) = MyWrapper(wrapper).userFee(recipient);
        }

        toReserve = (toReserve * feeMultiplier) / 10;
        toDao = (toDao * feeMultiplier) / 10;

        uint256 afterFee = amount - toReserve - toDao;

        _feeReserve += toReserve;

        _subFromBalance(amount, sender);
        _addToBalance(toDao, daoWallet);
        _addToBalance(afterFee, recipient);

        emit Transfer(sender, daoWallet, toDao);
        emit Transfer(sender, recipient, afterFee);
    }

    /**
     * Transfers an amount from a sender to a recipient with no fees.
	 *
     * @param sender spender address
     * @param recipient recipient address
     * @param amount transfer amount
     */
    function _doTransferFeeless(address sender, address recipient, uint256 amount) private {
        _subFromBalance(amount, sender);
        _addToBalance(amount, recipient);

        emit Transfer(sender, recipient, amount);
    }

    /**
     * Adds an amount to a wallet balance.
	 *
     * @param amount amount
     * @param to wallet address
     */
    function _addToBalance(uint256 amount, address to) internal {
        _nettoSupply -= _accounts[to].nettoBalance / REFLOW_PER;

        _accounts[to].nettoBalance = _balanceOf(to);
        _accounts[to].feeAccountMultiplier = _gFeeMultiplier;
        _accounts[to].nettoBalance += amount;

        _nettoSupply += _accounts[to].nettoBalance / REFLOW_PER;
    }

    /**
     * Adds an amount to a wallet balance.
	 *
     * @param amount amount
     * @param from wallet address
     */
    function _subFromBalance(uint256 amount, address from) internal {
        _nettoSupply -= _accounts[from].nettoBalance / REFLOW_PER;

        _accounts[from].nettoBalance = _balanceOf(from);
        _accounts[from].feeAccountMultiplier = _gFeeMultiplier;

        _accounts[from].nettoBalance -= amount;

        _nettoSupply += _accounts[from].nettoBalance / REFLOW_PER;
    }

    /**
     * Blacklists an account and puts the account balance into the fee reserve to prevent a dead wallet collecting fees.
	 *
     * @param account account address
     * @return bool is blacklisted
     */
    function blacklistAccount(address account) external onlyOwner returns (bool) {
        _addToBalance(0, account);
        uint256 toReserve = balanceOf(account);

        _subFromBalance(toReserve, account);
        _feeReserve += toReserve;

        isBlacklisted[account] = true;

        return isBlacklisted[account];
    }

    /**
     * Returns the fee account multiplier for a specific account.
	 *
     * @param account account address
     * @return uint256 fee account multiplier
     */
    function getMultiplierOf(address account) external view returns (uint256) {
        return _accounts[account].feeAccountMultiplier;
    }

    /**
     * Getter for _gFeeMultiplier.
	 *
     * @return uint256 global fee multiplier
     */
    function globalMultiplier() external view returns (uint256) {
        return _gFeeMultiplier;
    }

    /**
     * Getter for _fee gives back the txn fee excluded daoFee.
	 *
     * @return uint256 fee
     */
    function getReflowTxnFee() external view returns (uint256) {
        return _fee;
    }

    /**
     * Getter for _daoTxnFee gives back the daoFee fee excluded txn fee.
	 *
     * @return uint256 dao transaction fee
     */
    function getDaoTxFee() external view returns (uint256) {
        return _daoTxnFee;
    }

    /**
     * Getter for gives back fee that have to be paid.
	 *
     * @return uint256 fee + dao fee
     */
    function txnFee() external view returns (uint256) {
        return _fee + _daoTxnFee;
    }

    /**
     * Returns the actual fees.
	 *
     * @return uint256 fee divisor
	 * @return uint256 actual fees
     */
    function getActualFees() external view returns (uint256, uint256) {
        return (FEE_DIVISOR, _fee + _daoTxnFee);
    }

    /**
     * Getter for _feeReserve.
	 *
     */
    function feeReserve() external view returns (uint256) {
        return _feeReserve;
    }

    /**
     * Setter for _fee.
	 *
     * @param fee tx fee
     */
    function setReflowFees(uint16 fee) external onlyOwner {
        require(fee <= 100, "Too high fees set (max 10% (uint 100))");

        _fee = fee;
    }

    /**
     * Setter for _daoTxnFee.
	 *
     * @param fee tx dao fee
     */
    function setDaoTxFee(uint16 fee) external onlyOwner {
        require(fee <= 100, "Too high fees set (max 10% (uint 100))");

        _daoTxnFee = fee;
    }

    /**
     * Setter for daoWallet.
	 *
     * @param to dao wallet address
     */
    function setDaoWallet(address to) external onlyOwner {
        daoWallet = to;
    }

    /**
     * Setter for wrapper.
	 *
     * @param newWrapper wrapper address
     * @return bool 'true' if not reverted
     */
    function setWrapper(address newWrapper) external onlyOwner returns (bool) {
        wrapper = payable(newWrapper);

        return true;
    }

    /**
     * Compounds wallet with reflow.
	 *
     * @param account account address
     */
    function compoundWallet(address account) external {
        _reflow();
        _addToBalance(0, account);
    }

    /**
     * Does reflow.
     */
    function doReflow() external {
        _reflow();
    }

    /**
     * Fountains an amount.
	 *
     * @param amount fountain amount
     */
    function fountain(uint256 amount) external {
        require(_balanceOf(msg.sender) >= amount, "Transfer amount exceeds balance");

        _subFromBalance(amount, msg.sender);
        _feeReserve += amount;
    }

    /**
     * Fountains an amount.
	 *
     * @param amount fountain amount
     */
    function fountainWrapper(uint256 amount, address user) external {
        require(msg.sender == wrapper, "Only wrapper can call this function");

        _subFromBalance(amount, user);
        _feeReserve += amount;
    }

    /**
     * Mints a specific amount of tokens.
	 *
     * @param to recipient address
     * @param amount mint amount
     */
    function mint(address to, uint256 amount) external {
        require(amount > 0, "Mint amount must be greater than zero");
        require(wrapper == msg.sender, "Caller is not the wrapper");

        _reflow();
        _mint(to, amount);
    }

    /**
     * Mints tokens, triggers the global reflow and puts fees into the dao wallet.
	 *
     * @param account recipient address
     * @param amount mint amount
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");

        _addToBalance(amount, account);

        _totalSupply += amount;

        emit Transfer(address(0), account, amount);
    }

    /**
     * Triggers the global reflow and burns a specific amount of tokens.
	 *
     * @param to account address
     * @param amount burn amount
	 * @return uint256 burnt amount
     */
    function burn(address to, uint256 amount) external returns (uint256) {
        require(wrapper == msg.sender, "Caller is not the wrapper");
        require(amount > 0, "Burn amount must be greater than zero");

        return _burn(to, amount);
    }

    /**
     * Burns tokens.
	 *
     * @param account account address
     * @param amount burn amount
	 * @return uint256 burnt amount
     */
    function _burn(address account, uint256 amount) private returns (uint256) {
        require(account != address(0), "Burn from the zero address");
        require(balanceOf(account) >= amount,"Burn amount exceeds balance");

        _subFromBalance(amount, account);
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _reflow();

        return amount;
    }

    /**
     * Does reflow and syncs the liquidity pools.
     */
    function _reflow() private {
        if (_feeReserve > _nettoSupply) {
            uint256 multiplier = _feeReserve / _nettoSupply;
            uint256 modRes = _feeReserve % _nettoSupply;
            _feeReserve = modRes;
            _gFeeMultiplier += multiplier;

            _doAnySync();

            emit Reflow(_totalSupply, multiplier, _feeReserve);
        }
    }

    /**
     * Does sync over all sync addresses.
     */
    function _doAnySync() internal {
        for (uint256 i = 0; i < syncAddr.length; i++) {
            ISync(syncAddr[i]).sync();
        }
    }

    /**
     * Finds an address index with a given address.
	 *
     * @param inAddr account address
     * @return uint256 address index
     */
    function _findAddr(address inAddr) internal view returns (uint256) {
        uint256 addressIndex = MAX_POOLS;

        for (uint256 i = 0; i < syncAddr.length; i++) {
            if (syncAddr[i] == inAddr) {
                addressIndex = i;
            }
        }

        return addressIndex;
    }

    /**
     * Finds an address index with a given address.
	 *
     * @param inAddr account address
     * @return uint256 address index
     */
    function findAddr(address inAddr) external view returns (uint256) {
        uint256 addressIndex = _findAddr(inAddr);

        return addressIndex;
    }

    /**
     * Removes an index of the sync addresses.
	 *
     * @param index index
     * @return bool 'true' if not reverted
     */
    function removeIndex(uint256 index) public onlyOwner returns (bool) {
        require(index <= syncAddr.length, "Index out of range.");
        require(syncAddr.length >= 1, "Array has too few elements.");

        isLP[syncAddr[index]] = false;
        syncAddr[index] = syncAddr[syncAddr.length - 1];
        syncAddr.pop();

        return true;
    }

    /**
     * Removes an address from the sync addresses.
	 *
     * @param inAddr account address
     * @return bool
     */
    function removeAddress(address inAddr) public onlyOwner returns (bool) {
        uint256 index = _findAddr(inAddr);

        if (index != MAX_POOLS) {
            return removeIndex(index);
        } else {
            return false;
        }
    }

    /**
     * Adds a sync address.
	 *
     * @param inAddr account address
     * @return bool
     */
    function addSyncAddr(address inAddr) public returns (bool) {
        require(msg.sender == owner() || msg.sender == wrapper, "You are not allowed to add sync addresses");
        require(syncAddr.length <= MAX_POOLS - 1, "Too many addresses to sync");

        if (syncAddr.length != 0) {
            if (isLP[inAddr] == false) {
                isLP[inAddr] = true;
                syncAddr.push(inAddr);

                return true;
            } else {
                return false;
            }
        } else {
            isLP[inAddr] = true;
            syncAddr.push(inAddr);

            return true;
        }
    }

    /**
     * Withdraws ERC20 tokens from the contract.
	 * This contract should not be the owner of any other token.
	 *
     * @param tokenAddr address of the IERC20 token
     * @param to address of the recipient
     */
    function withdrawERC(address tokenAddr, address to) external onlyOwner {
        IERC20(tokenAddr).transfer(to, IERC20(tokenAddr).balanceOf(address(this)));
    }

    /**
     * Gives the owner the possibility to withdraw ETH which are airdroped or send by mistake to this contract.
	 *
     * @param to recipient of the tokens
     */
    function daoWithdrawETH(address to) external onlyOwner {
        (bool sent,) = to.call{value: address(this).balance}("");
		
        require(sent, "Failed to send ETH");
    }

    /**
     * Hook that is called before any transfer of tokens which includes minting and burning.
	 *
     * @param from from address
     * @param to to address
     * @param amount transfer amount
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        // ...
    }
}