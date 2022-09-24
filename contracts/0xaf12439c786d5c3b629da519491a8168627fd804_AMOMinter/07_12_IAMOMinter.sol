// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAMO.sol";

/// @title IAMO
/// @author Angle Core Team
/// @notice Interface for the `AMOMinter` contracts
/// @dev This interface only contains functions of the `AMOMinter` contract which need to be accessible
/// by other contracts of the protocol
interface IAMOMinter {
    /// @notice View function returning true if `admin` is the governor
    function isGovernor(address admin) external view returns (bool);

    /// @notice Checks whether an address is approved for `msg.sender` where `msg.sender`
    /// is expected to be an AMO
    function isApproved(address admin) external view returns (bool);

    /// @notice View function returning current token debt for the msg.sender
    /// @dev Only AMOs are expected to call this function
    function callerDebt(IERC20 token) external view returns (uint256);

    /// @notice View function returning current token debt for an amo
    function amoDebts(IAMO amo, IERC20 token) external view returns (uint256);

    /// @notice Sends tokens to be processed by an AMO
    /// @param amo Address of the AMO to transfer funds to
    /// @param tokens Addresses of tokens we want to mint/transfer to the AMO
    /// @param isStablecoin Boolean array giving the info whether we should mint or transfer the tokens
    /// @param amounts Amounts of tokens to be minted/transferred to the AMO
    /// @param data List of bytes giving additional information when depositing
    /// @dev Only an approved address for the `amo` can call this function
    /// @dev This function will mint if it is called for an agToken
    function sendToAMO(
        IAMO amo,
        IERC20[] memory tokens,
        bool[] memory isStablecoin,
        uint256[] memory amounts,
        bytes[] memory data
    ) external;

    /// @notice Pulls tokens from an AMO
    /// @param amo Address of the amo to receive funds from
    /// @param tokens Addresses of each tokens we want to burn/transfer from the AMO
    /// @param isStablecoin Boolean array giving the info on whether we should burn or transfer the tokens
    /// @param amounts Amounts of each tokens we want to burn/transfer from the amo
    /// @param data List of bytes giving additional information when withdrawing
    function receiveFromAMO(
        IAMO amo,
        IERC20[] memory tokens,
        bool[] memory isStablecoin,
        uint256[] memory amounts,
        address[] memory to,
        bytes[] memory data
    ) external;
}