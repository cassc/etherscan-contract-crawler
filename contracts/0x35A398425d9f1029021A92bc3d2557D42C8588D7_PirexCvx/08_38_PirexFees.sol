// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

contract PirexFees is Ownable {
    using SafeTransferLib for ERC20;

    // Types of fee recipients
    enum FeeRecipient {
        Treasury,
        Contributors
    }

    uint8 public constant PERCENT_DENOMINATOR = 100;

    // Configurable fee recipient percent-share
    uint8 public treasuryPercent = 75;

    // Configurable fee recipient addresses
    address public treasury;
    address public contributors;

    event SetFeeRecipient(FeeRecipient f, address recipient);
    event SetTreasuryPercent(uint8 _treasuryPercent);
    event DistributeFees(address token, uint256 amount);

    error ZeroAddress();
    error InvalidFeePercent();

    /**
        @param  _treasury      address  Redacted treasury
        @param  _contributors  address  Pirex contributor multisig
     */
    constructor(address _treasury, address _contributors) {
        if (_treasury == address(0)) revert ZeroAddress();
        if (_contributors == address(0)) revert ZeroAddress();

        treasury = _treasury;
        contributors = _contributors;
    }

    /** 
        @notice Set a fee recipient address
        @param  f          enum     FeeRecipient enum
        @param  recipient  address  Fee recipient address
     */
    function setFeeRecipient(FeeRecipient f, address recipient)
        external
        onlyOwner
    {
        if (recipient == address(0)) revert ZeroAddress();

        emit SetFeeRecipient(f, recipient);

        if (f == FeeRecipient.Treasury) {
            treasury = recipient;
            return;
        }

        contributors = recipient;
    }

    /** 
        @notice Set treasury fee percent
        @param  _treasuryPercent  uint8  Treasury fee percent
     */
    function setTreasuryPercent(uint8 _treasuryPercent) external onlyOwner {
        // Treasury fee percent should never exceed 75
        if (_treasuryPercent > 75) revert InvalidFeePercent();

        treasuryPercent = _treasuryPercent;

        emit SetTreasuryPercent(_treasuryPercent);
    }

    /** 
        @notice Distribute fees
        @param  from    address  Fee source
        @param  token   address  Fee token
        @param  amount  uint256  Fee token amount
     */
    function distributeFees(
        address from,
        address token,
        uint256 amount
    ) external {
        emit DistributeFees(token, amount);

        ERC20 t = ERC20(token);
        uint256 treasuryDistribution = (amount * treasuryPercent) /
            PERCENT_DENOMINATOR;

        // Favoring push over pull to reduce accounting complexity for different tokens
        t.safeTransferFrom(from, treasury, treasuryDistribution);
        t.safeTransferFrom(from, contributors, amount - treasuryDistribution);
    }
}