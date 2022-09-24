// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IAMO
/// @author Angle Core Team
/// @notice Interface for the `AMO` contracts
/// @dev This interface only contains functions of the `AMO` contracts which need to be accessible to other
/// contracts of the protocol
interface IAMO {
    // ================================ Views ======================================

    /// @notice Helper function to access the current net balance for a particular token
    /// @param token Address of the token to look for
    /// @return Actualised value owned by the contract
    function balance(IERC20 token) external view returns (uint256);

    /// @notice Helper function to access the current debt owed to the AMOMinter
    /// @param token Address of the token to look for
    function debt(IERC20 token) external view returns (uint256);

    /// @notice Gets the current value in `token` of the assets managed by the AMO corresponding to `token`,
    /// excluding the loose balance of `token`
    /// @dev In the case of a lending AMO, the liabilities correspond to the amount borrowed by the AMO
    /// @dev `token` is used in the case where one contract handles mutiple AMOs
    function getNavOfInvestedAssets(IERC20 token) external view returns (uint256);

    // ========================== Restricted Functions =============================

    /// @notice Pulls the gains made by the protocol on its strategies
    /// @param token Address of the token to getch gain for
    /// @param to Address to which tokens should be sent
    /// @param data List of bytes giving additional information when withdrawing
    /// @dev This function cannot transfer more than the gains made by the protocol
    function pushSurplus(
        IERC20 token,
        address to,
        bytes[] memory data
    ) external;

    /// @notice Claims earned rewards by the protocol
    /// @dev In some protocols like Aave, the AMO may be earning rewards, it thus needs a function
    /// to claim it
    function claimRewards(IERC20[] memory tokens) external;

    /// @notice Swaps earned tokens through `1Inch`
    /// @param minAmountOut Minimum amount of `want` to receive for the swap to happen
    /// @param payload Bytes needed for 1Inch API
    /// @dev This function can for instance be used to sell the stkAAVE rewards accumulated by an AMO
    function sellRewards(uint256 minAmountOut, bytes memory payload) external;

    /// @notice Changes allowance for a contract
    /// @param tokens Addresses of the tokens for which approvals should be madee
    /// @param spenders Addresses to approve
    /// @param amounts Approval amounts for each address
    function changeAllowance(
        IERC20[] calldata tokens,
        address[] calldata spenders,
        uint256[] calldata amounts
    ) external;

    /// @notice Recovers any ERC20 token
    /// @dev Can be used for instance to withdraw stkAave or Aave tokens made by the protocol
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 amountToRecover
    ) external;

    // ========================== Only AMOMinter Functions =========================

    /// @notice Withdraws invested funds to make it available to the `AMOMinter`
    /// @param tokens Addresses of the token to be withdrawn
    /// @param amounts Amounts of `token` wanted to be withdrawn
    /// @param data List of bytes giving additional information when withdrawing
    /// @return amountsAvailable Idle amounts in each token at the end of the call
    /// @dev Caller should make sure that for each token the associated amount can be withdrawn
    /// otherwise the call will revert
    function pull(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes[] memory data
    ) external returns (uint256[] memory);

    /// @notice Notify that stablecoins has been minted to the contract
    /// @param tokens Addresses of the token transferred
    /// @param amounts Amounts of the tokens transferred
    /// @param data List of bytes giving additional information when depositing
    function push(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes[] memory data
    ) external;

    /// @notice Changes the reference to the `AMOMinter`
    /// @param amoMinter_ Address of the new `AMOMinter`
    /// @dev All checks are performed in the parent contract
    function setAMOMinter(address amoMinter_) external;

    /// @notice Lets the AMO contract acknowledge support for a new token
    /// @param token Token to add support for
    function setToken(IERC20 token) external;

    /// @notice Removes support for a token
    /// @param token Token to remove support for
    function removeToken(IERC20 token) external;
}