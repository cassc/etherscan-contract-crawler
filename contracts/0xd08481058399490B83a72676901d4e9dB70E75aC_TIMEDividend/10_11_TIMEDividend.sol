// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./interfaces/IInternetMoneySwapRouter.sol";
import "./Utils.sol";

/**
 * @title TIMEDividend a token to track ownership over dividend
 * dividend come in over time and their ownership amount may shift
 */
contract TIMEDividend is Ownable, ERC20, ERC20Burnable, Utils, Multicall {
    using Address for address payable;

    /// @dev magnitude is a constant that converts amounts to scaling magnitudes
    /// so that resolution for payouts is maintained
    uint256 public constant magnitude = 2**128;
    uint256 public magnifiedDividendPerShare;

    mapping(address => int256) public magnifiedDividendCorrections;
    mapping(address => uint256) public cumulativeDividendClaimed;

    /// @dev This emits when PLS is distributed to token holders.
    /// @param from The address which sends PLS to this contract.
    /// @param weiAmount The amount of distributed PLS in wei.
    event DistributeDividend(address indexed from, uint256 weiAmount);

    /// @dev This emits when an address withdraws their dividend.
    /// @param account The address which withdraws native token from this contract.
    /// @param amount The amount of withdrawn native token.
    event ClaimDividend(address indexed account, address indexed recipient, uint256 amount);

    error HasAdmin(address owner);
    error SupplyMissing();
    error OutOfBounds();

    /**
     * @param supply the supply of the number of tokens to produce
     */
    constructor(uint256 supply)
        ERC20("T.I.M.E. Dividend", "TIME")
        Ownable()
    {
        _mint(_msgSender(), supply);
    }

    /**
     * @notice This payable function is used to receive amount which will be given to the token holders as dividend
     * @notice This function can be run by anyone transferring the native currency into the contract.
     * @dev This private function is used to distribute PLS dividend among the token holders
     */
    receive() external payable {
        // this function can only be run after mint process is complete
        // and ownership has been revoked
        if (owner() != address(0)) {
            revert HasAdmin(owner());
        }
        uint256 amount = msg.value;
        uint256 supply = totalSupply();
        if (supply == 0) {
            revert SupplyMissing();
        }
        magnifiedDividendPerShare += ((amount * magnitude) / supply);
        emit DistributeDividend(_msgSender(), amount);
    }

    /** converts a uint256 to int256 after checking bounds */
    function toInt256(uint256 target) internal pure returns(int256) {
        if (target > uint256(type(int256).max)) {
            revert OutOfBounds();
        }
        return int256(target);
    }

    /**
     * @dev This internal function is overridden from {ERC20} contract to handle mag corrections
     * See {ERC20-_beforeTokenTransfer} for more details
     * @notice updates magnified dividend corrections as they are transferred between accounts
     * @param from the address to send tokens from
     * @param to the address to send tokens to
     * @param amount the count of tokens being sent
     * @notice this covers transfers, mints, and burns
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        int256 correctionDelta = toInt256(magnifiedDividendPerShare * amount);
        if (from != address(0)) {
            magnifiedDividendCorrections[from] += correctionDelta;
        }
        if (to != address(0)) {
            magnifiedDividendCorrections[to] -= correctionDelta;
        }
    }

    /**
     * @notice This function is used to get total claimable dividend of `account`
     * @param account Address to check for
     * @return Total claimable dividend of `account`
     */
    function claimableDividendOf(address account) public view returns (uint256) {
        (uint256 totalClaimable, ) = dividendFrom(
            magnifiedDividendPerShare,
            balanceOf(account),
            magnifiedDividendCorrections[account]
        );
        return totalClaimable - cumulativeDividendClaimed[account];
    }

    /**
     * @param account the account whose dividend should be checked
     * @return accumulatedDividend the amount of dividend accumulated
     */
    function accumulativeDividendOf(address account) public view returns (uint256, uint256) {
        return dividendFrom(
            magnifiedDividendPerShare,
            balanceOf(account),
            magnifiedDividendCorrections[account]
        );
    }

    /**
     * computes the dividend that is owed given the dividend per share, token balance, and correction from transfers
     * @param magDividendPerShare is the targeted magnitudeDividendPerShare, must be passed in since it is variable on the contract
     * @param balance the token balance of the address in question
     * @param correction the correction of the address in question which takes into account transfers over a given magnitude
     * @notice the magnitude will almost never divide evenly into the correct
     * product of the balance * dividend per share value, so the remainder is returned
     * this is useful for anyone who wants to know if there is any token
     * being left in the contract due to rounding errors
     */
    function dividendFrom(
        uint256 magDividendPerShare,
        uint256 balance,
        int256 correction
    ) public pure returns(uint256 claimableDividend, uint256 productRemainder) {
        uint256 product = uint256(toInt256(magDividendPerShare * balance) + correction);
        return (product / magnitude, product % magnitude);
    }

    /**
     * @dev This private function claims the dividend for `_msgSender()`
     * @param recipient Account to receive dividend from account
     * @param amount the amount to distribute - 0 is recognized as all
     * @return claimed true if the claim is successful, false otherwise
     * @notice if zero is passed for amount, all of the available tokens are released
     * @notice the account distributing to must be payable
     */
    function claimDividend(
        address payable recipient,
        uint256 amount
    ) public returns (uint256) {
        address account = _msgSender();
        uint256 claimable = clamp(amount, claimableDividendOf(account));
        if (claimable == 0) {
            // return if we can't claim anything
            return 0;
        }
        cumulativeDividendClaimed[account] += claimable;
        recipient.sendValue(claimable);
        emit ClaimDividend(account, recipient, claimable);
        return claimable;
    }
}