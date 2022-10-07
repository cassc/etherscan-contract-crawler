// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./openzeppelin/SafeERC20Upgradeable.sol";
import "./openzeppelin/utils/Initializable.sol";
import "./interfaces/IPayment.sol";
import "./openzeppelin/PausableUpgradeable.sol";
import "./openzeppelin/AccessControlUpgradeable.sol";

contract Payment is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    IPayment
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event PaymentProcessed(
        uint256 indexed paymentId,
        uint256 indexed orderId,
        address indexed from,
        address to
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _safeTransferErc20 (address tokenAddress, address from, address to, uint256 amount) internal {
        if (from == to) return;
        if (amount == 0) return;
        if (from == address(this)) {
            return IERC20Upgradeable(tokenAddress).safeTransfer(to, amount);
        } 
        return IERC20Upgradeable(tokenAddress).safeTransferFrom(from, to, amount);
    }

    /**
     * @dev Retrieve tokens from user to proceed with next step on WGoldManager.
     *
     * @param paymentInfo A struct, that was created on a backend.
     */
    function processPayment(PaymentInfo memory paymentInfo)
        external
        override
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (paymentInfo.from != address(this)) {
            require(
                IERC20Upgradeable(paymentInfo.assetAddress).allowance(
                    paymentInfo.from,
                    address(this)
                ) >= paymentInfo.amount,
                "Payment: not enough allowance"
            );
            _safeTransferErc20(paymentInfo.assetAddress, paymentInfo.from, address(this), paymentInfo.amount);
        }
        require(
            paymentInfo.withdrawAmount <= paymentInfo.amount,
            "Withdraw more than amount"
        );
        _safeTransferErc20(paymentInfo.assetAddress, address(this), paymentInfo.to, paymentInfo.amount - paymentInfo.withdrawAmount);
        _safeTransferErc20(paymentInfo.assetAddress, address(this), paymentInfo.withdrawAddress, paymentInfo.withdrawAmount);
        emit PaymentProcessed(
            paymentInfo.paymentId,
            paymentInfo.orderId,
            paymentInfo.from,
            paymentInfo.to
        );
    }
}