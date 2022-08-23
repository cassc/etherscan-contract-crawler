// contracts/VowLpExchange.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract VowLpExchange is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    uint256 private _minimumLpAmount;
    uint256 private _bnbAmount;

    event Deposit(address indexed src, uint256 amount);
    event Withdraw(address indexed dest, uint256 amount);
    event DepositToken(address indexed token, address indexed src, uint256 amount);
    event WithdrawToken(address indexed token, address indexed dest, uint256 amount);
    event MinimumUpdated(uint256 amount, uint256 bnb);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(GOVERNOR_ROLE, _msgSender());
        _setMinimum(20 * 10 **18, 10 **16);
    }

    receive() external payable {
        require(msg.value > 0, "!zero");
        emit Deposit(_msgSender(), msg.value);
    }

    /**
     * @notice Function to deposit token
     * @param amount Amount of tokens
     * @param token Address of token to be rescued
     */
    function depositToken(
        uint256 amount, 
        address token
    ) external {
        require (amount >= 0, "!zero");
        require(address(0) != token, "!zero");
        require (IERC20(token).transferFrom(_msgSender(), address(this), amount), "!transfer");
        emit DepositToken(token, _msgSender(), amount);
    }

    /**
     * @notice Function to withdraw ETH
     * Caller is assumed to be governance
     * @param amount Amount of tokens
     */
    function withdrawEth(
        uint256 amount
    ) external onlyRole(GOVERNOR_ROLE) {
        require(amount > 0, "!zero");
        require(payable(_msgSender()).send(amount), "!sent");
        emit Withdraw(_msgSender(), amount);
    }

    /**
     * @notice Function to withdraw token
     * Caller is assumed to be governance
     * @param token Address of token to be rescued
     * @param amount Amount of tokens
     */
    function withdrawToken(
        IERC20 token,
        uint256 amount
    ) external onlyRole(GOVERNOR_ROLE) {
        require(amount > 0, "!zero");
        token.safeTransfer(_msgSender(), amount);
        emit WithdrawToken(address(token), _msgSender(), amount);
    }

    /**
     * @notice Function to setMinimum
     * Owner is assumed to be governance
     * @param token Amount of tokens
     * @param bnb Amount of bnb
     */
    function setMinimum(
        uint256 token,
        uint256 bnb
    ) external onlyRole(GOVERNOR_ROLE) {
        _setMinimum(token, bnb);
    }

    /**
     * @dev Returns the _minimumLpAmount.
     */
    function minimumLpAmount() public view virtual returns (uint256) {
        return _minimumLpAmount;
    }

    /**
     * @dev Returns the bnbAmount.
     */
    function bnbAmount() public view virtual returns (uint256) {
        return _bnbAmount;
    }

    /**
     * @notice Function to setMinimum
     * @param token Amount of tokens
     * @param bnb Amount of bnb
     */
    function _setMinimum(
        uint256 token,
        uint256 bnb
    ) internal {
        if (_minimumLpAmount != token) {
            _minimumLpAmount = token;
        }

        if (_bnbAmount != bnb) {
            _bnbAmount = bnb;
        }

        emit MinimumUpdated(token, bnb);
    }

}