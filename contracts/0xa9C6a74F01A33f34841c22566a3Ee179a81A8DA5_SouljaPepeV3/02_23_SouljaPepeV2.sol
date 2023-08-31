// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SouljaPepeV1.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";

contract SouljaPepeV2 is SouljaPepe {
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override notBlacklisted(sender, recipient) nonReentrant {
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 tax = (amount * (burnPercentage / 1)) / 100;

        super._transfer(sender, recipient, amount - tax);
        super._transfer(sender, marketingWallet, tax / 2);

        if (totalSupply() > minSupply) {
            super._burn(sender, tax / 2);
        }
    }
}