// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IMToken.sol";
import "./interfaces/ISupervisor.sol";

abstract contract MTokenStorage is IMToken, Initializable, AccessControl, ReentrancyGuard {
    /**
     * @notice Container for borrow balance information
     * @param principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @param interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);

    uint256 internal constant EXP_SCALE = 1e18;
    bytes32 internal constant FLASH_LOAN_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /**
     * @dev Maximum borrow rate that can ever be applied (.0005% / block)
     */
    uint256 internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @dev Maximum fraction of interest that can be set aside for protocol interest
     */
    uint256 internal constant protocolInterestFactorMaxMantissa = 1e18;

    /**
     * @notice Underlying asset for this MToken
     */
    IERC20 public underlying;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Contract which oversees inter-mToken operations
     */
    ISupervisor public supervisor;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    IInterestRateModel public interestRateModel;

    /**
     * @dev Initial exchange rate used when lending the first MTokens (used when totalTokenSupply = 0)
     */
    uint256 public initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for protocol interest
     */
    uint256 public protocolInterestFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @notice Total amount of protocol interest of the underlying held in this market
     */
    uint256 public totalProtocolInterest;

    /**
     * @dev Total number of tokens in circulation
     */
    uint256 internal totalTokenSupply;

    /**
     * @dev Official record of token balances for each account
     */
    mapping(address => uint256) internal accountTokens;

    /**
     * @dev Approved token transfer amounts on behalf of others
     */
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    /**
     * @dev Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /// @dev Share of market's current underlying  token balance that can be used as flash loan (scaled by 1e18).
    uint256 public maxFlashLoanShare;

    /// @dev Share of flash loan amount that would be taken as fee (scaled by 1e18).
    uint256 public flashLoanFeeShare;
}