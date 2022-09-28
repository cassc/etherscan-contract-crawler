// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../config/PaymentConstants.sol";
import "../../libraries/ERC20Utils.sol";

abstract contract PaymentTransfersAdapter is PaymentConstants {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev States of currency tokens used for deposits.
     */
    enum CurrencySupport {
        INEXISTENT,
        OPERATIVE,
        DEPRECATED
    }

    /// @notice set of ERC20 tokens supported for payment
    mapping(IERC20Upgradeable => CurrencySupport) public currencySupport;

    /**
     * @dev Emitted when changing support-level for `erc20` of `decimals` denomination to `state`.
     */
    event SetCurrencySupport(IERC20Upgradeable indexed erc20, CurrencySupport indexed state, uint8 decimals);

    /**
     * @dev Emitted when client `account` deposits `amount` of `erc20` to increase its platform funds.
     */
    event Deposit(address indexed account, IERC20Upgradeable indexed erc20, uint256 amount);

    /**
     * @dev Emitted when provider `account` claims `amount` of `erc20` from its earned rewards.
     */
    event Claim(address indexed account, IERC20Upgradeable indexed erc20, uint256 amount);

    /**
     * @dev Set the support-level for a payment token.
     * @param erc20 token address
     * @param state support-level to update to
     */
    function _setCurrencySupport(IERC20Upgradeable erc20, CurrencySupport state) internal {
        uint8 decimals = IERC20MetadataUpgradeable(address(erc20)).decimals();
        require(decimals <= TOKEN_PRECISION, "BP203");
        currencySupport[erc20] = state;
        emit SetCurrencySupport(erc20, state, decimals);
    }

    /**
     * @dev Converts `amount` in token `erc20` to uniform internal precision.
     * @param erc20 token converting from
     * @param amount raw (external) amount of USD
     */
    function _externalToInternal(IERC20Upgradeable erc20, uint256 amount) internal view returns (uint256) {
        return amount * (10**(TOKEN_PRECISION - IERC20MetadataUpgradeable(address(erc20)).decimals()));
    }

    /**
     * @dev Converts internal `amount` to the precision of token `erc20`.
     * @param erc20 token converting to
     * @param amount uniform (internal) amount of USD
     */
    function _internalToExternal(IERC20Upgradeable erc20, uint256 amount) internal view returns (uint256) {
        return amount / (10**(TOKEN_PRECISION - IERC20MetadataUpgradeable(address(erc20)).decimals()));
    }

    /**
     * @dev Deposit `amount` of supported token `erc20` to increase `account`s funds.
     * @param account account to transfer from
     * @param erc20 currency token to use
     * @param amount amount of tokens to deposit
     */
    function _deposit(
        address account,
        IERC20Upgradeable erc20,
        uint256 amount
    ) internal {
        require(currencySupport[erc20] == CurrencySupport.OPERATIVE, "BP103");
        emit Deposit(account, erc20, ERC20Utils.strictTransferFrom(erc20, account, address(this), amount));
    }

    /**
     * @dev Transfer `amount` of supported token `erc20` from this contract to `account`
     * and record this claim operation.
     * @param account account to transfer to
     * @param erc20 currency token to use
     * @param amount amount of tokens to claim
     */
    function _claim(
        address account,
        IERC20Upgradeable erc20,
        uint256 amount
    ) internal {
        require(currencySupport[erc20] != CurrencySupport.INEXISTENT, "BP104");
        erc20.safeTransfer(account, amount);
        emit Claim(account, erc20, amount);
    }

    /**
     * @dev empty reserved space to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[49] private __gap;
}