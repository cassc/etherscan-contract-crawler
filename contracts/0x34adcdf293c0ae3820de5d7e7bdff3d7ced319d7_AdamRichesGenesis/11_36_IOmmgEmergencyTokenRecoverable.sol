// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgEmergencyTokenRecoverable
/// @author NotAMeme aka nxlogixnick
/// @notice An interface for emergency ERC20 token recovery. This is needed
/// in the case that someone accidentally sent ERC20 tokens to this contract.
interface IOmmgEmergencyTokenRecoverable {
    /// @notice Triggers when ERC20 tokens are recovered
    /// @param token The address of the ERC20 token contract
    /// @param receiver The recipient of the tokens
    /// @param amount the amount of tokens recovered
    event TokensRecovered(
        IERC20 indexed token,
        address indexed receiver,
        uint256 amount
    );

    /// @notice Recovers ERC20 tokens
    /// @param token The address of the ERC20 token contract
    /// @param receiver The recipient of the tokens
    /// @param amount the amount of tokens to recover
    function emergencyRecoverTokens(
        IERC20 token,
        address receiver,
        uint256 amount
    ) external;
}