// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Base.sol";

/*
 * AntiWhaleToken: Limit the max wallet size
 */
abstract contract AntiWhaleToken is ERC20Base {
    uint256 public maxTokenPerWallet; // anti whale: max token per wallet (default to 1% of supply)

    event MaxTokenPerWalletUpdated(uint256 amount);

    modifier antiWhale(
        address sender,
        address recipient,
        uint256 amount
    ) {
        if (maxTokenPerWallet != 0 && !isExcludedFromAntiWhale(recipient)) {
            require(balanceOf(recipient) + amount <= maxTokenPerWallet, "Wallet exceeds max");
        }
        _;
    }

    constructor(uint256 maxTokenPerWallet_) {
        maxTokenPerWallet = maxTokenPerWallet_;
    }

    function isExcludedFromAntiWhale(address account) public view virtual returns (bool);

    /**
     * @dev Update the max token per wallet
     * set to 0 to disable
     */
    function _setMaxTokenPerWallet(uint256 amount) internal {
        require(amount == 0 || amount > (totalSupply() * 5) / 1000, "Amount too low"); // min 0.5% of supply

        maxTokenPerWallet = amount;
        emit MaxTokenPerWalletUpdated(amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override antiWhale(from, to, amount) {
        super._beforeTokenTransfer(from, to, amount);
    }
}