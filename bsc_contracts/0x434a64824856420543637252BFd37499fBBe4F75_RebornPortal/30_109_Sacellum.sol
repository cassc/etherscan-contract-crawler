// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {UUPSUpgradeable} from "./oz/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "./oz/contracts-upgradeable/security/PausableUpgradeable.sol";
import {SafeOwnableUpgradeable} from "./utils/SafeOwnableUpgradeable.sol";
import {RBT} from "src/RBT.sol";
import {CommonError} from "src/lib/CommonError.sol";
import {ISacellum} from "src/interfaces/ISacellum.sol";
import {SafeERC20Upgradeable} from "./oz/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Sacellum is
    ISacellum,
    SafeOwnableUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable
{
    RBT public CZToken;
    RBT public DEGENToken;
    uint256 public rate;

    uint256[47] private _gap;

    using SafeERC20Upgradeable for RBT;

    /**
     * @dev initialize function
     * @param CZToken_ $CZ token address
     * @param DEGENToken_ $DEGEN token address
     * @param owner_ contract owner
     */
    function initialize(
        RBT CZToken_,
        RBT DEGENToken_,
        address owner_
    ) public initializer {
        if (
            address(CZToken_) == address(0) ||
            address(DEGENToken_) == address(0)
        ) {
            revert CommonError.ZeroAddressSet();
        }
        CZToken = CZToken_;
        DEGENToken = DEGENToken_;
        __Ownable_init(owner_);
        __Pausable_init();
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev set invoke reate
     * @param rate_ $DEGEN amount per $CZ
     */
    function setRate(uint256 rate_) external override onlyOwner {
        rate = rate_;
        emit RateSet(rate);
    }

    /**
     * @dev withdraw remaining $DEGEN
     * @param to address receive remaining $DEGEN
     */
    function withdrawRemaining(address to) external onlyOwner {
        uint256 b = DEGENToken.balanceOf(address(this));
        DEGENToken.safeTransfer(to, b);

        emit Withdraw(to, b);
    }

    function invoke(uint256 amount) external override {
        _invoke(amount);
    }

    function invoke(
        uint256 amount,
        uint256 permitAmount,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external override {
        _permit(permitAmount, deadline, r, s, v);
        _invoke(amount);
    }

    /**
     * @dev burn $CZ to invoke for $DEGEN
     * @param amount amount of $CZ to be burned
     */
    function _invoke(uint256 amount) internal {
        if (rate == 0) {
            revert RateNotSet();
        }
        CZToken.burnFrom(msg.sender, amount);
        uint256 degenAmount = amount * rate;
        DEGENToken.safeTransfer(msg.sender, degenAmount);

        emit Invoke(amount, degenAmount);
    }

    /**
     * @dev run erc20 permit to approve
     */
    function _permit(
        uint256 amount,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal {
        CZToken.permit(msg.sender, address(this), amount, deadline, v, r, s);
    }
}