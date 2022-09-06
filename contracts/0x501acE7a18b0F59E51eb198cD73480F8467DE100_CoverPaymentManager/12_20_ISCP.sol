// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ISCPRetainer.sol";
import "./../utils/IGovernable.sol";

/**
 * @title Solace Cover Points (SCP)
 * @author solace.fi
 * @notice **SCP** is a stablecoin pegged to **USD**. It is used to pay for coverage.
 *
 * **SCP** conforms to the ERC20 standard but cannot be minted or transferred by most users. Balances can only be modified by "SCP movers" such as SCP Tellers and coverage contracts. In some cases the user may be able to exchange **SCP** for the payment token, if not the balance will be marked non refundable. Some coverage contracts may have a minimum balance required to prevent abuse - these are called "SCP retainers" and may block [`withdraw()`](#withdraw).
 *
 * [**Governance**](/docs/protocol/governance) can add and remove SCP movers and retainers. SCP movers can modify token balances via [`mint()`](#mint), [`burn()`](#burn), [`transfer()`](#transfer), [`transferFrom()`](#transferfrom), and [`withdraw()`](#withdraw).
 */
interface ISCP is IERC20, IERC20Metadata, ISCPRetainer, IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when the status of an SCP mover is set.
    event ScpMoverStatusSet(address indexed scpMover, bool status);
    /// @notice Emitted when the status of an SCP retainer is set.
    event ScpRetainerStatusSet(address indexed scpRetainer, bool status);

    /***************************************
    ERC20 FUNCTIONS
    ***************************************/

    /**
     * @notice Creates `amount` tokens and assigns them to `account`, increasing the total supply.
     * Requirements:
     * - `account` cannot be the zero address.
     */
    function mint(address account, uint256 amount, bool isRefundable) external;

    /**
     * @notice Destroys `amounts` tokens from `accounts`, reducing the total supply.
     * Requirements:
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burnMultiple(address[] calldata accounts, uint256[] calldata amounts) external;

    /**
     * @notice Destroys `amount` tokens from `account`, reducing the total supply.
     * Requirements:
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burn(address account, uint256 amount) external;

    /**
     * @notice Withdraws funds from an account.
     * @dev Same as burn() except uses refundable amount and checks min scp required.
     * The user must have sufficient refundable balance.
     * @param account The account to withdraw from.
     * @param amount The amount to withdraw.
     */
    function withdraw(address account, uint256 amount) external;

    /***************************************
    MOVER AND RETAINER FUNCTIONS
    ***************************************/

    /// @notice Returns true if `account` has permissions to move balances.
    function isScpMover(address account) external view returns (bool status);
    /// @notice Returns the number of scp movers.
    function scpMoverLength() external view returns (uint256 length);
    /// @notice Returns the scp mover at `index`.
    function scpMoverList(uint256 index) external view returns (address scpMover);

    /// @notice Returns true if `account` may need to retain scp on behalf of a user.
    function isScpRetainer(address account) external view returns (bool status);
    /// @notice Returns the number of scp retainers.
    function scpRetainerLength() external view returns (uint256 length);
    /// @notice Returns the scp retainer at `index`.
    function scpRetainerList(uint256 index) external view returns (address scpRetainer);

    /// @notice The amount of tokens owned by account that cannot be withdrawn.
    function balanceOfNonRefundable(address account) external view returns (uint256);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds or removes a set of scp movers.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param scpMovers List of scp movers to set.
     * @param statuses Statuses to set.
     */
    function setScpMoverStatuses(address[] calldata scpMovers, bool[] calldata statuses) external;

    /**
     * @notice Adds or removes a set of scp retainers.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param scpRetainers List of scp retainers to set.
     * @param statuses Statuses to set.
     */
    function setScpRetainerStatuses(address[] calldata scpRetainers, bool[] calldata statuses) external;
}