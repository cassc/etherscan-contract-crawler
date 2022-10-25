// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {Clone} from "solady/utils/Clone.sol";
import {ISplitMain} from "src/interfaces/ISplitMain.sol";

/// @title LiquidSplitCloneImpl
/// @author 0xSplits
/// @notice An abstract liquid split base designed to be used as part of a
/// clones-with-immutable-args implementation.
/// @dev This contract uses token = address(0) to refer to ETH.
abstract contract LiquidSplitCloneImpl is Clone {
    /// -----------------------------------------------------------------------
    /// libraries
    /// -----------------------------------------------------------------------

    using SafeTransferLib for address;

    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    /// Emitted after each successful ETH transfer to proxy
    /// @param amount Amount of ETH received
    /// @dev embedded in & emitted from clone bytecode
    event ReceiveETH(uint256 amount);

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    address internal constant ETH_ADDRESS = address(0);
    uint256 public constant PERCENTAGE_SCALE = 1e6;

    ISplitMain public immutable splitMain;
    address internal immutable liquidSplitFactory;

    address public payoutSplit;

    /// -----------------------------------------------------------------------
    /// storage - cwia
    /// -----------------------------------------------------------------------

    // 0; first item
    uint256 internal constant DISTRIBUTOR_FEE_OFFSET = 0;

    /// @dev equivalent to uint32 public immutable distributorFee;
    function distributorFee() public pure returns (uint32) {
        return _getArgUint32(DISTRIBUTOR_FEE_OFFSET);
    }

    /// -----------------------------------------------------------------------
    /// constructor & initializer
    /// -----------------------------------------------------------------------

    constructor(address _splitMain) {
        splitMain = ISplitMain(_splitMain);
        liquidSplitFactory = msg.sender;
    }

    /// @dev cannot be called externally by default; inheriting contracts must
    /// be sure to properly secure any calls
    function initializer() internal {
        /// checks

        /// effects

        /// interactions

        // create dummy mutable split with this contract as controller;
        // recipients & distributorFee will be updated on first payout
        address[] memory recipients = new address[](2);
        recipients[0] = address(0);
        recipients[1] = address(1);
        uint32[] memory initPercentAllocations = new uint32[](2);
        initPercentAllocations[0] = uint32(500000);
        initPercentAllocations[1] = uint32(500000);
        payoutSplit = payable(
            splitMain.createSplit({
                accounts: recipients,
                percentAllocations: initPercentAllocations,
                distributorFee: 0,
                controller: address(this)
            })
        );
    }

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    /// emit event when receiving ETH
    /// @dev implemented w/i clone bytecode
    /* receive() external virtual payable { */
    /*     emit ReceiveETH(msg.value); */
    /* } */

    /// distributes ETH & ERC20s to NFT holders
    /// @param token ETH (0x0) or ERC20 token to distribute
    /// @param accounts Ordered, unique list of NFT holders
    /// @param distributorAddress Address to receive distributorFee
    function distributeFunds(address token, address[] calldata accounts, address distributorAddress) external virtual {
        uint256 numRecipients = accounts.length;
        uint32[] memory percentAllocations = new uint32[](numRecipients);
        for (uint256 i; i < numRecipients;) {
            percentAllocations[i] = scaledPercentBalanceOf(accounts[i]);
            unchecked {
                ++i;
            }
        }

        // atomically deposit funds, update recipients to reflect current NFT holders, and distribute
        if (token == ETH_ADDRESS) {
            payoutSplit.safeTransferETH(address(this).balance);
            splitMain.updateAndDistributeETH({
                split: payoutSplit,
                accounts: accounts,
                percentAllocations: percentAllocations,
                distributorFee: distributorFee(),
                distributorAddress: distributorAddress
            });
        } else {
            token.safeTransfer(payoutSplit, ERC20(token).balanceOf(address(this)));
            splitMain.updateAndDistributeERC20({
                split: payoutSplit,
                token: ERC20(token),
                accounts: accounts,
                percentAllocations: percentAllocations,
                distributorFee: distributorFee(),
                distributorAddress: distributorAddress
            });
        }
    }

    /// -----------------------------------------------------------------------
    /// functions - public & external - view & pure
    /// -----------------------------------------------------------------------

    function scaledPercentBalanceOf(address account) public view virtual returns (uint32) {}

    /// @dev Reads an immutable arg with type uint32.
    function _getArgUint32(uint256 argOffset) internal pure returns (uint32 arg) {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            arg := shr(0xe0, calldataload(add(offset, argOffset)))
        }
    }
}