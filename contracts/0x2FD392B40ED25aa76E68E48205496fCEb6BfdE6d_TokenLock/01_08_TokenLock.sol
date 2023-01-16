// Copyright © 2022, TXA PTE. LTD. All rights reserved.
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "./ERC777Recipient.sol";
import "./IAcceptsDeposit.sol";

/**
 * Allows token holders to lock an ERC777 token for pre-staking.
 * Depositors send a specified token to this contract in order to stake.
 */
contract TokenLock is ERC777Recipient, IAcceptsDeposit {
    /**
     * Interface to token approved for deposits.
     */
    IERC20 public immutable depositToken;

    /**
     * Timestamp for date after which deposits no longer accepted
     */
    uint256 public immutable depositEndTime;

    /**
     * Timestamp for date after which prestaked tokens can be withdrawn
     */
    uint256 public immutable withdrawUnlockTime;

    /**
     * Minimum amount of token that must be deposited
     */
    uint256 public immutable minimumDeposit;

    /**
     * Address of contract that can migrate deposits to this contract
     */
    address public immutable migrator;

    /**
     * Address with tokens that are burnt each time a deposit happens
     */
    address public immutable burner;

    /**
     * Maps depositor address to amount of depositToken staked
     */
    mapping(address => uint256) public depositorBalance;

    /**
     * Emitted when a new deposit is made to the contract
     */
    event TokensLocked(address depositor, uint256 amount);

    /**
     * Sets up parameters for prestaking

     * @param _depositToken Address of token accepted as deposit

     * @param _depositEndTime Timestamp at which deposits no longer accepted

     * @param _withdrawUnlockTime Timestamp at which deposited tokens can be withdrawn

     * @param _minimumDeposit Minimum amount of tokens that depositor must stake to qualify
     */
    constructor(
        address _depositToken,
        uint256 _depositEndTime,
        uint256 _withdrawUnlockTime,
        uint256 _minimumDeposit,
        address _migrator,
        address _burner
    ) {
        depositToken = IERC20(_depositToken);
        depositEndTime = _depositEndTime;
        withdrawUnlockTime = _withdrawUnlockTime;
        minimumDeposit = _minimumDeposit;
        migrator = _migrator;
        burner = _burner;
    }

    /**
     * Called by the ERC777 contract when tokens are sent to this contract.
     * Depositors call the token contract to send tokens here to stake.
     * Ignores any transfers from the migrator contract, as those are handled
     * in `migrateDeposit`
     *
     * Records number of tokens sent by a depositor.
     * Rejects any ERC777 token other than the deposit token.
     * Rejects deposits after the deposit period ends.
     * Rejects deposits below a minimum amount.
     */
    function tokensReceived(
        address,
        address from,
        address,
        uint256 amount,
        bytes calldata,
        bytes calldata
    ) external override {
        if (from != migrator) {
            require(msg.sender == address(depositToken), "INVALID_TOKEN");
            require(block.timestamp < depositEndTime, "DEPOSIT_TIMEOUT");
            depositorBalance[from] += amount;
            require(depositorBalance[from] >= minimumDeposit, "BELOW_MINIMUM");
            IERC777(address(depositToken)).operatorBurn(burner, amount, "", "");
            emit TokensLocked(from, amount);
        }
    }

    /**
     * Called by depositor to withdraw staked tokens.
     *
     * Forbids withdrawing before unlock time has passed.
     * Prevents this contract from holding depositor's tokens
     * forever in the case that a migration contract is not added, or
     * if depositors choose not to migrate.
     */
    function withdraw(uint256 amount) external {
        require(block.timestamp >= withdrawUnlockTime, "WITHDRAW_LOCKED");
        require(depositorBalance[msg.sender] >= amount, "INSUFFICIENT_FUNDS");
        depositorBalance[msg.sender] -= amount;
        require(depositToken.transfer(msg.sender, amount), "TRANSFER_FAILED");
    }

    /**
     * Called by migrator contract to transfer a deposit to this contract
     */
    function migrateDeposit(address depositor, uint256 amount)
        external
        override
        returns (bool)
    {
        require(msg.sender == migrator, "CALLER_MUST_BE_MIGRATOR");
        require(block.timestamp < depositEndTime, "DEPOSIT_TIMEOUT");
        require(
            IERC20(depositToken).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "TRANSFER_FROM_FAILED"
        );
        depositorBalance[depositor] += amount;
        require(depositorBalance[depositor] >= minimumDeposit, "BELOW_MINIMUM");
        IERC777(address(depositToken)).operatorBurn(burner, amount, "", "");
        emit TokensLocked(depositor, amount);
        return true;
    }

    /**
     * Unsupported, always returns false
     */
    function migrateVirtualBalance(address depositor, uint256 amount)
        external
        override
        returns (bool)
    {
        return false;
    }

    function getMigratorAddress() external view override returns (address) {
        return migrator;
    }
}