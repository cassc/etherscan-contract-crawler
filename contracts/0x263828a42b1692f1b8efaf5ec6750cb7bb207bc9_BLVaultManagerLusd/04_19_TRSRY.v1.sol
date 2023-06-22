// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import "src/Kernel.sol";

/// @notice Treasury holds all other assets under the control of the protocol.
abstract contract TRSRYv1 is Module {
    // =========  EVENTS ========= //

    event IncreaseWithdrawApproval(
        address indexed withdrawer_,
        ERC20 indexed token_,
        uint256 newAmount_
    );
    event DecreaseWithdrawApproval(
        address indexed withdrawer_,
        ERC20 indexed token_,
        uint256 newAmount_
    );
    event Withdrawal(
        address indexed policy_,
        address indexed withdrawer_,
        ERC20 indexed token_,
        uint256 amount_
    );
    event IncreaseDebtorApproval(address indexed debtor_, ERC20 indexed token_, uint256 newAmount_);
    event DecreaseDebtorApproval(address indexed debtor_, ERC20 indexed token_, uint256 newAmount_);
    event DebtIncurred(ERC20 indexed token_, address indexed policy_, uint256 amount_);
    event DebtRepaid(ERC20 indexed token_, address indexed policy_, uint256 amount_);
    event DebtSet(ERC20 indexed token_, address indexed policy_, uint256 amount_);

    // =========  ERRORS ========= //

    error TRSRY_NoDebtOutstanding();
    error TRSRY_NotActive();

    // =========  STATE ========= //

    /// @notice Status of the treasury. If false, no withdrawals or debt can be incurred.
    bool public active;

    /// @notice Mapping of who is approved for withdrawal.
    /// @dev    withdrawer -> token -> amount. Infinite approval is max(uint256).
    mapping(address => mapping(ERC20 => uint256)) public withdrawApproval;

    /// @notice Mapping of who is approved to incur debt.
    /// @dev    debtor -> token -> amount. Infinite approval is max(uint256).
    mapping(address => mapping(ERC20 => uint256)) public debtApproval;

    /// @notice Total debt for token across all withdrawals.
    mapping(ERC20 => uint256) public totalDebt;

    /// @notice Debt for particular token and debtor address
    mapping(ERC20 => mapping(address => uint256)) public reserveDebt;

    // =========  FUNCTIONS ========= //

    modifier onlyWhileActive() {
        if (!active) revert TRSRY_NotActive();
        _;
    }

    /// @notice Increase approval for specific withdrawer addresses
    function increaseWithdrawApproval(
        address withdrawer_,
        ERC20 token_,
        uint256 amount_
    ) external virtual;

    /// @notice Decrease approval for specific withdrawer addresses
    function decreaseWithdrawApproval(
        address withdrawer_,
        ERC20 token_,
        uint256 amount_
    ) external virtual;

    /// @notice Allow withdrawal of reserve funds from pre-approved addresses.
    function withdrawReserves(address to_, ERC20 token_, uint256 amount_) external virtual;

    /// @notice Increase approval for someone to accrue debt in order to withdraw reserves.
    /// @dev    Debt will generally be taken by contracts to allocate treasury funds in yield sources.
    function increaseDebtorApproval(
        address debtor_,
        ERC20 token_,
        uint256 amount_
    ) external virtual;

    /// @notice Decrease approval for someone to withdraw reserves as debt.
    function decreaseDebtorApproval(
        address debtor_,
        ERC20 token_,
        uint256 amount_
    ) external virtual;

    /// @notice Pre-approved policies can get a loan to perform operations with treasury assets.
    function incurDebt(ERC20 token_, uint256 amount_) external virtual;

    /// @notice Repay a debtor debt.
    /// @dev    Only confirmed to safely handle standard and non-standard ERC20s.
    /// @dev    Can have unforeseen consequences with ERC777. Be careful with ERC777 as reserve.
    function repayDebt(address debtor_, ERC20 token_, uint256 amount_) external virtual;

    /// @notice An escape hatch for setting debt in special cases, like swapping reserves to another token.
    function setDebt(address debtor_, ERC20 token_, uint256 amount_) external virtual;

    /// @notice Get total balance of assets inside the treasury + any debt taken out against those assets.
    function getReserveBalance(ERC20 token_) external view virtual returns (uint256);

    /// @notice Emergency shutdown of withdrawals.
    function deactivate() external virtual;

    /// @notice Re-activate withdrawals after shutdown.
    function activate() external virtual;
}