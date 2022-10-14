// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@oz/access/Ownable.sol";
import "@oz/token/ERC20/IERC20.sol";
import "@oz/token/ERC20/ERC20.sol";
import "@oz/security/ReentrancyGuard.sol";
import {IBattleZone} from "./interfaces/IBattleZone.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 */
contract BeepBoop is ERC20, ReentrancyGuard, Ownable {
    IBattleZone public battleZone;

    uint256 public MAX_SUPPLY;
    uint256 public constant MAX_TAX_VALUE = 100;

    uint256 public spendTaxAmount;
    uint256 public withdrawTaxAmount;
    uint256 public reserveTaxAmount;
    address public reserveTaxAddress;

    uint256 public bribesDistributed;
    uint256 public activeTaxCollectedAmount;

    bool public tokenCapSet;

    bool public withdrawTaxCollectionStopped;
    bool public spendTaxCollectionStopped;

    bool public isPaused;
    bool public isDepositPaused;
    bool public isWithdrawPaused;
    bool public isTransferPaused;

    mapping(address => bool) private _isAuthorised;
    address[] public authorisedLog;

    mapping(address => uint256) public depositedAmount;
    mapping(address => uint256) public spentAmount;

    modifier onlyAuthorised() {
        require(_isAuthorised[msg.sender], "Not Authorised");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Transfers paused!");
        _;
    }

    event Withdraw(address indexed userAddress, uint256 amount, uint256 tax);
    event Deposit(address indexed userAddress, uint256 amount);
    event DepositFor(
        address indexed caller,
        address indexed userAddress,
        uint256 amount
    );
    event Spend(
        address indexed caller,
        address indexed userAddress,
        uint256 amount,
        uint256 tax
    );
    event ClaimTax(
        address indexed caller,
        address indexed userAddress,
        uint256 amount
    );
    event ClaimReservedTax(
        address indexed caller,
        address indexed userAddress,
        uint256 amount
    );
    event InternalTransfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    constructor(address battleZone_) ERC20("Beep Boop", "BeepBoop") {
        _isAuthorised[msg.sender] = true;
        isPaused = true;
        isTransferPaused = true;

        withdrawTaxAmount = 30;
        spendTaxAmount = 0;
        reserveTaxAmount = 50;
        reserveTaxAddress = address(0);

        battleZone = IBattleZone(battleZone_);
    }

    /**
     * @dev Returnes current spendable balance of a specific user. This balance can be spent by user for other collections without
     *      withdrawal to ERC-20 token OR can be withdrawn to ERC-20 token.
     */
    function getUserBalance(address user) public view returns (uint256) {
        return (battleZone.getAccumulatedAmount(user) +
            depositedAmount[user] -
            spentAmount[user]);
    }

    /**
     * @dev Function to deposit ERC-20 to the game balance.
     */
    function depositBeepBoop(uint256 amount) public nonReentrant whenNotPaused {
        require(!isDepositPaused, "Deposit Paused");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        _burn(msg.sender, amount);
        depositedAmount[msg.sender] += amount;

        emit Deposit(msg.sender, amount);
    }

    /**
     * @dev Function to withdraw game to ERC-20.
     */
    function withdrawBeepBoop(uint256 amount)
        public
        nonReentrant
        whenNotPaused
    {
        require(!isWithdrawPaused, "Withdraw Paused");
        require(getUserBalance(msg.sender) >= amount, "Insufficient balance");
        uint256 tax = withdrawTaxCollectionStopped
            ? 0
            : (amount * withdrawTaxAmount) / 100;

        spentAmount[msg.sender] += amount;

        if (reserveTaxAmount != 0 && reserveTaxAddress != address(0)) {
            activeTaxCollectedAmount += (tax * (100 - reserveTaxAmount)) / 100;
            _mint(reserveTaxAddress, (tax * reserveTaxAmount) / 100);
        } else {
            activeTaxCollectedAmount += tax;
        }
        _mint(msg.sender, (amount - tax));

        emit Withdraw(msg.sender, amount, tax);
    }

    /**
     * @dev Function to transfer game from one account to another.
     */
    function transferBeepBoop(address to, uint256 amount)
        public
        nonReentrant
        whenNotPaused
    {
        require(!isTransferPaused, "Transfer Paused");
        require(getUserBalance(msg.sender) >= amount, "Insufficient balance");

        spentAmount[msg.sender] += amount;
        depositedAmount[to] += amount;

        emit InternalTransfer(msg.sender, to, amount);
    }

    /**
     * @dev Function to spend user balance. Can be called by other authorised contracts. To be used for internal purchases of other NFTs, etc.
     */
    function spendBeepBoop(address user, uint256 amount)
        external
        onlyAuthorised
        nonReentrant
    {
        require(getUserBalance(user) >= amount, "Insufficient balance");
        uint256 tax = spendTaxCollectionStopped
            ? 0
            : (amount * spendTaxAmount) / 100;

        spentAmount[user] += amount;
        activeTaxCollectedAmount += tax;

        emit Spend(msg.sender, user, amount, tax);
    }

    /**
     * @dev Function to deposit tokens to a user balance. Can be only called by an authorised contracts.
     */
    function depositBeepBoopFor(address user, uint256 amount)
        public
        onlyAuthorised
        nonReentrant
    {
        _depositBeepBoopFor(user, amount);
    }

    /**
     * @dev Function to tokens to the user balances. Can be only called by an authorised users.
     */
    function distributeBeepBoop(address[] memory user, uint256[] memory amount)
        public
        onlyAuthorised
        nonReentrant
    {
        require(user.length == amount.length, "Wrong arrays passed");

        for (uint256 i; i < user.length; i++) {
            _depositBeepBoopFor(user[i], amount[i]);
        }
    }

    function _depositBeepBoopFor(address user, uint256 amount) internal {
        require(user != address(0), "Deposit to 0 address");
        depositedAmount[user] += amount;

        emit DepositFor(msg.sender, user, amount);
    }

    /**
     * @dev Function to mint tokens to a user balance. Can be only called by an authorised contracts.
     */
    function mintFor(address user, uint256 amount)
        external
        onlyAuthorised
        nonReentrant
    {
        if (tokenCapSet) {
            require(
                totalSupply() + amount <= MAX_SUPPLY,
                "You try to mint more than max supply"
            );
        }
        _mint(user, amount);
    }

    /**
     * @dev Function to claim tokens from the tax accumulated pot. Can be only called by an authorised contracts.
     */
    function claimBeepBoopTax(address user, uint256 amount)
        public
        onlyAuthorised
        nonReentrant
    {
        require(activeTaxCollectedAmount >= amount, "Insufficient balance");

        activeTaxCollectedAmount -= amount;
        depositedAmount[user] += amount;
        bribesDistributed += amount;

        emit ClaimTax(msg.sender, user, amount);
    }

    /**
     * @dev Function returns maxSupply set by admin. By default returns error (Max supply is not set).
     */
    function getMaxSupply() public view returns (uint256) {
        require(tokenCapSet, "Max supply is not set");
        return MAX_SUPPLY;
    }

    /*
      ADMIN FUNCTIONS
    */

    /**
     * @dev Function allows admin to set total supply of token.
     */
    function setTokenCap(uint256 tokenCup) public onlyOwner {
        require(
            totalSupply() < tokenCup,
            "Value is smaller than the number of existing tokens"
        );
        require(!tokenCapSet, "Token cap has been already set");

        MAX_SUPPLY = tokenCup;
    }

    /**
     * @dev Function allows admin add authorised address. The function also logs what addresses were authorised for transparancy.
     */
    function authorise(address addressToAuth) public onlyOwner {
        _isAuthorised[addressToAuth] = true;
        authorisedLog.push(addressToAuth);
    }

    /**
     * @dev Function allows admin add unauthorised address.
     */
    function unauthorise(address addressToUnAuth) public onlyOwner {
        _isAuthorised[addressToUnAuth] = false;
    }

    /**
     * @dev Function allows admin update the address of staking address.
     */
    function changeBattleZoneContract(address battleZone_) public onlyOwner {
        battleZone = IBattleZone(battleZone_);
        authorise(battleZone_);
    }

    /**
     * @dev Function allows admin to update limmit of tax on withdraw.
     */
    function updateWithdrawTaxAmount(uint256 _taxAmount) public onlyOwner {
        require(_taxAmount < MAX_TAX_VALUE, "Wrong value passed");
        withdrawTaxAmount = _taxAmount;
    }

    /**
     * @dev Function allows admin to update limmit of tax on reserve.
     */
    function updateReserveTaxAmount(uint256 _taxAmount) public onlyOwner {
        require(_taxAmount < MAX_TAX_VALUE, "Wrong value passed");
        reserveTaxAmount = _taxAmount;
    }

    /**
     * @dev Function allows admin to update limmit of tax on reserve.
     */
    function updateReserveTaxRecipient(address address_) public onlyOwner {
        reserveTaxAddress = address_;
    }

    /**
     * @dev Function allows admin to update tax amount on spend.
     */
    function updateSpendTaxAmount(uint256 _taxAmount) public onlyOwner {
        require(_taxAmount < MAX_TAX_VALUE, "Wrong value passed");
        spendTaxAmount = _taxAmount;
    }

    /**
     * @dev Function allows admin to stop tax collection on withdraw.
     */
    function stopTaxCollectionOnWithdraw(bool _stop) public onlyOwner {
        withdrawTaxCollectionStopped = _stop;
    }

    /**
     * @dev Function allows admin to stop tax collection on spend.
     */
    function stopTaxCollectionOnSpend(bool _stop) public onlyOwner {
        spendTaxCollectionStopped = _stop;
    }

    /**
     * @dev Function allows admin to pause all in game transfactions.
     */
    function pauseGameBeepBoop(bool _pause) public onlyOwner {
        isPaused = _pause;
    }

    /**
     * @dev Function allows admin to pause in game transfers.
     */
    function pauseTransfers(bool _pause) public onlyOwner {
        isTransferPaused = _pause;
    }

    /**
     * @dev Function allows admin to pause in game withdraw.
     */
    function pauseWithdraw(bool _pause) public onlyOwner {
        isWithdrawPaused = _pause;
    }

    /**
     * @dev Function allows admin to pause in game deposit.
     */
    function pauseDeposits(bool _pause) public onlyOwner {
        isDepositPaused = _pause;
    }

    /**
     * @dev Function allows admin to withdraw ETH accidentally dropped to the contract.
     */
    function rescue() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}