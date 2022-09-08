/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/migration/MigrationTool.sol
*/
            
pragma solidity >=0.5.0;

/// @title  IERC20Metadata
/// @author Alchemix Finance
interface IERC20Metadata {
    /// @notice Gets the name of the token.
    ///
    /// @return The name.
    function name() external view returns (string memory);

    /// @notice Gets the symbol of the token.
    ///
    /// @return The symbol.
    function symbol() external view returns (string memory);

    /// @notice Gets the number of decimals that the token has.
    ///
    /// @return The number of decimals.
    function decimals() external view returns (uint8);
}


/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/migration/MigrationTool.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/migration/MigrationTool.sol
*/
            
pragma solidity >=0.5.0;

////import "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

////import "../IERC20Metadata.sol";

/// @title IWETH9
interface IWETH9 is IERC20, IERC20Metadata {
  /// @notice Deposits `msg.value` ethereum into the contract and mints `msg.value` tokens.
  function deposit() external payable;

  /// @notice Burns `amount` tokens to retrieve `amount` ethereum from the contract.
  ///
  /// @dev This version of WETH utilizes the `transfer` function which hard codes the amount of gas
  ///      that is allowed to be utilized to be exactly 2300 when receiving ethereum.
  ///
  /// @param amount The amount of tokens to burn.
  function withdraw(uint256 amount) external;
}