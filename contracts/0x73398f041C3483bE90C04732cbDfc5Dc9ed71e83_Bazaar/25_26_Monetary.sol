// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";


library Monetary {
    using Address for address;
    using Address for address payable;
    using SafeERC20 for IERC20;

    struct Crypto {
        uint amount;
        address currency;
    }

    error UnsupportedCurrency(address currency);

    address constant NativeCurrency = address(0);

    function Native(uint amount) public pure returns (Monetary.Crypto memory) { return Crypto(amount, NativeCurrency); }
    function Zero(address currency) public pure returns (Monetary.Crypto memory) { return Crypto(0, currency); }

    function isNative(Monetary.Crypto memory self) internal pure returns (bool) { return self.currency == NativeCurrency; }

    function isZero(Monetary.Crypto memory self) internal pure returns (bool) { return self.amount == 0; }

    function isValidCurrency(address currency) internal view returns (bool) {
        return currency.isContract();
    }

    function isEqualTo(Monetary.Crypto memory self, Monetary.Crypto memory other) internal pure returns (bool) {
        return self.currency == other.currency && self.amount == other.amount;
    }

    function isGreaterThan(Monetary.Crypto memory self, Monetary.Crypto memory other) internal pure returns (bool) {
        require(self.currency == other.currency, "incompatible currency");
        return self.amount > other.amount;
    }

    function plus(Monetary.Crypto memory self, Monetary.Crypto memory other) internal pure returns (Monetary.Crypto memory) {
        require(self.currency == other.currency, "incompatible currency");
        return Crypto(self.amount + other.amount, self.currency);
    }

    function minus(Monetary.Crypto memory self, Monetary.Crypto memory other) internal pure returns (Monetary.Crypto memory) {
        require(self.currency == other.currency, "incompatible currency");
        return Crypto(self.amount - other.amount, self.currency);
    }

    function multipliedBy(Monetary.Crypto memory self, uint value) internal pure returns (Monetary.Crypto memory) {
        return Crypto(self.amount * value, self.currency);
    }

    function dividedBy(Monetary.Crypto memory self, uint value) internal pure returns (Monetary.Crypto memory) {
        return Crypto(self.amount / value, self.currency);
    }

    function transferFromSender(Monetary.Crypto memory self) internal {
        if (!isZero(self)) {
            if (isValidCurrency(self.currency)) IERC20(self.currency).safeTransferFrom(msg.sender, address(this), self.amount);
            else revert UnsupportedCurrency(self.currency);
        }
    }

    function transferTo(Monetary.Crypto memory self, address recipient) internal {
        if (!isZero(self)) {
            if (isNative(self)) payable(recipient).sendValue(self.amount);
            else if (isValidCurrency(self.currency)) IERC20(self.currency).safeTransfer(recipient, self.amount);
            else revert UnsupportedCurrency(self.currency);
        }
    }

}