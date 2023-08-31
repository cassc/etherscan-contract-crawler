// SPDX-License-Identifier: MIT
// Changes made by Clowder: 
// - Removed the received function and the ReceiveETH event
// - Removed the _distributorFee variable as we will solely rely on inheriting contract
// - Made distributorAddress rely on the inheriting contract
// - Moved out the Split creation to a function so it can be called from the inheriting contract
pragma solidity ^0.8.13;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {ISplitMain} from "./interfaces/ISplitMain.sol";

/// @title LiquidSplit
/// @author 0xSplits
/// @notice An abstract liquid split base contract. Can be inherited into a 721
/// or 1155 contract.
/// @dev This contract uses token = address(0) to refer to ETH.
abstract contract LiquidSplit {
    /// -----------------------------------------------------------------------
    /// libraries
    /// -----------------------------------------------------------------------

    using SafeTransferLib for address;

    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    /// Emitted after each liquid split creation for indexing purposes
    event CreateLiquidSplit(address indexed payoutSplit);

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    address internal constant ETH_ADDRESS = address(0);
    uint256 public constant PERCENTAGE_SCALE = 1e6;

    ISplitMain public immutable splitMain;
    address public payoutSplit;

    /// -----------------------------------------------------------------------
    /// constructor
    /// -----------------------------------------------------------------------

    constructor(address _splitMain) {
        /// checks


        /// effects

        splitMain = ISplitMain(_splitMain); /*Establish interface to splits contract*/

        /// interactions
    }

    function _createSplit() internal {
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

        emit CreateLiquidSplit(payoutSplit);
    }

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    // NOTE: if `sum(percentAllocations) != 1e6`, the split will fail to update and funds will be stuck!
    // be _very_ careful with edge cases in managing supply (including burns, rounding on odd numbers, etc)

    /// distributes ETH & ERC20s to NFT holders
    /// @param token ETH (0x0) or ERC20 token to distribute
    /// @param accounts Ordered, unique list of NFT holders
    function distributeFunds(address token, address[] calldata accounts) external virtual {
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
                distributorAddress: distributorAddress()
            });
        } else {
            token.safeTransfer(payoutSplit, ERC20(token).balanceOf(address(this)));
            splitMain.updateAndDistributeERC20({
                split: payoutSplit,
                token: ERC20(token),
                accounts: accounts,
                percentAllocations: percentAllocations,
                distributorFee: distributorFee(),
                distributorAddress: distributorAddress()
            });
        }
    }

    /// -----------------------------------------------------------------------
    /// functions - public & external - view & pure
    /// -----------------------------------------------------------------------

    function scaledPercentBalanceOf(address account) public view virtual returns (uint32) {}

    /// @dev can be overridden if inheriting contract wants to grant the ability for an owner to update
    function distributorFee() public view virtual returns (uint32) {}

    /// @dev can be overridden if inheriting contract wants to grant the ability for an owner to update
    function distributorAddress() public view virtual returns (address) {}
}