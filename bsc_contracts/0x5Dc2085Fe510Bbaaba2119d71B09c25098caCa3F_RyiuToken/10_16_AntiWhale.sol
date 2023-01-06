// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20Base.sol";

/**
 * @dev limit the maximum number of tokens per wallet
 */
abstract contract AntiWhale is Ownable, ERC20Base {
    uint256 public maxTokenPerWallet;
    mapping(address => bool) private _excluded;

    event ExcludedFromAntiWhale(address indexed account, bool excluded);
    event MaxTokenPerWalletUpdated(uint256 amount);

    constructor(uint256 maxTokenPerWallet_) {
        maxTokenPerWallet = maxTokenPerWallet_;

        _setIsExcludedFromAntiWhale(_msgSender(), true);
        _setIsExcludedFromAntiWhale(address(this), true);
    }

    function _setIsExcludedFromAntiWhale(address account, bool excluded) internal {
        _excluded[account] = excluded;
        emit ExcludedFromAntiWhale(account, excluded);
    }

    function isExcludedFromAntiWhale(address account) public view returns (bool) {
        return _excluded[account];
    }

    function setIsExcludedFromAntiWhale(address account, bool excluded) external onlyOwner {
        require(_excluded[account] != excluded, "Already set");
        _setIsExcludedFromAntiWhale(account, excluded);
    }

    function setMaxTokenPerWallet(uint256 amount) external onlyOwner {
        uint256 supply = totalSupply();

        if (amount == 0) amount = supply; // set to 0 to disable
        require(amount > (supply * 5) / 1000, "Amount too low"); // min 0.5% of supply

        maxTokenPerWallet = amount;
        emit MaxTokenPerWalletUpdated(amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (!isExcludedFromAntiWhale(to)) {
            require(balanceOf(to) <= maxTokenPerWallet, "AntiWhale: balance too high");
        }
        super._afterTokenTransfer(from, to, amount);
    }
}