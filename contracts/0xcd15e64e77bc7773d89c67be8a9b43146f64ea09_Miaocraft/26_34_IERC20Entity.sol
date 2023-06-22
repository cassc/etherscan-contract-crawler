// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/Interfaces/IERC1363.sol";

/// @title ERC20 with entity-based ownership and allowances.
/// @author boffee
/// @author Modified from openzeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol)
interface IERC20Entity is IERC1363 {
    /**
     * @dev Emitted when `value` tokens are moved from one entity (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event EntityTransfer(
        uint256 indexed from,
        uint256 indexed to,
        uint256 value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event EntityApproval(
        uint256 indexed owner,
        uint256 indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens owned by `entity`.
     */
    function balanceOf(uint256 entity) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's entity to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {EntityTransfer} event.
     */
    function transfer(uint256 to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(uint256 owner, uint256 spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(uint256 spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {EntityTransfer} event.
     */
    function transferFrom(
        uint256 from,
        uint256 to,
        uint256 amount
    ) external returns (bool);
}