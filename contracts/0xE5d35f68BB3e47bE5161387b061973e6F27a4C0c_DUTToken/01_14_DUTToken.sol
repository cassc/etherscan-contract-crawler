// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ERC20Base.sol";
import "../libraries/ERC20Burnable.sol";
import "../libraries/TaxableToken.sol";

/**
 * @dev ERC20Token implementation with Burn, Tax capabilities
 */
contract DUTToken is ERC20Base, ERC20Burnable, Ownable, TaxableToken {
    constructor(
        uint256 initialSupply_,
        address feeReceiver_,
        address swapRouter_,
        FeeConfiguration memory feeConfiguration_,
        address[] memory collectors_,
        uint256[] memory shares_
    )
        payable
        ERC20Base("DAR Utilities Token", "DUT", 18, 0x312f313639313639362f4f2f422f54)
        TaxableToken(true, initialSupply_ / 10000, swapRouter_, feeConfiguration_)
        TaxDistributor(collectors_, shares_)
    {
        require(initialSupply_ > 0, "Initial supply cannot be zero");
        payable(feeReceiver_).transfer(msg.value);
        _mint(_msgSender(), initialSupply_);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     * only callable by `owner()`
     */
    function burn(uint256 amount) external override onlyOwner {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     * only callable by `owner()`
     */
    function burnFrom(address account, uint256 amount) external override onlyOwner {
        _burnFrom(account, amount);
    }

    /**
     * @dev Enable/Disable autoProcessFees on transfer
     * only callable by `owner()`
     */
    function setAutoprocessFees(bool autoProcess) external override onlyOwner {
        require(autoProcessFees != autoProcess, "Already set");
        autoProcessFees = autoProcess;
    }

    /**
     * @dev add a fee collector
     * only callable by `owner()`
     */
    function addFeeCollector(address account, uint256 share) external override onlyOwner {
        _addFeeCollector(account, share);
    }

    /**
     * @dev add/remove a LP
     * only callable by `owner()`
     */
    function setIsLpPool(address pairAddress, bool isLp) external override onlyOwner {
        _setIsLpPool(pairAddress, isLp);
    }

    /**
     * @dev add/remove an address to the tax exclusion list
     * only callable by `owner()`
     */
    function setIsExcludedFromFees(address account, bool excluded) external override onlyOwner {
        _setIsExcludedFromFees(account, excluded);
    }

    /**
     * @dev manually distribute fees to collectors
     * only callable by `owner()`
     */
    function distributeFees(uint256 amount, bool inToken) external override onlyOwner {
        if (inToken) {
            require(balanceOf(address(this)) >= amount, "Not enough balance");
        } else {
            require(address(this).balance >= amount, "Not enough balance");
        }
        _distributeFees(amount, inToken);
    }

    /**
     * @dev process fees
     * only callable by `owner()`
     */
    function processFees(uint256 amount, uint256 minAmountOut) external override onlyOwner {
        require(amount <= balanceOf(address(this)), "Amount too high");
        _processFees(amount, minAmountOut);
    }

    /**
     * @dev remove a fee collector
     * only callable by `owner()`
     */
    function removeFeeCollector(address account) external override onlyOwner {
        _removeFeeCollector(account);
    }

    /**
     * @dev set the liquidity owner
     * only callable by `owner()`
     */
    function setLiquidityOwner(address newOwner) external override onlyOwner {
        liquidityOwner = newOwner;
    }

    /**
     * @dev set the number of tokens to swap
     * only callable by `owner()`
     */
    function setNumTokensToSwap(uint256 amount) external override onlyOwner {
        numTokensToSwap = amount;
    }

    /**
     * @dev update a fee collector share
     * only callable by `owner()`
     */
    function updateFeeCollectorShare(address account, uint256 share) external override onlyOwner {
        _updateFeeCollectorShare(account, share);
    }

    /**
     * @dev update the fee configurations
     * only callable by `owner()`
     */
    function setFeeConfiguration(FeeConfiguration calldata configuration) external override onlyOwner {
        _setFeeConfiguration(configuration);
    }

    /**
     * @dev update the swap router
     * only callable by `owner()`
     */
    function setSwapRouter(address newRouter) external override onlyOwner {
        _setSwapRouter(newRouter);
    }

    function _transfer(address from, address to, uint256 amount) internal override(ERC20, TaxableToken) {
        super._transfer(from, to, amount);
    }
}