// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {WrappedRebaseTokenErrors} from "./libraries/Errors.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {WadRayMath} from "./libraries/WadRayMath.sol";

contract WrappedRebaseToken is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;

    IERC20 private immutable _rebaseToken;

    /**
     * Sets the underlyingToken, name, and symbol variables variables
     * @param rebaseToken The rebase token that this contract wraps around
     * @param name The name of the Wrapped Rebase Token; will be passed into the ERC20 constructor
     * @param symbol The symbol of the Wrapped Rebase Token; will be passed into the ERC20 constructor
     *
     */
    constructor(IERC20 rebaseToken, string memory name, string memory symbol) ERC20(name, symbol) {
        if (address(rebaseToken) == address(0)) {
            revert WrappedRebaseTokenErrors.CONSTRUCTOR_ARGUMENT_CANNOT_BE_ADDRESS_ZERO();
        }
        _rebaseToken = rebaseToken;
    }

    /**
     * Deposits a depositAmount of a user's IERC20 token to this address and mints wrappedToken to a user
     * @notice requires approval of depositAmount on the rebase token before calling
     * @param depositAmount The amount of tokens to wrap
     * @return mintAmount The amount of wrapped rebase tokens minted for the requested depositAmount
     * @dev requires prior rebase token approval of deposit amount from the wrapped token contract
     */
    function deposit(uint256 depositAmount) external nonReentrant returns (uint256 mintAmount) {
        if (depositAmount == 0) {
            revert WrappedRebaseTokenErrors.CANNOT_DEPOSIT_ZERO_TOKENS();
        }
        uint256 beforeBalance = _rebaseToken.balanceOf(address(this));
        _rebaseToken.safeTransferFrom(msg.sender, address(this), depositAmount);
        uint256 actualTransfer = _rebaseToken.balanceOf(address(this)) - beforeBalance;

        if (beforeBalance == 0) {
            mintAmount = actualTransfer;
        } else {
            mintAmount = totalSupply().rayDiv(beforeBalance).rayMul(actualTransfer);
        }

        _mint(msg.sender, mintAmount);
    }

    /**
     * Withdraws a given amount of the wrapped token, calculates how much to send, and sends the unwrapped amount it to the user
     *  @param withdrawAmount The amount of wrapped rebase tokens to unwrap
     * @return unwrappedTokens The amount of unwrapped rebase tokens sent to the user
     */
    function withdraw(uint256 withdrawAmount) external returns (uint256 unwrappedTokens) {
        if (balanceOf(msg.sender) < withdrawAmount) {
            revert WrappedRebaseTokenErrors.UNWRAP_AMOUNT_EXCEEDS_BALANCE();
        }
        if (withdrawAmount == 0) {
            revert WrappedRebaseTokenErrors.CANNOT_WITHDRAW_ZERO_TOKENS();
        }
        unwrappedTokens = _rebaseToken.balanceOf(address(this)).rayDiv(totalSupply()).rayMul(withdrawAmount);

        _burn(msg.sender, withdrawAmount);
        _rebaseToken.safeTransfer(msg.sender, unwrappedTokens);
    }
}