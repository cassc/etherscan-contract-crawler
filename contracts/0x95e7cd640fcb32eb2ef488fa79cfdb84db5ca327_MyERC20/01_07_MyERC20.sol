// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

error MyERC20__AmountExceedsBalance();

/**
 * @title erc-20 name
 * @author Author
 */

contract MyERC20 is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private immutable iTxFee;
    uint256 private immutable iBurnOnTx;
    uint256 private immutable iDenominator;

    address private immutable iMarketingWallet;

    mapping(address => bool) private isFeeExempt;

    /**
     * @param initialSupply_ the token's initial supply
     * @param name_ the token's name
     * @param symbol_ the token's tocker
     * @param txFee_ the percentage of fees sent to the contract owner at each transaction
     * @param burnOnTx_ the percentage of tokens burnt at each transaction
     * @param denominator_ the denominator used on which percentages are based
     * @param marketingWallet_ the marketing wallet's address
     * @param marketingShare_ the supply ratio sent to the marketing wallet
     */

    constructor(
        uint256 initialSupply_,
        string memory name_,
        string memory symbol_,
        uint256 txFee_,
        uint256 burnOnTx_,
        uint256 denominator_,
        address marketingWallet_,
        uint256 marketingShare_
    ) ERC20(name_, symbol_) {
        iTxFee = txFee_;
        iBurnOnTx = burnOnTx_;
        iDenominator = denominator_;
        iMarketingWallet = marketingWallet_;

        _mint(
            payable(iMarketingWallet),
            initialSupply_.mul(marketingShare_).div(iDenominator)
        );
        _mint(
            msg.sender,
            initialSupply_.mul(iDenominator.sub(marketingShare_)).div(
                iDenominator
            )
        );

        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[iMarketingWallet] = true;
    }

    // Avoid to trap ethers sent here by mistake
    receive() external payable {
        revert();
    }

    fallback() external {
        revert();
    }

    /**
     * @dev Overrides Openzeppelin's ERC20 _transfer()
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}.
     * It implements automatic token fees and burns token
     * at each transaction.
     *
     * Requirements:
     *
     * @param from cannot be the zero address.
     * @param to cannot be the zero address.
     * @param amount 'from' must have a balance of at least `amount`.
     */

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from != address(0) && to != address(0) && amount != 0) {
            uint256 fee = 0;
            uint256 burn = 0;

            uint256 fromBalance = balanceOf(from);

            if (fromBalance < amount) {
                revert MyERC20__AmountExceedsBalance();
            }

            // If "from" isn't fee exempt compute the amount of fees
            if (!isFeeExempt[from]) {
                fee = amount.mul(iTxFee).div(iDenominator);
            }

            uint256 amountAfterFee = amount.sub(fee);

            // Compute the amount of token to be burnt
            burn = amount.mul(iBurnOnTx).div(iDenominator);
            _burn(from, burn);

            super._transfer(from, payable(owner()), fee);
            super._transfer(from, to, amountAfterFee);
        }
    }

    function getTxFeeNumerator() public view returns (uint256) {
        return iTxFee;
    }

    function getBurnNumerator() public view returns (uint256) {
        return iBurnOnTx;
    }

    function getDenominator() public view returns (uint256) {
        return iDenominator;
    }

    function getMarketingWallet() public view returns (address) {
        return iMarketingWallet;
    }
}