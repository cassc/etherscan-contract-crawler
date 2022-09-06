// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC3156FlashBorrower.sol";

struct FlashLenderContract {
    uint256 feePerMillion;
    address wrappedToken;
}

/// @notice this interface is implemented by flash lenders in order to allow flash borrowers to borrow funds
interface IERC3156FlashLender {

     /// @notice The amount of currency available to be lent.
     /// @param token The loan currency.
     /// @return The amount of `token` that can be borrowed.
    function maxFlashLoan(address token) external view returns (uint256);


     /// @notice The fee to be charged for a given loan.
     /// @param token The loan currency.
     /// @param amount The amount of tokens lent.
     /// @return The amount of `token` to be charged for the loan, on top of the returned principal.
    function flashFee(address token, uint256 amount)
        external
        view
        returns (uint256);

    /// @dev Initiate a flash loan.
    /// @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
    /// @param token The loan currency.
    /// @param amount The amount of tokens lent.
    /// @param data Arbitrary data structure, intended to contain user-defined parameters.
    /// @return treus if load was successful
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}