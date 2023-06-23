/*
 * Copyright ©️ 2021 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2021 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ERC20Wrapper is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @dev Returns the address of underlying ERC20.
     */
    IERC20 public underlyingERC20;

    /**
     * @dev Returns the wrapped/underlying token ratio.
     */
    uint256 public ratio; // 1e18 = 1:1

    uint8 private _decimals;

    
    event  Deposit(address indexed user, uint256 underlyingAmount, uint256 amount);
    event  Withdrawal(address indexed user, uint256 underlyingAmount, uint256 amount);
    

    constructor(
        IERC20 underlyingERC20_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 ratio_
    ) ERC20(name_, symbol_) {
        require(address(underlyingERC20_) != address(0), "ERC20Wrapper: underlyingERC20_ cannot be zero");
        require(ratio_ > 0, "ERC20Wrapper: ratio_ cannot be zero");

        underlyingERC20 = underlyingERC20_;
        _decimals = decimals_;
        ratio = ratio_;
    }


    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the amount of underlying tokens calculated based on amount of wrapped tokens.
     */
    function underlyingAssetAmount(uint256 wrappedAmount) public view virtual returns (uint256) {
        return wrappedAmount * 1e18 / ratio;
    }

    /**
     * @dev Returns the amount of wrapped tokens calculated based on amount of underlying tokens.
     */
    function wrappedAssetAmount(uint256 underlyingAmount) public view virtual returns (uint256) {
        return underlyingAmount * ratio / 1e18;
    }


    /**
     * @dev Deposits/wraps `underlyingAmount` of underlying tokens.
     */
    function deposit(uint256 underlyingAmount) external nonReentrant {
        uint256 amount = wrappedAssetAmount(underlyingAmount);
        require(amount > 0, "ERC20Wrapper: amount cannot be zero");

        underlyingERC20.safeTransferFrom(
            address(msg.sender),
            address(this),
            underlyingAmount
        );

        _mint(address(msg.sender), amount);

        emit Deposit(address(msg.sender), underlyingAmount, amount);
    }

    /**
     * @dev Withdraws/unwraps `underlyingAmount` of underlying tokens.
     */
    function withdraw(uint256 underlyingAmount) external nonReentrant {
        _withdraw(address(msg.sender), wrappedAssetAmount(underlyingAmount), underlyingAmount);
    }


    function _withdraw(address account, uint256 amount, uint256 underlyingAmount) internal {
        require(amount > 0, "ERC20Wrapper: amount cannot be zero");
        require(underlyingAmount > 0, "ERC20Wrapper: underlyingAmount cannot be zero");

        _burn(account, amount);

        underlyingERC20.safeTransfer(
            account,
            underlyingAmount
        );

        emit Withdrawal(account, underlyingAmount, amount);
    }
}